import 'package:flutter/material.dart';
import 'package:gov_app/screens/Chat/citizen_chat_screen.dart'; // Ensure this path is correct
import 'package:gov_app/screens/Chat/government_chat_list.dart'; // Ensure this path is correct
import '../../services/auth_service.dart'; // Ensure this path is correct

class ChatScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _authService.getUserDetails(), // Async call to get user details
      builder: (context, snapshot) {
        // Show loading state while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          print(
              "ChatScreen: Error from getUserDetails: ${snapshot.error}"); // Log the error
          return Scaffold(
            appBar: AppBar(
              title: const Text("Chat Error"),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              automaticallyImplyLeading: false,
              elevation: 1,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading user details.',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Details: ${snapshot.error}', // Show the specific error
                      style:
                          TextStyle(color: Colors.red.shade700, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Replace with your actual navigation to the login screen
                        // Example: Navigator.of(context).pushReplacementNamed('/login');
                        print(
                            "ChatScreen: Navigating to login screen (error case)");
                        Navigator.of(context).pushNamed('login');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Handle case where no user data is returned (user is not logged in)
        final user = snapshot.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Access Denied"),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Please log in to access the chat.',
                      style: TextStyle(fontSize: 18, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        print(
                            "ChatScreen: Navigating to login screen (user null)");
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Check user type and return appropriate screen
        if (user['type'] == 'Admin') {
          return GovernmentChatListScreen();
        }
        // If not admin, and user is not null, they are a citizen
        return const CitizenChatScreen();
      },
    );
  }
}
