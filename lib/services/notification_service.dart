import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  FlutterLocalNotificationsPlugin? _flutterLocalNotificationsPlugin;
  AndroidNotificationChannel? _channel;
  
  bool _initialized = false;
  
  // Store a global navigator key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // Initialize the notification service
  Future<void> initialize(BuildContext? context) async {
    if (_initialized) return;
    
    // Request permission for notifications
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    print('User notification settings: ${settings.authorizationStatus}');
    
    // Setup local notifications
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Configure Android notification channel for high importance notifications
    _channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );
    
    // Register the channel with the system
    await _flutterLocalNotificationsPlugin!
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel!);
    
    // Initialize local notifications
    await _flutterLocalNotificationsPlugin!.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );
    
    // Handle FCM token changes
    _fcm.onTokenRefresh.listen(_updateFcmToken);
    
    // Get and save the FCM token
    String? token = await _fcm.getToken();
    if (token != null) {
      await _updateFcmToken(token);
    }
    
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
    
    // Handle notification clicks when app is in the background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(jsonEncode(message.data));
    });
    
    // Check for initial message (app opened from terminated state)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }
    
    _initialized = true;
  }
  
  // Save FCM token to Firestore for the current user
  Future<void> _updateFcmToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('fcm_token');
    
    // Only update if the token has changed
    if (savedToken != token) {
      await prefs.setString('fcm_token', token);
      
      // Save to user document if logged in
      User? user = _auth.currentUser;
      if (user != null) {
        try {
          // First check if user document exists
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          
          if (userDoc.exists) {
            // Update existing document
            await _firestore.collection('users').doc(user.uid).update({
              'fcmTokens': FieldValue.arrayUnion([token]),
            });
            print('Updated FCM token for user ${user.uid}');
          } else {
            // Create new document with fcmTokens field
            await _firestore.collection('users').doc(user.uid).set({
              'fcmTokens': [token],
              'userId': user.uid,
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            print('Created new user document with FCM token for user ${user.uid}');
          }
        } catch (e) {
          print('Error updating FCM token: $e');
        }
      }
    }
  }
  
  // Handle notification taps
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    try {
      print('Handling notification tap with payload: $payload');
      Map<String, dynamic> data = jsonDecode(payload);
      
      // Wait for the next frame to ensure the navigator is available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Handle different notification types
        switch (data['type']) {
          case 'chat':
            print('Navigating to chat screen');
            navigatorKey.currentState?.pushNamed('/chat');
            break;
          case 'announcement':
            print('Navigating to announcement details');
            final announcementId = data['announcementId'];
            if (announcementId != null) {
              // Navigate to specific announcement if ID is provided
              navigatorKey.currentState?.pushNamed('/announcement-details', arguments: {'id': announcementId});
            } else {
              // Otherwise just go to announcements list
              navigatorKey.currentState?.pushNamed('/home');
            }
            break;
          case 'task':
            print('Navigating to task details');
            final taskId = data['taskId'];
            if (taskId != null) {
              // Navigate to specific task if ID is provided
              navigatorKey.currentState?.pushNamed('/task-details', arguments: {'id': taskId});
            } else {
              // Otherwise go to tasks list
              navigatorKey.currentState?.pushNamed('/volunteer');
            }
            break;
          default:
            // Default handling - go to home
            print('Unknown notification type, navigating to home');
            navigatorKey.currentState?.pushNamed('/home');
            break;
        }
      });
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }
  
  // Show local notification
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null && _flutterLocalNotificationsPlugin != null && _channel != null) {
      _flutterLocalNotificationsPlugin!.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel!.id,
            _channel!.name,
            channelDescription: _channel!.description,
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }
  
  // Subscribe to topic for receiving specific types of notifications
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }
  
  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
  
  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    // Get user FCM tokens
    final userDoc = await _firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      print('User document does not exist');
      return;
    }
    
    final userData = userDoc.data();
    if (userData == null) return;
    
    final List<dynamic> tokens = userData['fcmTokens'] ?? [];
    
    if (tokens.isEmpty) {
      print('No FCM tokens found for user');
      return;
    }
    
    // Create notification document in Firestore
    // This will trigger a Cloud Function to send the actual notification
    await _firestore.collection('notifications').add({
      'tokens': tokens,
      'title': title,
      'body': body,
      'type': type,
      'data': data ?? {},
      'sentAt': FieldValue.serverTimestamp(),
      'userId': userId,
    });
  }

  // Test notification - can be called from anywhere to verify notifications are working
  Future<void> sendTestNotification(String userId) async {
    try {
      print('Attempting to send test notification to user: $userId');
      
      // First, check if the user document exists and has FCM tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document does not exist, creating one...');
        // Try to create the user document with current token
        String? token = await _fcm.getToken();
        if (token != null) {
          await _firestore.collection('users').doc(userId).set({
            'userId': userId,
            'fcmTokens': [token],
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('Created user document and set FCM token: $token');
        } else {
          print('Could not get FCM token, cannot send test notification');
          return;
        }
      }
      
      // Send via local notifications first (doesn't require FCM backend)
      if (_flutterLocalNotificationsPlugin != null && _channel != null) {
        print('Sending local test notification');
        await _flutterLocalNotificationsPlugin!.show(
          0,
          'Test Notification',
          'This is a test notification from CivicLink',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel!.id,
              _channel!.name,
              channelDescription: _channel!.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
        
        // Try sending a second notification after a slight delay
        await Future.delayed(const Duration(seconds: 2));
        await _flutterLocalNotificationsPlugin!.show(
          1,
          'Chat Notification',
          'You have a new message in your chats!',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel!.id,
              _channel!.name,
              channelDescription: _channel!.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: '{"type":"chat","chatId":"test-chat"}',
        );
        
        print('Local notifications sent successfully');
        return; // We've sent the notifications locally, no need for Firestore trigger
      } else {
        print('Flutter local notifications plugin not initialized');
      }
      
      // Since Cloud Functions may not be available due to payment plan,
      // we won't rely on Firestore triggers
      
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // Show a local notification directly
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize(null);
    }
    
    if (_flutterLocalNotificationsPlugin != null && _channel != null) {
      await _flutterLocalNotificationsPlugin!.show(
        title.hashCode, // Use title hashcode as notification ID
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel!.id,
            _channel!.name,
            channelDescription: _channel!.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      print('Local notification shown: $title');
    } else {
      print('Cannot show notification: plugin or channel not initialized');
    }
  }
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will be called when the app is in the background or terminated
  print('Background message received: ${message.notification?.title}');
} 