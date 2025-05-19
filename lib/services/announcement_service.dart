import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';
import 'auth_service.dart';

class AnnouncementService {
  // Singleton pattern
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _announcementsCollection = FirebaseFirestore.instance.collection('announcements');
  final CollectionReference _commentsCollection = FirebaseFirestore.instance.collection('announcementComments');
  final AuthService _authService = AuthService();

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
          final comments = snapshot.docs
              .map((doc) => Comment.fromFirestore(doc))
              .toList();
          comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          final updatedComments = await Future.wait(
            comments.map((comment) async {
              final userDetails = await _authService.getUserNamefromID(comment.userId);
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
  Future<void> addComment(String announcementId, String userId, String content) async {
    // Get user details
    final userDetails = await _authService.getUserNamefromID(userId);
    
    await _commentsCollection.add({
      'announcementId': announcementId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
      'firstName': userDetails['firstName'],
      'lastName': userDetails['lastName'],
    });
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
                announcement.description.toLowerCase().contains(lowercaseQuery) ||
                announcement.department.toLowerCase().contains(lowercaseQuery))
            .toList());
  }
}