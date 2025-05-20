import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final List<PollChoice> choices;

  Poll({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.expiresAt,
    required this.isActive,
    required this.choices,
  });

  factory Poll.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Poll(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: DateTime.parse(data['expiresAt']),
      isActive: data['isActive'] ?? false,
      choices: [], // Will be populated separately
    );
  }
}

class PollChoice {
  final String id;
  final String text;
  final String type;

  PollChoice({
    required this.id,
    required this.text,
    required this.type,
  });

  factory PollChoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PollChoice(
      id: doc.id,
      text: data['text'] ?? '',
      type: data['type'] ?? 'option',
    );
  }
}
