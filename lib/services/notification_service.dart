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
        await _firestore.collection('users').doc(user.uid).update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        });
      }
    }
  }
  
  // Handle notification taps
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    try {
      Map<String, dynamic> data = jsonDecode(payload);
      
      // Handle different notification types
      switch (data['type']) {
        case 'chat':
          // Navigate to chat screen
          break;
        case 'announcement':
          // Navigate to announcement details
          break;
        case 'task':
          // Navigate to task details
          break;
        default:
          // Default handling
          break;
      }
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
}

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This function will be called when the app is in the background or terminated
  print('Background message received: ${message.notification?.title}');
} 