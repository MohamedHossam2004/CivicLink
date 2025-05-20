import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String issueType;
  final String description;
  final double? latitude;
  final double? longitude;
  final List<String> photoUrls;
  final String status;
  final DateTime createdAt;
  final String userId;

  Report({
    this.id,
    required this.issueType,
    required this.description,
    this.latitude,
    this.longitude,
    this.photoUrls = const [],
    this.status = 'Pending',
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'issueType': issueType,
      'description': description,
      'coordinates': (latitude != null && longitude != null)
          ? GeoPoint(latitude!, longitude!) // Store as GeoPoint
          : null,
      'photoUrls': photoUrls,
      'status': status,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map, String id) {
    double? parsedLatitude;
    double? parsedLongitude;

    final dynamic coordinatesData = map['coordinates']; // Get the dynamic data

    if (coordinatesData is GeoPoint) {
      // If it's already a GeoPoint (which Firestore normally returns)
      parsedLatitude = coordinatesData.latitude;
      parsedLongitude = coordinatesData.longitude;
    } else if (coordinatesData is Map<String, dynamic>) {
      // If it's a map (e.g., from older data or manual insertion)
      parsedLatitude = (coordinatesData['latitude'] as num?)?.toDouble();
      parsedLongitude = (coordinatesData['longitude'] as num?)?.toDouble();
    }

    return Report(
      id: id,
      issueType: map['issueType'] ?? '',
      description: map['description'] ?? '',
      latitude: parsedLatitude,
      longitude: parsedLongitude,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: map['status'] ?? 'Pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
}
