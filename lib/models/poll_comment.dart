import 'package:cloud_firestore/cloud_firestore.dart';

class PollComment {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? firstName;
  final String? lastName;
  final bool isAnonymous;
  final String userId;

  PollComment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.firstName,
    this.lastName,
    required this.isAnonymous,
    required this.userId,
  });

  factory PollComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollComment(
      id: doc.id,
      content: data['content'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      isAnonymous: data['isAnonymous'] as bool,
      userId: data['userId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'firstName': firstName,
      'lastName': lastName,
      'isAnonymous': isAnonymous,
      'userId': userId,
    };
  }
}
