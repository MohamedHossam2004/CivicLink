import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'cloudinary_service.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<List<String>> _uploadPhotos(List<File> photos) async {
    List<String> urls = [];
    for (var photo in photos) {
      final imageUrl = await _cloudinaryService.uploadImage(photo);
      if (imageUrl != null) {
        urls.add(imageUrl);
      }
    }
    return urls;
  }

  Future<String> submitReport({
    required String issueType,
    required String description,
    required String location,
    required LatLng? coordinates,
    required List<XFile?> photos,
  }) async {
    try {
      List<File> imageFiles =
          photos.whereType<XFile>().map((xFile) => File(xFile.path)).toList();

      final imageUrls = await _uploadPhotos(imageFiles);
      print('All photos uploaded to Cloudinary. URLs: $imageUrls');

      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final DocumentReference docRef =
          await _firestore.collection('reports').add({
        'issueType': issueType,
        'description': description,
        'location': location,
        'coordinates': coordinates != null
            ? GeoPoint(coordinates.latitude, coordinates.longitude)
            : null,
        'photoUrls': imageUrls,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'userId': userId,
      });

      print('Report details and photo URLs saved to Firestore successfully.');
      return docRef.id;
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }
}
