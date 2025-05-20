// main.dart
import 'package:flutter/material.dart';
import 'package:gov_app/models/task.dart';
import 'package:gov_app/screens/Chat/chat_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_app/screens/calendar/calendar_page.dart';
import 'package:gov_app/screens/calendar/event_detail_page.dart';
import 'package:gov_app/screens/home/home_screen.dart';
import 'package:gov_app/widgets/bottom_nav_bar.dart';
import 'package:gov_app/screens/volunteer/volunteer_page.dart';
import 'package:gov_app/screens/Auth/loginPage.dart';
import 'package:gov_app/screens/Auth/registrationPage.dart';
import 'screens/ReportIssue/report_issue_step1.dart';
import 'package:gov_app/screens/profile/profile_page.dart';
import 'package:gov_app/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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

  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/calendar': (context) => const CalendarPage(),
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
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    VolunteerPage(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    ChatScreen(),
    const CalendarPage(),
    const ProfilePage(),
  ];

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
