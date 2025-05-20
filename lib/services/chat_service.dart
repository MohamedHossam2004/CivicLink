import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

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
      await conversationRef.set(
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
      
      // Send notification for new message
      if (!toGov) {
        // Government sending message to citizen, notify the citizen
        await _notificationService.sendNotificationToUser(
          userId: effectiveCitizenId,
          title: 'New Message from CivicLink',
          body: 'You have received a new message from the government',
          type: 'chat',
          data: {
            'conversationId': effectiveCitizenId,
          },
        );
      } else if (toGov) {
        // Message from citizen to government
        // You can notify admins or specific department staffs through a Cloud Function
        // This would be handled server-side
      }
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
