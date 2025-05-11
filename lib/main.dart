// main.dart
import 'package:flutter/material.dart';
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
      home: const LoginPage(),
      routes: {
        '/home': (context) => const MainScreen(),
        '/event-details': (context) => const EventDetailPage(),
        '/volunteer': (context) => const VolunteerPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationPage(),
      },
    );
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
    const CalendarPage(),
    const Placeholder(), // Chat page
    const ReportIssueStep1(),
    const Placeholder(), // Profile page
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
