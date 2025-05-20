import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/poll.dart';
import '../../models/poll_comment.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_view.dart';

class PollDetailScreen extends StatefulWidget {
  final String pollId;

  const PollDetailScreen({
    super.key,
    required this.pollId,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen> {
  final _commentController = TextEditingController();
  final _isAnonymousController = ValueNotifier<bool>(true);
  bool _isSubmitting = false;
  String? _selectedChoiceId;
  bool _hasVoted = false;
  List<PollChoice> _choices = [];
  Map<String, int> _choiceVotes = {};
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _loadChoices();
    _checkIfUserVoted();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _isAnonymousController.dispose();
    super.dispose();
  }

  Future<void> _loadChoices() async {
    try {
      final choicesSnapshot = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('choices')
          .get();

      setState(() {
        _choices = choicesSnapshot.docs
            .map((doc) => PollChoice.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading choices: $e')),
        );
      }
    }
  }

  Future<void> _checkIfUserVoted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userType = userDoc.data()?['type'] as String?;

        // Check if user has voted
        final voteDoc = await FirebaseFirestore.instance
            .collection('pollVotes')
            .where('pollId', isEqualTo: widget.pollId)
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          _hasVoted = voteDoc.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking vote status: $e');
    }
  }

  Future<void> _submitVote() async {
    if (_selectedChoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an option')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to vote')),
        );
        return;
      }

      // Check user type
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userType = userDoc.data()?['type'] as String?;

      // Only allow regular users to vote
      if (userType != null && userType != 'User') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Admin and advertiser users cannot vote')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('pollVotes').add({
        'pollId': widget.pollId,
        'choiceId': _selectedChoiceId,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _hasVoted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting vote: $e')),
      );
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to comment')),
        );
        return;
      }

      // Check user type
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userType = userDoc.data()?['type'] as String?;

      // Only allow regular users to comment
      if (userType != null && userType != 'Regular') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Admin and advertiser users cannot comment')),
        );
        return;
      }

      // Check if user has already commented
      final existingComment = await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (existingComment.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already commented on this poll')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('polls')
          .doc(widget.pollId)
          .collection('comments')
          .add({
        'content': _commentController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'firstName': userDoc.data()?['firstName'] ?? '',
        'lastName': userDoc.data()?['lastName'] ?? '',
        'isAnonymous': _isAnonymousController.value,
        'userId': user.uid,
      });

      _commentController.clear();
      _isAnonymousController.value = false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Poll Details',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('polls')
            .doc(widget.pollId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              message: 'Error loading poll: ${snapshot.error}',
              onRetry: () {
                // The stream will automatically retry
              },
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final poll = Poll.fromFirestore(snapshot.data!);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poll details
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  poll.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.text,
                                  ),
                                ),
                                if (poll.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    poll.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.text.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                Text(
                                  'Expires: ${_formatDate(poll.expiresAt)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.text.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Voting section
                      const Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, userSnapshot) {
                          final userType =
                              userSnapshot.data?.get('type') as String?;
                          final isRegularUser =
                              userType == null || userType == 'User';
                          final showVotingOptions = isRegularUser && !_hasVoted;

                          if (showVotingOptions) {
                            // Show voting options for regular users who haven't voted
                            return Column(
                              children: _choices.map((choice) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: RadioListTile<String>(
                                    value: choice.id,
                                    groupValue: _selectedChoiceId,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedChoiceId = value;
                                      });
                                    },
                                    title: Text(choice.text),
                                    activeColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          } else {
                            // Show results for everyone else
                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('pollVotes')
                                  .where('pollId', isEqualTo: widget.pollId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                final votes = snapshot.data!.docs;
                                final totalVotes = votes.length;
                                final choiceVotes = <String, int>{};

                                for (var vote in votes) {
                                  final data =
                                      vote.data() as Map<String, dynamic>;
                                  final choiceId = data['choiceId'] as String;
                                  choiceVotes[choiceId] =
                                      (choiceVotes[choiceId] ?? 0) + 1;
                                }

                                return Column(
                                  children: _choices.map((choice) {
                                    final votes = choiceVotes[choice.id] ?? 0;
                                    final percentage = totalVotes > 0
                                        ? (votes / totalVotes * 100)
                                            .toStringAsFixed(1)
                                        : '0.0';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _selectedChoiceId == choice.id
                                              ? AppTheme.primary
                                              : Colors.grey.shade200,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            choice.text,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: totalVotes > 0
                                                ? votes / totalVotes
                                                : 0,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              AppTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$percentage% ($votes votes)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.text
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            );
                          }
                        },
                      ),

                      if (!_hasVoted) ...[
                        const SizedBox(height: 24),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, userSnapshot) {
                            final userType =
                                userSnapshot.data?.get('type') as String?;
                            final isRegularUser =
                                userType == null || userType == 'User';

                            if (!isRegularUser) {
                              return const SizedBox.shrink();
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitVote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor:
                                      AppTheme.primary.withOpacity(0.5),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Submit Vote',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Comments section
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Add comment section
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('polls')
                            .doc(widget.pollId)
                            .collection('comments')
                            .where('userId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          // If user has already commented, don't show the input box
                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            return const SizedBox.shrink();
                          }

                          // Check if user is admin or advertiser
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final userType =
                                  userSnapshot.data?.get('type') as String?;
                              // Don't show comment box for admin or advertiser users
                              if (userType == 'Admin' ||
                                  userType == 'Advertiser') {
                                return const SizedBox.shrink();
                              }

                              return Card(
                                elevation: 2,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: _commentController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          hintText: 'Write your comment...',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isAnonymousController,
                                        builder: (context, isAnonymous, child) {
                                          return Row(
                                            children: [
                                              Checkbox(
                                                value: isAnonymous,
                                                onChanged: (value) {
                                                  _isAnonymousController.value =
                                                      value!;
                                                },
                                                activeColor: AppTheme.primary,
                                              ),
                                              const Text('Post anonymously'),
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submitComment,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isSubmitting
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text('Post Comment'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Comments list
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('polls')
                            .doc(widget.pollId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, commentsSnapshot) {
                          if (commentsSnapshot.hasError) {
                            return Text('Error: ${commentsSnapshot.error}');
                          }

                          if (commentsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final comments = commentsSnapshot.data?.docs
                                  .map((doc) => PollComment.fromFirestore(doc))
                                  .toList() ??
                              [];

                          if (comments.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No comments yet. Be the first to comment!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.text.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color:
                                                AppTheme.text.withOpacity(0.5),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            comment.isAnonymous
                                                ? 'Anonymous'
                                                : '${comment.firstName} ${comment.lastName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.text
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(comment.createdAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.text
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        comment.content,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
