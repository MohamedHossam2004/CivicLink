import 'package:flutter/material.dart';
import 'package:gov_app/config/theme.dart';
import 'package:gov_app/screens/emergency/emergency_page.dart';
import 'package:gov_app/screens/home/widgets/announcement_card.dart';
import 'package:gov_app/screens/home/widgets/task_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gov_app/screens/reportIssue/report_issue_step1.dart';
import '../announcement/announcements_screen.dart';
import '../announcement/announcement_detail_screen.dart';
import '../volunteer/task_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task.dart';
import '../../utils/date_formatter.dart';
import '../volunteer/volunteer_page.dart';
import '../advertisements/advertisements_screen.dart';
import '../polls/polls_screen.dart';
import '../../main.dart';
import '../admin/admin_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _featuredTask;
  bool _isLoading = true;
  String? _error;

  // User data fields
  String _fullName = '';
  String _userInitials = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchData();
  }

  // Fetch current user's data
  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          // Get the user's full name
          final firstName = userData['firstName'] ?? '';
          final lastName = userData['lastName'] ?? '';
          final fullName = userData['fullName'] ?? '$firstName $lastName';

          // Create initials from the first letters of first and last name
          String initials = '';
          if (firstName.isNotEmpty) initials += firstName[0];
          if (lastName.isNotEmpty) initials += lastName[0];

          setState(() {
            _fullName = fullName;
            _userInitials = initials.toUpperCase();
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      // Fetch featured task (task with most volunteers)
      final featuredTaskSnapshot = await _firestore
          .collection('tasks')
          .orderBy('currVolunteers', descending: true)
          .limit(10) // Get top 10 tasks by volunteer count
          .get();

      print(
          'Fetched ${featuredTaskSnapshot.docs.length} tasks for featured section');

      if (featuredTaskSnapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        // Filter out tasks that have ended and get the first one
        final activeTasks = featuredTaskSnapshot.docs.where((doc) {
          final endTimeData = doc.data()['endTime'];
          DateTime endTime;

          if (endTimeData is Timestamp) {
            endTime = endTimeData.toDate();
          } else if (endTimeData is String) {
            try {
              endTime = DateTime.parse(endTimeData);
            } catch (e) {
              print('Error parsing end time: $e');
              return false;
            }
          } else {
            print('Invalid end time format: $endTimeData');
            return false;
          }

          return endTime.isAfter(now);
        }).toList();

        print('Found ${activeTasks.length} active tasks');

        if (activeTasks.isNotEmpty) {
          final doc = activeTasks.first;
          setState(() {
            _featuredTask = {
              ...doc.data(),
              'id': doc.id,
            };
          });
          print('Set featured task: ${_featuredTask!['name']}');
        } else {
          print('No active tasks found');
          setState(() {
            _featuredTask = null;
          });
        }
      }

      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .orderBy('createdOn', descending: true)
          .limit(2)
          .get();

      final announcements = announcementsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .orderBy('createdOn')
          .limit(10)
          .get();

      // Get unique tasks by name to avoid repetition and filter out tasks with passed deadlines
      final now = DateTime.now();
      final tasks = tasksSnapshot.docs
          .map((doc) {
            final data = doc.data();
            return {
              ...data,
              'id': doc.id,
            };
          })
          .where((task) {
            final endTimeData = task['endTime'];
            DateTime endTime;

            if (endTimeData is Timestamp) {
              endTime = endTimeData.toDate();
            } else if (endTimeData is String) {
              try {
                endTime = DateTime.parse(endTimeData);
              } catch (e) {
                return false;
              }
            } else {
              return false;
            }

            return endTime.isAfter(now);
          })
          .fold<Map<String, Map<String, dynamic>>>({}, (map, task) {
            if (!map.containsKey(task['name'])) {
              map[task['name']] = task;
            }
            return map;
          })
          .values
          .take(3)
          .toList();

      setState(() {
        _announcements = announcements;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    print(
        'Building home screen with featured task: ${_featuredTask != null ? _featuredTask!['name'] : 'null'}');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildServicesSection(),
                  const SizedBox(height: 24),
                  _buildFeaturedTask(),
                  const SizedBox(height: 24),
                  _buildUpcomingTasksSection(),
                  const SizedBox(height: 24),
                  _buildAnnouncementsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryLightColor,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _userInitials.isEmpty ? 'U' : _userInitials,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _fullName.isEmpty ? 'User' : _fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search services, tasks, announcements...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey.shade500,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Government Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildServiceItem(
                icon: Icons.location_on_outlined,
                label: 'Report',
                color: Colors.red,
                bgColor: Colors.red.shade100,
                onTap: () async {
                  final user = _auth.currentUser;
                  if (user != null) {
                    final userDoc = await _firestore
                        .collection('users')
                        .doc(user.uid)
                        .get();
                    if (userDoc.exists && userDoc.data()?['type'] == 'Admin') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AdminDashboard()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReportIssueStep1()),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReportIssueStep1()),
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: _buildServiceItem(
                icon: Icons.notifications_none,
                label: 'Updates',
                color: AppTheme.communityColor,
                bgColor: AppTheme.communityColor.withOpacity(0.1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AnnouncementsScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildServiceItem(
                icon: Icons.campaign_outlined,
                label: 'Ads',
                color: AppTheme.primaryColor,
                bgColor: AppTheme.primaryLightColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdvertisementsScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildServiceItem(
                icon: Icons.poll_outlined,
                label: 'Polls',
                color: Colors.orange,
                bgColor: Colors.orange.shade100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PollsScreen()),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildServiceItem(
                icon: Icons.warning_amber_outlined,
                label: 'Contacts',
                color: Colors.red,
                bgColor: Colors.red.shade100,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EmergencyNumbersPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTask() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _featuredTask != null
              ? () async {
                  final doc = await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(_featuredTask!['id'])
                      .get();
                  if (doc.exists) {
                    final task = Task.fromFirestore(doc);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: task,
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                      ),
                    );
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_featuredTask != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _featuredTask!['label'] ?? 'Featured Task',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_featuredTask!['currVolunteers'] ?? 0}/${_featuredTask!['maxVolunteers'] ?? 0} Volunteers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _featuredTask!['name'] ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _featuredTask!['description'] ?? 'No description available',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(_featuredTask!['startTime']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_featuredTask!['endTime']),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _featuredTask!['location'] != null
                                ? '${_featuredTask!['location']['latitude']}, ${_featuredTask!['location']['longitude']}'
                                : 'No location set',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final doc = await FirebaseFirestore.instance
                              .collection('tasks')
                              .doc(_featuredTask!['id'])
                              .get();
                          if (doc.exists) {
                            final task = Task.fromFirestore(doc);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskDetailPage(
                                  task: task,
                                  userId:
                                      FirebaseAuth.instance.currentUser?.uid ??
                                          '',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Join Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Featured Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'There are currently no active tasks that need volunteers. Check back later for new opportunities!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No date set';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid date';
      }
    } else {
      return 'Invalid date';
    }

    return DateFormatter.format(date);
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'No time set';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        return 'Invalid time';
      }
    } else {
      return 'Invalid time';
    }

    return DateFormatter.formatWithTime(date);
  }

  Widget _buildUpcomingTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Find the MainScreen ancestor and update its index
                final mainScreen =
                    context.findAncestorStateOfType<MainScreenState>();
                if (mainScreen != null) {
                  mainScreen.changeIndex(1); // Switch to Tasks tab
                }
              },
              child: const Row(
                children: [
                  Text('View All'),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Upcoming Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are currently no upcoming tasks. Check back later for new opportunities!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ..._tasks.map((task) {
            // Format the date and time
            final startTime = task['startTime'];
            final endTime = task['endTime'];

            String formattedDate = 'No date set';
            String formattedTime = 'No time set';

            if (startTime != null) {
              if (startTime is Timestamp) {
                formattedDate = DateFormatter.format(startTime);
              } else if (startTime is String) {
                try {
                  final date = DateTime.parse(startTime);
                  formattedDate = DateFormatter.format(date);
                } catch (e) {
                  // Handle parsing error silently
                }
              }
            }

            if (endTime != null) {
              if (endTime is Timestamp) {
                formattedTime = DateFormatter.formatWithTime(endTime);
              } else if (endTime is String) {
                try {
                  final date = DateTime.parse(endTime);
                  formattedTime = DateFormatter.formatWithTime(date);
                } catch (e) {
                  // Handle parsing error silently
                }
              }
            }

            return TaskCard(
              title: task['name'] ?? '',
              location: task['location'] != null
                  ? '${task['location']['latitude']}, ${task['location']['longitude']}'
                  : '',
              date: formattedDate,
              time: formattedTime,
              category: task['label'] ?? '',
              participants: task['currVolunteers'] ?? 0,
              maxParticipants: task['maxVolunteers'] ?? 0,
              color: _getCategoryColor(task['label']),
              onTap: () async {
                final taskId = task['id'];

                if (taskId != null) {
                  final taskDoc = await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(taskId)
                      .get();

                  if (taskDoc.exists) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailPage(
                          task: Task.fromFirestore(taskDoc),
                          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                        ),
                      ),
                    );
                  }
                }
              },
            );
          }),
      ],
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Latest Announcements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnnouncementsScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text('View All'),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._announcements.map((announcement) {
          // Format the date
          String formattedDate = 'No date set';
          final timestamp =
              announcement['startTime'] ?? announcement['createdOn'];

          if (timestamp != null) {
            if (timestamp is Timestamp) {
              formattedDate = DateFormatter.format(timestamp);
            } else if (timestamp is String) {
              try {
                final date = DateTime.parse(timestamp);
                formattedDate = DateFormatter.format(date);
              } catch (e) {
                // Handle parsing error silently
              }
            }
          }

          return AnnouncementCard(
            title: announcement['name'] ?? '',
            description: announcement['description'] ?? '',
            date: formattedDate,
            category: announcement['label'] ?? '',
            color: _getCategoryColor(announcement['label']),
            onTap: () {
              final announcementId = announcement['id'];

              if (announcementId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailScreen(
                      announcementId: announcementId,
                    ),
                  ),
                );
              }
            },
          );
        }),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Environment':
        return AppTheme.environmentColor;
      case 'Community':
        return AppTheme.communityColor;
      case 'Healthcare':
        return AppTheme.healthcareColor;
      case 'Education':
        return AppTheme.educationColor;
      default:
        return Colors.grey;
    }
  }
}
