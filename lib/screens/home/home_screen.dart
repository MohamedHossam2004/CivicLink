import 'package:flutter/material.dart';
import 'package:gov_app/config/theme.dart';
import 'package:gov_app/screens/home/widgets/announcement_card.dart';
import 'package:gov_app/screens/home/widgets/task_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gov_app/screens/report_issue/report_issue_step1.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .orderBy('createdOn', descending: true)
          .limit(2)
          .get();
      final announcements =
          announcementsSnapshot.docs.map((doc) => doc.data()).toList();

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .orderBy('createdOn')
          .limit(3)
          .get();
      final tasks = tasksSnapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _announcements = announcements;
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
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
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'John Doe',
                    style: TextStyle(
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildServiceItem(
              icon: Icons.check_circle_outline,
              label: 'Volunteer',
              color: AppTheme.primaryColor,
              bgColor: AppTheme.primaryLightColor,
              onTap: () {
                // Navigate to volunteer screen
              },
            ),
            _buildServiceItem(
              icon: Icons.chat_bubble_outline,
              label: 'AI Chat',
              color: AppTheme.secondaryColor,
              bgColor: AppTheme.secondaryLightColor,
              onTap: () {
                // Navigate to chat screen
              },
            ),
            _buildServiceItem(
              icon: Icons.location_on_outlined,
              label: 'Report',
              color: Colors.red,
              bgColor: Colors.red.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportIssueStep1(),
                  ),
                );
              },
            ),
            _buildServiceItem(
              icon: Icons.notifications_none,
              label: 'Updates',
              color: AppTheme.communityColor,
              bgColor: AppTheme.communityColor.withOpacity(0.1),
              onTap: () {
                // Navigate to announcements screen
              },
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
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTask() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Text(
              'Featured Task',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Community Garden Project',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help create a new community garden in the central district',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'May 20, 2025',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.access_time,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                '9:00 AM - 2:00 PM',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Replace the overlapping avatars with a Stack
                  SizedBox(
                    height: 28,
                    width: 100, // Adjust width as needed
                    child: Stack(
                      children: [
                        for (int i = 0; i < 3; i++)
                          Positioned(
                            left: i *
                                20.0, // Position each avatar with some overlap
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white,
                                child: Text(
                                  'A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 60, // Position the +8 avatar
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLightColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.transparent,
                              child: Text(
                                '+8',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '11 of 20 volunteers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Join Now'),
              ),
            ],
          ),
        ],
      ),
    );
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
                // Navigate to volunteer screen
              },
              child: Row(
                children: const [
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
        ..._tasks.map((task) => TaskCard(
              title: task['name'] ?? '',
              location: task['location'] != null
                  ? '${task['location']['latitude']}, ${task['location']['longitude']}'
                  : '',
              date: task['startTime'] ?? '',
              time: task['endTime'] ?? '',
              category: task['label'] ?? '',
              participants: task['currVolunteers'] ?? 0,
              maxParticipants: task['maxVolunteers'] ?? 0,
              color: _getCategoryColor(task['label']),
            )),
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
                // Navigate to announcements screen
              },
              child: Row(
                children: const [
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
          final timestamp = announcement['startTime'];
          final date = timestamp is Timestamp
              ? timestamp
                  .toDate()
                  .toString() // Convert Timestamp to DateTime, then to String
              : 'Unknown Date';

          return AnnouncementCard(
            title: announcement['name'] ?? '',
            description: announcement['description'] ?? '',
            date: date,
            category: announcement['label'] ?? '',
            color: _getCategoryColor(announcement['label']),
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
