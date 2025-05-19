import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message (used by both citizen and government)
  Future<void> sendMessage({
    required String text,
    required bool toGov, // True if citizen sending, False if gov replying
    String?
        citizenNameForConversation, // Optional: To create/update citizen name
    String? conversationCitizenId, // Required only for government replies
  }) async {
    if (text.trim().isEmpty) return;

    try {
      // Check if user is logged in
      final user = _auth.currentUser;
      if (user == null && toGov) {
        throw Exception('User not logged in');
      }

      // Determine senderId and conversationCitizenId
      final senderId = toGov ? user!.uid : 'government';
      final effectiveCitizenId = toGov ? user!.uid : conversationCitizenId;

      if (effectiveCitizenId == null) {
        throw Exception(
            'Conversation citizen ID is required for government replies');
      }

      final messageData = ChatMessage(
        id: '', // Firestore will generate
        userId: effectiveCitizenId,
        senderId: senderId,
        toGov: toGov,
        text: text,
        timestamp: Timestamp.now(),
      );

      // Add the message to the subcollection
      await _db
          .collection('chats')
          .doc(effectiveCitizenId)
          .collection('messages')
          .add(messageData.toFirestore());

      // Update the conversation metadata in the parent document
      final conversationRef = _db.collection('chats').doc(effectiveCitizenId);
      return conversationRef.set(
        {
          'citizenId': effectiveCitizenId,
          if (citizenNameForConversation != null && toGov)
            'citizenName': citizenNameForConversation,
          'lastMessageText': text,
          'lastMessageTimestamp': messageData.timestamp,
          'lastMessageSenderId': senderId,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get stream of messages for a specific conversation
  Stream<List<ChatMessage>> getConversationStream(String citizenUserId) {
    return _db
        .collection('chats')
        .doc(citizenUserId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList());
  }

  // Get stream of all conversation metadata (for government dashboard)
  Stream<List<Conversation>> getAllConversationsStream() {
    return _db
        .collection('chats')
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc))
            .toList());
  }
}
