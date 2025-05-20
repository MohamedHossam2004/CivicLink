import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
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
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      // Send notification for new message
      if (!toGov) {
        // Government sending message to citizen, notify the citizen
        try {
          // Get the user's FCM tokens - for future FCM implementation
          final userDoc = await _db.collection('users').doc(effectiveCitizenId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData['fcmTokens'] != null) {
              // FCM tokens exist, but we'll use local notifications for now
              // since Cloud Functions require a paid plan
              print('User has FCM tokens, would send push notification');
            }
          }
          
          // Initialize notification service if needed
          await _notificationService.initialize(null);
          
          // Send local notification directly - this works without Cloud Functions
          await _notificationService.showLocalNotification(
            title: 'New Message',
            body: 'You have received a new message',
            payload: jsonEncode({
              'type': 'chat',
              'conversationId': effectiveCitizenId
            })
          );
          
          print('Local notification sent for new message to: $effectiveCitizenId');
        } catch (e) {
          print('Error sending notification: $e');
        }
      } else if (toGov) {
        // Message from citizen to government
        // Would notify admins through Cloud Functions, but we'll skip for now
        print('Message sent to government from user: $effectiveCitizenId');
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

  // Listen for incoming messages for the current user
  void startMessageListener() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('Cannot start message listener: User not logged in');
      return;
    }
    
    print('Starting message listener for user: ${currentUser.uid}');
    
    // Listen to the user's chat document
    _db.collection('chats')
      .doc(currentUser.uid)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) async {
        if (snapshot.docs.isEmpty) return;
        
        final latestMessage = snapshot.docs.first;
        final messageData = latestMessage.data();
        
        // Only show notification for new messages from the government
        if (messageData['senderId'] == 'government') {
          // Check if this is a new message (created within the last minute)
          final timestamp = messageData['timestamp'] as Timestamp;
          final now = DateTime.now();
          final messageTime = timestamp.toDate();
          final difference = now.difference(messageTime);
          
          if (difference.inMinutes <= 1) {
            // This is a recent message, show notification
            await _notificationService.showLocalNotification(
              title: 'New Message from CivicLink',
              body: messageData['text'] ?? 'You have a new message',
              payload: jsonEncode({
                'type': 'chat',
                'conversationId': currentUser.uid,
                'messageId': latestMessage.id
              }),
            );
            
            print('Notification shown for new message from government');
          }
        }
      },
      onError: (error) {
        print('Error listening for messages: $error');
      });
  }
  
  // Get conversation metadata for the current user
  Future<Map<String, dynamic>?> getConversationMetadata() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    final doc = await _db.collection('chats').doc(currentUser.uid).get();
    return doc.data();
  }
}
