import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get all reports
  Stream<QuerySnapshot> getAllReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get reports by status
  Stream<QuerySnapshot> getReportsByStatus(String status) {
    return _firestore
        .collection('reports')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update report status
  Future<void> updateReportStatus(String reportId, String newStatus) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }

  // Delete a report
  Future<void> deleteReport(String reportId) async {
    try {
      // Get the report to access photo URLs
      final reportDoc =
          await _firestore.collection('reports').doc(reportId).get();

      if (reportDoc.exists) {
        final data = reportDoc.data() as Map<String, dynamic>;

        // Delete photos from storage if they exist
        if (data.containsKey('photoUrls')) {
          final List<String> photoUrls =
              List<String>.from(data['photoUrls'] ?? []);

          for (var url in photoUrls) {
            try {
              // Extract the path from the URL
              final ref = _storage.refFromURL(url);
              await ref.delete();
            } catch (e) {
              print('Error deleting photo: $e');
              // Continue with other photos even if one fails
            }
          }
        }

        // Delete the report document
        await _firestore.collection('reports').doc(reportId).delete();
      }
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
    }
  }

  // Get user details
  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data();
      }

      return null;
    } catch (e) {
      print('Error getting user details: $e');
      rethrow;
    }
  }

  // Get report statistics
  Future<Map<String, int>> getReportStatistics() async {
    try {
      final stats = {
        'total': 0,
        'pending': 0,
        'under review': 0,
        'closed': 0,
      };

      final reportsSnapshot = await _firestore.collection('reports').get();

      stats['total'] = reportsSnapshot.docs.length;

      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'Pending';

        switch (status) {
          case 'Pending':
            stats['pending'] = (stats['pending'] ?? 0) + 1;
            break;
          case 'Under Review':
            stats['Under Review'] = (stats['under review'] ?? 0) + 1;
            break;
          case 'Closed':
            stats['closed'] = (stats['closed'] ?? 0) + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting report statistics: $e');
      rethrow;
    }
  }
}
