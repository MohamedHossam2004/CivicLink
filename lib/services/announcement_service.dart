import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AnnouncementService {
  // Singleton pattern
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _announcementsCollection =
      FirebaseFirestore.instance.collection('announcements');
  final CollectionReference _commentsCollection =
      FirebaseFirestore.instance.collection('announcementComments');
  final CollectionReference _savedAnnouncementsCollection =
      FirebaseFirestore.instance.collection('savedAnnouncements');
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  // Listen for new announcements and notify
  void startAnnouncementListener() {
    _announcementsCollection
        .orderBy('createdOn', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final latestAnnouncement = Announcement.fromFirestore(snapshot.docs.first);
        
        // Check if it's a new announcement (created within the last minute)
        final now = DateTime.now();
        final difference = now.difference(latestAnnouncement.createdOn);
        
        if (difference.inMinutes <= 1) {
          // This is likely a new announcement
          
          // If it's important, send to all users
          if (latestAnnouncement.isImportant) {
            // Instead of individual notifications, we can use a topic
            // Assuming all users subscribe to 'announcements' topic on login
            
            // But we can also notify specific users directly if needed
            final allUsers = await _firestore.collection('users').get();
            for (final userDoc in allUsers.docs) {
              final userId = userDoc.id;
              await _notificationService.sendNotificationToUser(
                userId: userId,
                title: 'Important Announcement',
                body: latestAnnouncement.name,
                type: 'announcement',
                data: {
                  'announcementId': latestAnnouncement.id,
                },
              );
            }
          }
        }
      }
    });
  }

  // Get all announcements
  Stream<List<Announcement>> getAllAnnouncements() {
    return _announcementsCollection
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc))
            .toList());
  }

  // Get announcement by ID
  Future<Announcement?> getAnnouncementById(String id) async {
    final doc = await _announcementsCollection.doc(id).get();
    if (doc.exists) {
      return Announcement.fromFirestore(doc);
    }
    return null;
  }

  // Get comments for an announcement
  Stream<List<Comment>> getCommentsForAnnouncement(String announcementId) {
    return _commentsCollection
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .asyncMap((snapshot) async {
      final comments =
          snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList();
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final updatedComments = await Future.wait(
        comments.map((comment) async {
          final userDetails =
              await _authService.getUserNamefromID(comment.userId);
          return comment.copyWith(
            firstName: userDetails['firstName'],
            lastName: userDetails['lastName'],
          );
        }),
      );
      return updatedComments;
    });
  }

  // Add a comment to an announcement
  Future<void> addComment(String announcementId, String userId, String content,
      {bool isAnonymous = false}) async {
    // Get user details
    final userDetails = await _authService.getUserNamefromID(userId);

    final commentDoc = await _commentsCollection.add({
      'announcementId': announcementId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'firstName': userDetails['firstName'],
      'lastName': userDetails['lastName'],
      'isAnonymous': isAnonymous,
    });

    // Get the announcement details
    final announcement = await getAnnouncementById(announcementId);
    
    // Check if this is a reply to another comment (notifications would be handled differently)
    // For now, we notify the announcement creator if different from commenter
    if (announcement != null) {
      // Fetch all users who have commented on this announcement before
      // to notify them of new activity
      final previousComments = await _commentsCollection
          .where('announcementId', isEqualTo: announcementId)
          .where('userId', isNotEqualTo: userId) // Don't notify the commenter
          .get();
      
      // Get unique user IDs
      final Set<String> usersToNotify = {};
      for (final doc in previousComments.docs) {
        final commentData = doc.data() as Map<String, dynamic>;
        final commentUserId = commentData['userId'] as String;
        usersToNotify.add(commentUserId);
      }
      
      // Send notifications
      for (final userToNotify in usersToNotify) {
        await _notificationService.sendNotificationToUser(
          userId: userToNotify,
          title: 'New Comment on Announcement',
          body: 'Someone commented on an announcement you\'re following',
          type: 'announcement_comment',
          data: {
            'announcementId': announcementId,
            'commentId': commentDoc.id,
          },
        );
      }
    }
  }

  // Like a comment
  Future<void> likeComment(String commentId) async {
    await _commentsCollection.doc(commentId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  // Filter announcements by department
  Stream<List<Announcement>> filterByDepartment(String department) {
    return _announcementsCollection
        .where('department', isEqualTo: department)
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc))
            .toList());
  }

  // Get important announcements
  Stream<List<Announcement>> getImportantAnnouncements() {
    return _announcementsCollection
        .where('isImportant', isEqualTo: true)
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc))
            .toList());
  }

  // Search announcements
  Stream<List<Announcement>> searchAnnouncements(String query) {
    if (query.isEmpty) {
      return getAllAnnouncements();
    }

    final lowercaseQuery = query.toLowerCase();
    return _announcementsCollection
        .orderBy('createdOn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc))
            .where((announcement) =>
                announcement.name.toLowerCase().contains(lowercaseQuery) ||
                announcement.description
                    .toLowerCase()
                    .contains(lowercaseQuery) ||
                announcement.department.toLowerCase().contains(lowercaseQuery))
            .toList());
  }

  // Save an announcement
  Future<void> saveAnnouncement(String announcementId) async {
    final user = _authService.currentUser;
    if (user == null) {
      print("Cannot save announcement: User is not logged in");
      return;
    }

    // Force token refresh to ensure we have fresh credentials
    try {
      await user.getIdToken(true);
      print("Token refreshed successfully");
    } catch (e) {
      print("Error refreshing token: $e");
      // Continue anyway as this is just a precaution
    }

    try {
      print(
          "Attempting to save announcement $announcementId for user ${user.uid}");

      // Check if already saved
      final existingSave = await _savedAnnouncementsCollection
          .where('userId', isEqualTo: user.uid)
          .where('announcementId', isEqualTo: announcementId)
          .get();

      if (existingSave.docs.isNotEmpty) {
        print("Announcement already saved, no action needed");
        return;
      }

      print("Creating new save document");
      final saveData = {
        'userId': user.uid,
        'announcementId': announcementId,
        'savedAt': FieldValue.serverTimestamp(),
      };
      print("Save data: $saveData");

      // Create new save
      final docRef = await _savedAnnouncementsCollection.add(saveData);
      print("Save successful, document ID: ${docRef.id}");
    } catch (e) {
      print('Error saving announcement: $e');
      rethrow;
    }
  }

  // Unsave an announcement
  Future<void> unsaveAnnouncement(String announcementId) async {
    final user = _authService.currentUser;
    if (user == null) {
      print("Cannot unsave announcement: User is not logged in");
      return;
    }

    // Force token refresh to ensure we have fresh credentials
    try {
      await user.getIdToken(true);
      print("Token refreshed successfully");
    } catch (e) {
      print("Error refreshing token: $e");
      // Continue anyway as this is just a precaution
    }

    try {
      print(
          "Attempting to unsave announcement $announcementId for user ${user.uid}");

      final querySnapshot = await _savedAnnouncementsCollection
          .where('userId', isEqualTo: user.uid)
          .where('announcementId', isEqualTo: announcementId)
          .get();

      print("Found ${querySnapshot.docs.length} saved entries to delete");

      for (var doc in querySnapshot.docs) {
        print("Deleting document ID: ${doc.id}");
        await doc.reference.delete();
      }

      print("Unsave operation completed successfully");
    } catch (e) {
      print('Error unsaving announcement: $e');
      rethrow;
    }
  }

  // Get saved announcements for current user
  Stream<List<Announcement>> getSavedAnnouncements() {
    final user = _authService.currentUser;
    if (user == null) return Stream.value([]);

    return _savedAnnouncementsCollection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        return [];
      }

      final savedAnnouncements = await Future.wait(
        snapshot.docs.map((doc) async {
          final announcementId = doc['announcementId'] as String;
          try {
            final announcementDoc =
                await _announcementsCollection.doc(announcementId).get();
            if (announcementDoc.exists) {
              return Announcement.fromFirestore(announcementDoc);
            }
          } catch (e) {
            print('Error fetching announcement $announcementId: $e');
          }
          return null;
        }),
      );

      // Filter out null values and return the list of announcements
      return savedAnnouncements.whereType<Announcement>().toList();
    });
  }

  // Check if an announcement is saved
  Stream<bool> isAnnouncementSaved(String announcementId) {
    final user = _authService.currentUser;
    if (user == null) return Stream.value(false);

    print(
        'Checking if announcement $announcementId is saved for user ${user.uid}');

    return _savedAnnouncementsCollection
        .where('userId', isEqualTo: user.uid)
        .where('announcementId', isEqualTo: announcementId)
        .snapshots()
        .map((snapshot) {
      final isSaved = snapshot.docs.isNotEmpty;
      print('Announcement $announcementId saved status: $isSaved');
      return isSaved;
    });
  }

  // Update announcement
  Future<void> updateAnnouncement(
    String id, {
    required String name,
    required String description,
    required String phone,
    required String email,
    required String department,
    required String label,
    required bool isImportant,
    required DateTime? startTime,
    required DateTime? endTime,
  }) async {
    await _announcementsCollection.doc(id).update({
      'name': name,
      'description': description,
      'phone': phone,
      'email': email,
      'department': department,
      'label': label,
      'isImportant': isImportant,
      'startTime': startTime != null ? Timestamp.fromDate(startTime) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    // Delete the announcement
    await _announcementsCollection.doc(id).delete();

    // Delete associated comments
    final comments =
        await _commentsCollection.where('announcementId', isEqualTo: id).get();

    for (var doc in comments.docs) {
      await doc.reference.delete();
    }

    // Delete saved announcements
    final savedAnnouncements = await _savedAnnouncementsCollection
        .where('announcementId', isEqualTo: id)
        .get();

    for (var doc in savedAnnouncements.docs) {
      await doc.reference.delete();
    }
  }
}
