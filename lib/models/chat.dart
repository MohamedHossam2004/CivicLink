import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id; // Firestore document ID
  final String userId; // Citizen's ID (identifies the conversation thread)
  final String senderId; // Actual sender: citizen's ID or "government"
  final bool
      toGov; // True if citizen sending to gov, false if gov replying to this citizen
  final String text;
  final Timestamp timestamp;

  ChatMessage({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.toGov,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      userId: data['userId'] ?? '',
      senderId: data['senderId'] ?? '',
      toGov: data['toGov'] ?? true,
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'senderId': senderId,
      'toGov': toGov,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class Conversation {
  final String citizenId;
  final String? citizenName;
  final String lastMessageText;
  final Timestamp lastMessageTimestamp;
  final String lastMessageSenderId;

  Conversation({
    required this.citizenId,
    this.citizenName,
    required this.lastMessageText,
    required this.lastMessageTimestamp,
    required this.lastMessageSenderId,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Conversation(
      citizenId: doc.id,
      citizenName: data['citizenName'],
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageTimestamp: data['lastMessageTimestamp'] ?? Timestamp.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
    );
  }
}
