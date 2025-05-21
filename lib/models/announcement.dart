import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Announcement {
  final String id;
  final String label;
  final String name;
  final DateTime createdOn;
  final DateTime startTime;
  final DateTime endTime;
  final String department;
  final String description;
  final String? documentUrl;
  final GeoPoint location;
  final String phone;
  final String email;
  final bool isImportant;
  final List<String> imageUrls;

  Announcement({
    required this.id,
    required this.label,
    required this.name,
    required this.createdOn,
    required this.startTime,
    required this.endTime,
    required this.department,
    required this.description,
    this.documentUrl,
    required this.location,
    required this.phone,
    required this.email,
    this.isImportant = false,
    this.imageUrls = const [],
  });

  // Create a copy of the announcement with updated fields
  Announcement copyWith({
    String? id,
    String? label,
    String? name,
    DateTime? createdOn,
    DateTime? startTime,
    DateTime? endTime,
    String? department,
    String? description,
    String? documentUrl,
    GeoPoint? location,
    String? phone,
    String? email,
    bool? isImportant,
    List<String>? imageUrls,
  }) {
    return Announcement(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      createdOn: createdOn ?? this.createdOn,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      department: department ?? this.department,
      description: description ?? this.description,
      documentUrl: documentUrl ?? this.documentUrl,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isImportant: isImportant ?? this.isImportant,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  // Convert Firestore document to Announcement
  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime parseTimestamp(dynamic value) {
      try {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          // Try different date formats
          try {
            return DateTime.parse(value);
          } catch (e) {
            // If standard format fails, try custom formats
            final formats = [
              'yyyy-MM-dd HH:mm:ss',
              'yyyy-MM-dd',
              'dd/MM/yyyy HH:mm:ss',
              'dd/MM/yyyy',
              'MM/dd/yyyy HH:mm:ss',
              'MM/dd/yyyy',
            ];
            
            for (final format in formats) {
              try {
                return DateFormat(format).parse(value);
              } catch (_) {
                continue;
              }
            }
            print('Warning: Could not parse date string: $value');
            return DateTime.now();
          }
        } else if (value is DateTime) {
          return value;
        } else if (value == null) {
          print('Warning: Date value is null, using current time');
          return DateTime.now();
        }
        print('Warning: Invalid date value type: ${value.runtimeType}');
        return DateTime.now();
      } catch (e) {
        print('Error parsing date: $e');
        return DateTime.now();
      }
    }

    GeoPoint parseLocation(dynamic value) {
      try {
        if (value is GeoPoint) {
          return value;
        } else if (value is Map<String, dynamic>) {
          // Convert map to GeoPoint, handling both int and double values
          double parseCoordinate(dynamic coord) {
            if (coord is double) return coord;
            if (coord is int) return coord.toDouble();
            if (coord is String) {
              try {
                return double.parse(coord);
              } catch (e) {
                print('Warning: Could not parse coordinate string: $coord');
                return 0.0;
              }
            }
            print('Warning: Invalid coordinate type: ${coord.runtimeType}');
            return 0.0;
          }

          return GeoPoint(
            parseCoordinate(value['latitude']),
            parseCoordinate(value['longitude']),
          );
        }
        print('Warning: Invalid location type: ${value.runtimeType}');
        return const GeoPoint(0.0, 0.0);
      } catch (e) {
        print('Error parsing location: $e');
        return const GeoPoint(0.0, 0.0);
      }
    }

    // Parse image URLs
    List<String> parseImageUrls(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return List<String>.from(value.map((item) => item.toString()));
      }
      return [];
    }

    return Announcement(
      id: doc.id,
      label: data['label'] ?? '',
      name: data['name'] ?? '',
      createdOn: parseTimestamp(data['createdOn']),
      startTime: parseTimestamp(data['startTime']),
      endTime: parseTimestamp(data['endTime']),
      department: data['department'] ?? '',
      description: data['description'] ?? '',
      documentUrl: data['documentUrl'],
      location: parseLocation(data['location']),
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      isImportant: data['isImportant'] ?? false,
      imageUrls: parseImageUrls(data['imageUrls']),
    );
  }

  // Convert Announcement to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'name': name,
      'createdOn': Timestamp.fromDate(createdOn),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'department': department,
      'description': description,
      'documentUrl': documentUrl,
      'location': location,
      'phone': phone,
      'email': email,
      'isImportant': isImportant,
      'imageUrls': imageUrls,
    };
  }
}

class Comment {
  final String id;
  final String announcementId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final String? firstName;
  final String? lastName;
  final bool isAnonymous;

  Comment({
    required this.id,
    required this.announcementId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.firstName,
    this.lastName,
    this.isAnonymous = false,
  });

  // Convert Firestore document to Comment
  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      announcementId: data['announcementId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      likesCount: data['likesCount'] ?? 0,
      firstName: data['firstName'],
      lastName: data['lastName'],
      isAnonymous: data['isAnonymous'] ?? false,
    );
  }

  // Convert Comment to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'announcementId': announcementId,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likesCount': likesCount,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      'isAnonymous': isAnonymous,
    };
  }

  String get displayName {
    if (isAnonymous) {
      return 'Anonymous';
    }
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return userId;
  }

  Comment copyWith({
    String? id,
    String? announcementId,
    String? userId,
    String? content,
    DateTime? createdAt,
    int? likesCount,
    String? firstName,
    String? lastName,
    bool? isAnonymous,
  }) {
    return Comment(
      id: id ?? this.id,
      announcementId: announcementId ?? this.announcementId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}

class Reply {
  final String id;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final bool isOfficial;
  final int likes;

  Reply({
    required this.id,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.isOfficial = false,
    this.likes = 0,
  });
}