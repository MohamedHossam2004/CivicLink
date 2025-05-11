class Report {
  final String? id;
  final String issueType;
  final String description;
  final String location;
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
    required this.location,
    this.latitude,
    this.longitude,
    this.photoUrls = const [],
    this.status = 'Under Review',
    DateTime? createdAt,
    required this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'issueType': issueType,
      'description': description,
      'location': location,
      'coordinates': (latitude != null && longitude != null)
          ? {'latitude': latitude, 'longitude': longitude}
          : null,
      'photoUrls': photoUrls,
      'status': status,
      'createdAt': createdAt,
      'userId': userId,
    };
  }

  // Create Report from Firestore document
  factory Report.fromMap(Map<String, dynamic> map, String id) {
    final coordinates = map['coordinates'];

    return Report(
      id: id,
      issueType: map['issueType'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: coordinates != null ? coordinates['latitude'] : null,
      longitude: coordinates != null ? coordinates['longitude'] : null,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      status: map['status'] ?? 'Under Review',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
}
