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

    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF1A365D),
              ],
              stops: [0.0, 0.3],
            ),
          ),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _userInitials.isEmpty ? 'U' : _userInitials,
                    style: const TextStyle(
                      color: Color(0xFF1A365D),
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
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _fullName.isEmpty ? 'User' : _fullName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search services, tasks, announcements...',
              hintStyle: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.white70,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(color: Colors.white),
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
            color: Colors.white,
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
                color: Colors.white,
                bgColor: const Color(0xFF1A365D),
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
                color: Colors.white,
                bgColor: const Color(0xFF1A365D),
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
                color: Colors.white,
                bgColor: const Color(0xFF1A365D),
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
                color: Colors.white,
                bgColor: const Color(0xFF1A365D),
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
                color: Colors.white,
                bgColor: const Color(0xFF1A365D),
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
              color: const Color(0xFF1A365D),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTask() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A365D),
            Color(0xFF0A1929),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                          color: Colors.white.withOpacity(0.1),
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
                          color: Colors.white.withOpacity(0.1),
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
                ] else ...[
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.white70,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Featured Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'There are currently no active tasks that need volunteers. Check back later for new opportunities!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
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
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                final mainScreen =
                    context.findAncestorStateOfType<MainScreenState>();
                if (mainScreen != null) {
                  mainScreen.changeIndex(1);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Upcoming Tasks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There are currently no upcoming tasks available.\nCheck back later for new opportunities!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._tasks.map((task) {
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
              color: const Color(0xFF1A365D),
              onTap: () async {
                final doc = await FirebaseFirestore.instance
                    .collection('tasks')
                    .doc(task['id'])
                    .get();
                if (doc.exists) {
                  final taskObj = Task.fromFirestore(doc);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskDetailPage(
                        task: taskObj,
                        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
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
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnnouncementsScreen()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
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
        if (_announcements.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.announcement_outlined,
                    size: 48,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Announcements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'There are currently no announcements available.\nCheck back later for updates!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ..._announcements.map((announcement) {
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
              color: const Color(0xFF1A365D),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailScreen(
                      announcementId: announcement['id'],
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
}
