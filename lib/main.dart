// main.dart
import 'package:flutter/material.dart';
import 'package:gov_app/models/task.dart';
import 'package:gov_app/screens/Chat/chat_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gov_app/screens/calendar/calendar_page.dart';
import 'package:gov_app/screens/calendar/event_detail_page.dart';
import 'package:gov_app/screens/home/home_screen.dart';
import 'package:gov_app/services/notification_service.dart';
import 'package:gov_app/services/announcement_service.dart';
import 'package:gov_app/services/task_service.dart';
import 'package:gov_app/widgets/bottom_nav_bar.dart';
import 'package:gov_app/screens/volunteer/volunteer_page.dart';
import 'package:gov_app/screens/Auth/loginPage.dart';
import 'package:gov_app/screens/Auth/registrationPage.dart';
import 'screens/ReportIssue/report_issue_step1.dart';
import 'package:gov_app/screens/profile/profile_page.dart';
import 'package:gov_app/services/auth_service.dart';
import 'package:gov_app/services/content_moderation_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gov_app/services/chat_service.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  print('Background message received: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    print('Environment variables loaded successfully');
  } catch (e) {
    print('Failed to load environment variables: $e');
  }

  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize FCM settings early
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Request permission for notifications right at startup
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Get FCM token for debugging
  final fcmToken = await FirebaseMessaging.instance.getToken();
  print('FCM Token: $fcmToken');

  // Configure Firebase Auth settings globally
  try {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
    print('Main: Firebase Auth settings configured successfully');
  } catch (e) {
    print('Main: Error configuring Firebase Auth settings: $e');
  }

  // Initialize content moderation service
  _initializeContentModeration();

  await initializeDateFormatting();
  runApp(const MyApp());
}

// Initialize content moderation service
void _initializeContentModeration() {
  final contentModerationService = ContentModerationService();

  // Initialize with environment variables or defaults
  contentModerationService.initialize(
    // In production, set testMode to false
    testModeOverride: false,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'CivicLink',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/event-details': (context) => const EventDetailPage(),
        '/volunteer': (context) =>
            VolunteerPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
        '/chat': (context) => ChatScreen(),
        '/calendar': (context) =>
            CalendarPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final userCredential = await _authService.autoLogin();
      setState(() {
        _isLoggedIn = userCredential != null;
        _isLoading = false;
      });
      
      // Initialize notification service after login status is determined
      if (_isLoggedIn) {
        await _notificationService.initialize(context);
        // Subscribe to relevant topics based on user role or preferences
        await _notificationService.subscribeToTopic('announcements');
      }
    } catch (e) {
      print('Error checking login status: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainScreen() : const LoginPage();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final AnnouncementService _announcementService = AnnouncementService();
  final TaskService _taskService = TaskService();
  final ChatService _chatService = ChatService();

  final List<Widget> _screens = [
    const HomeScreen(),
    VolunteerPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    ChatScreen(),
    CalendarPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    
    // Start listeners for notifications
    _announcementService.startAnnouncementListener();
    _taskService.startTaskUpdateListener();
    _chatService.startMessageListener();
  }

  void changeIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
