// lib/services/report_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/report.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get collection reference
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');

  // Submit a new report
  Future<String> submitReport({
    required String issueType,
    required String description,
    double? latitude,
    double? longitude,
    required List<File> photos,
  }) async {
    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload photos to Firebase Storage
      List<String> photoUrls = [];
      if (photos.isNotEmpty) {
        photoUrls = await _uploadPhotos(photos);
      }

      // Create report object
      final report = Report(
        issueType: issueType,
        description: description,
        latitude: latitude,
        longitude: longitude,
        photoUrls: photoUrls,
        userId: user.uid,
      );

      final docRef = await _reportsCollection.add(report.toMap());

      return docRef.id;
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  // Upload photos to Firebase Storage
  Future<List<String>> _uploadPhotos(List<File> photos) async {
    List<String> urls = [];

    for (var photo in photos) {
      if (photo.path.isEmpty) continue;

      try {
        // Generate unique filename with timestamp to avoid collisions
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        const uuid = Uuid();
        final filename = 'report_${uuid.v4()}_$timestamp.jpg';

        // Create storage reference with a simpler path
        final ref = FirebaseStorage.instance.ref().child('reports/$filename');

        // Upload file with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded_by': 'app_user'},
        );

        // Log the upload attempt
        print('Attempting to upload file: reports/$filename');

        // Upload with metadata and track progress
        final uploadTask = ref.putFile(photo, metadata);

        // Wait for upload to complete
        await uploadTask.whenComplete(() => print('Upload complete'));

        // Check if task was successful
        if (uploadTask.snapshot.state == TaskState.success) {
          // Get download URL
          final url = await ref.getDownloadURL();
          print('File uploaded successfully. URL: $url');
          urls.add(url);
        } else {
          print('Upload failed with state: ${uploadTask.snapshot.state}');
        }
      } catch (e) {
        print('Error uploading photo: $e');
        // Continue with other photos even if one fails
      }
    }

    return urls;
  }
}
