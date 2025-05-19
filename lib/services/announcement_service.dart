import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  // Singleton pattern
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _announcementsCollection = FirebaseFirestore.instance.collection('announcements');
  final CollectionReference _commentsCollection = FirebaseFirestore.instance.collection('announcementComments');

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Comment.fromFirestore(doc))
            .toList());
  }

  // Add a comment to an announcement
  Future<void> addComment(String announcementId, String userId) async {
    await _commentsCollection.add({
      'announcementId': announcementId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
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
}