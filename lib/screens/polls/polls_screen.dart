import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_app/models/poll.dart';
import 'package:gov_app/screens/polls/poll_detail_screen.dart';
import 'package:gov_app/theme/app_theme.dart';
import 'package:gov_app/widgets/loading_indicator.dart';
import 'package:gov_app/widgets/error_view.dart';
import 'create_poll_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({super.key});

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        setState(() {
          _isAdmin = userDoc.data()?['type'] == 'Admin';
        });
      }
    } catch (e) {
      print('Error checking admin status: $e');
    }
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      // Handle the format "2025-010-30T00:00:00Z"
      final parts = dateValue.split('-');
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2].split('T')[0]);
        return DateTime(year, month, day);
      }
      throw FormatException('Invalid date format: $dateValue');
    }
    throw FormatException('Unsupported date type: ${dateValue.runtimeType}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Polls',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePollScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Polls Error: ${snapshot.error}');
            return ErrorView(
              message: 'Error loading polls: ${snapshot.error}',
              onRetry: () {
                // The stream will automatically retry
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          // Filter out the _schema document and expired polls
          final polls = snapshot.data?.docs.where((doc) {
                if (doc.id == '_schema') return false;

                final data = doc.data() as Map<String, dynamic>;
                final expiresAtStr = data['expiresAt'] as String;
                try {
                  final expiresAt = _parseDate(expiresAtStr);
                  final isExpired = expiresAt.isBefore(DateTime.now());

                  print('Poll ${doc.id}:');
                  print('- Title: ${data['title']}');
                  print('- isActive: ${data['isActive']}');
                  print('- expiresAt: $expiresAt');
                  print('- isExpired: $isExpired');

                  return !isExpired;
                } catch (e) {
                  print('Error parsing date for poll ${doc.id}: $e');
                  return false;
                }
              }).toList() ??
              [];

          print('Total polls after filtering: ${polls.length}');

          if (polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.poll_outlined,
                    size: 64,
                    color: AppTheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active polls',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = Poll.fromFirestore(polls[index]);
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('polls')
                    .doc(poll.id)
                    .collection('choices')
                    .snapshots(),
                builder: (context, choicesSnapshot) {
                  final choicesCount = choicesSnapshot.data?.docs.length ?? 0;

                  // Skip polls with no options
                  if (choicesCount == 0) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PollDetailScreen(pollId: poll.id),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.poll_outlined,
                                    color: AppTheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    poll.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (poll.description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                poll.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.text.withOpacity(0.7),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Expires: ${_formatDate(poll.expiresAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.text.withOpacity(0.5),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$choicesCount options',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
