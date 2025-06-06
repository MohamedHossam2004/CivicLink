// lib/screens/profile/profile_page.dart
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gov_app/services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Firestore-driven state
  int _totalTasks = 0;
  int _totalReports = 0;
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _error;
  String? _fullName;
  DateTime? _createdAt;
  bool _sendingTestNotification = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendTestNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No authenticated user')),
      );
      return;
    }

    setState(() {
      _sendingTestNotification = true;
    });

    try {
      // Initialize notification service
      await _notificationService.initialize(context);
      
      // Send test notification
      await _notificationService.sendTestNotification(user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test notification sent. Check console for details.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending notification: $e')),
      );
    } finally {
      setState(() {
        _sendingTestNotification = false;
      });
    }
  }

  Future<void> _fetchData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final uid = user.uid;

      // Fetch user's full name
      final userDoc = await _firestore.collection('users').doc(uid).get();
      _fullName = userDoc.data()?['fullName'] ?? 'Unknown User';
      final createdAtField = userDoc.data()?['createdAt'];
      _createdAt = createdAtField is Timestamp ? createdAtField.toDate() : null;

      // Fetch tasks volunteered by user
      final taskSnap = await _firestore
          .collection('tasks')
          .where('volunteeredUsers', arrayContains: uid)
          .orderBy('createdOn')
          .limit(3)
          .get();

      // Fetch reports created by user
      final reportSnap = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(2)
          .get();

      // Count tasks and reports for user
      final taskCountSnap = await _firestore
          .collection('tasks')
          .where('volunteeredUsers', arrayContains: uid)
          .count()
          .get();

      final reportCountSnap = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: uid)
          .count()
          .get();

      setState(() {
        _tasks = taskSnap.docs.map((d) => d.data()).toList();
        _reports = reportSnap.docs.map((d) => d.data()).toList();
        _totalTasks = taskCountSnap.count ?? 0;
        _totalReports = reportCountSnap.count ?? 0;
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
    return Scaffold(
      // —— AppBar ——
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: const Text('Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.grey),
              onPressed: () {}),
        ],
      ),
      // —— Body ——
      body: Column(
        children: [
          // 1) Gradient header with avatar & name
          Container(
            width: double.infinity,
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7E57C2), Color(0xFF5E35B1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                ),
                const SizedBox(height: 8),
                Text(_fullName ?? 'Loading...',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  _createdAt != null
                      ? 'Joined ${DateFormat.yMMMM().format(_createdAt!)}'
                      : 'Join date unavailable',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _sendingTestNotification ? null : _sendTestNotification,
                  icon: _sendingTestNotification ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ) : const Icon(Icons.notifications),
                  label: Text(_sendingTestNotification ? 'Sending...' : 'Test Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5E35B1),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2) Re-added stat cards: Total Tasks & Total Reports
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      count: _totalTasks.toString(),
                      label: 'Total Tasks',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      count: _totalReports.toString(),
                      label: 'Total Reports',
                    ),
                  ),
                ],
              ),
            ),

          // Show loading or error instead of cards if needed
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Error: $_error')),
            ),

          const SizedBox(height: 16),

          // 3) Pill-style TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                indicatorPadding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                labelColor: const Color(0xFF7E57C2),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Activity'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 4) Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview (with dynamic lists)
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_error != null)
                  Center(child: Text('Error: $_error'))
                else
                  _OverviewTab(tasks: _tasks, reports: _reports),

                const _ActivityTab(),
                const _SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stateless widget for a single stat card
class _StatCard extends StatelessWidget {
  final String count;
  final String label;

  const _StatCard({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ]),
      ),
    );
  }
}

/// The Overview tab, now with Upcoming Tasks & Recent Reports
class _OverviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> reports;

  const _OverviewTab({
    required this.tasks,
    required this.reports,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMMd();
    final timeFmt = DateFormat.jm();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Tasks header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('View All',
                    style: TextStyle(color: Color(0xFF7E57C2))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: tasks.map((t) {
                // Firestore Timestamp → DateTime
                final ts = (t['createdAt'] ?? t['createdOn']);
                final createdDate =
                    (ts is Timestamp ? ts.toDate() : DateTime.now());

                final DateFormat dateFmt =
                    DateFormat.yMMMd(); // e.g. May 18, 2025
                final DateFormat timeFmt = DateFormat.jm(); // e.g. 11:07 AM
                return Column(
                  children: [
                    _UpcomingTaskItem(
                      title: t['title']?.toString() ?? 'Untitled Task',
                      date: dateFmt.format(createdDate!),
                      time: timeFmt.format(createdDate!),
                      joined: true, // or use your logic
                      iconColor: Colors.green,
                    ),
                    if (tasks.last != t) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Reports header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Reports',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('View All',
                    style: TextStyle(color: Color(0xFF7E57C2))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: reports.map((r) {
                final ts = (r['createdAt'] as Timestamp).toDate();
                // choose colors by status
                final status = r['status'] as String;
                Color statusColor;
                if (status == 'Resolved') {
                  statusColor = Colors.green;
                } else if (status == 'In Progress') {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.grey;
                }
                return Column(
                  children: [
                    _RecentReportItem(
                      title: r['description'] as String,
                      date: dateFmt.format(ts),
                      status: status,
                      statusBg: statusColor.withOpacity(0.2),
                      statusColor: statusColor,
                      iconColor: Colors.blue,
                    ),
                    if (reports.last != r) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row inside Upcoming Tasks
class _UpcomingTaskItem extends StatelessWidget {
  final String title, date, time;
  final bool joined;
  final Color iconColor;

  const _UpcomingTaskItem({
    required this.title,
    required this.date,
    required this.time,
    required this.joined,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(Icons.check_circle, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(date, style: const TextStyle(color: Colors.grey)),
        const SizedBox(width: 16),
        // const Icon(Icons.access_time, size: 16, color: Colors.grey),
        // const SizedBox(width: 4),
        // Text(time, style: const TextStyle(color: Colors.grey)),
      ]),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          joined ? 'Joined' : 'Join',
          style: const TextStyle(
              color: Color(0xFF7E57C2), fontWeight: FontWeight.bold),
        ),
      ),
      onTap: () {
        // TODO: navigate or toggle join
      },
    );
  }
}

/// Single row inside Recent Reports
class _RecentReportItem extends StatelessWidget {
  final String title, date, status;
  final Color statusBg, statusColor, iconColor;

  const _RecentReportItem({
    required this.title,
    required this.date,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(Icons.location_on, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Row(children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(date, style: const TextStyle(color: Colors.grey)),
      ]),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(status,
                style:
                    TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: () {
        // TODO: navigate to report detail
      },
    );
  }
}

// Add these imports at the top of your file
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  // Firestore & Auth instances
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Controllers for each editable field
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _addressController = TextEditingController();
  bool _pushNotifications = false;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _nationalIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      // Map Firestore fields into our controllers
      _fullNameController.text = data['fullName'] ?? '';
      _emailController.text = data['email'] ?? '';
      _nationalIdController.text = data['nationalId'] ?? '';
      _addressController.text = data['address'] ?? '';
      _pushNotifications = data['pushNotifications'] ?? false;

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePushNotifications(bool newValue) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({
      'pushNotifications': newValue,
    });
    setState(() {
      _pushNotifications = newValue;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context)
          .pushReplacementNamed('/login'); // change route if needed
    }
  }

  Future<void> _updateField(String fieldKey, TextEditingController ctrl) async {
    final newValue = ctrl.text.trim();
    if (newValue.isEmpty) return;

    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({fieldKey: newValue});
    // Controller is already updated, UI will reflect change immediately
  }

  Future<void> _showEditDialog(
    String fieldKey,
    TextEditingController controller,
    String label,
  ) async {
    final editCtrl = TextEditingController(text: controller.text);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: editCtrl,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              controller.text = editCtrl.text;
              await _updateField(fieldKey, controller);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    TextEditingController ctrl,
    String firestoreKey,
  ) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(label),
      subtitle: Text(ctrl.text),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Color(0xFF7E57C2)),
        onPressed: () => _showEditDialog(firestoreKey, ctrl, label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Personal Information
        const Text(
          'Personal Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildInfoTile('Full Name', _fullNameController, 'fullName'),
              const Divider(height: 1),
              _buildInfoTile('Email Address', _emailController, 'email'),
              const Divider(height: 1),
              _buildInfoTile(
                  'National ID', _nationalIdController, 'nationalId'),
              const Divider(height: 1),
              _buildInfoTile('Address', _addressController, 'address'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Notification Settings',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive alerts on your device'),
                value: _pushNotifications,
                onChanged: _togglePushNotifications,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates via email'),
                value: false,
                onChanged: null, // Implement later
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('SMS Notifications'),
                subtitle:
                    const Text('Receive text messages for urgent updates'),
                value: false,
                onChanged: null, // Implement later
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
// Account Section
        const Text(
          'Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                onTap: () {
                  // TODO: Navigate to change password screen
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Settings'),
                onTap: () {
                  // TODO: Navigate to privacy settings
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: _signOut,
        ),
        // Keep your Notification Settings & Account sections here...
      ]),
    );
  }
}

/// Activity Tab & Timeline Widgets
/// ----------------------------------

/// ----------------------------
/// Activity Tab (no line/dots)
/// ----------------------------
Future<List<Map<String, dynamic>>> _fetchActivityItems() async {
  final firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final List<Map<String, dynamic>> activity = [];

  if (userId == null) return activity;

  // Fetch from each collection
  final tasksSnap = await firestore.collection('tasks').get();
  final reportsSnap = await firestore.collection('reports').get();
  final announcementsSnap = await firestore.collection('announcements').get();
  final pollsSnap = await firestore.collection('polls').get();

  // Append tasks — only if user is in volunteeredUsers[]
  for (var doc in tasksSnap.docs) {
    final data = doc.data();
    final volunteered = List<String>.from(data['volunteeredUsers'] ?? []);
    if (!volunteered.contains(userId)) continue;

    final ts = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
    activity.add({
      'type': 'Task',
      'title': data['title'] ?? 'Unnamed Task',
      'description': data['description'] ?? '',
      'timestamp': ts,
      'color': const Color(0xFF7E57C2),
      'bg': const Color(0xFFEDE7F6),
    });
  }

  // Append reports — only if userId matches
  for (var doc in reportsSnap.docs) {
    final data = doc.data();
    if (data['userId'] != userId) continue;

    final ts = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
    activity.add({
      'type': 'Report',
      'title': data['issueType'] ?? 'Report',
      'description': data['description'] ?? '',
      'timestamp': ts,
      'color': const Color(0xFFD32F2F),
      'bg': const Color(0xFFFFEBEE),
    });
  }

  // Append announcements (shown to everyone)
  for (var doc in announcementsSnap.docs) {
    final data = doc.data();
    final ts = (data['createdOn'] as Timestamp?)?.toDate() ?? DateTime(1970);
    activity.add({
      'type': 'Announcement',
      'title': data['label'] ?? data['name'] ?? 'Announcement',
      'description': data['description'] ?? '',
      'timestamp': ts,
      'color': const Color(0xFF1976D2),
      'bg': const Color(0xFFE3F2FD),
    });
  }

  activity.sort((a, b) {
    final aTime = a['timestamp'] ?? DateTime(1970);
    final bTime = b['timestamp'] ?? DateTime(1970);
    return bTime.compareTo(aTime); // newest first
  });

  return activity;
}

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  late Future<List<Map<String, dynamic>>> _futureActivity;

  @override
  void initState() {
    super.initState();
    _futureActivity = _fetchActivityItems();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureActivity,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final items = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ActivityItem(
              type: item['type'],
              timestamp: DateFormat.yMMMMd().add_jm().format(item['timestamp']),
              title: item['title'],
              description: item['description'],
              typeBgColor: item['bg'],
              typeColor: item['color'],
            );
          },
        );
      },
    );
  }
}

/// A single activity row: badge + timestamp, then a white card.
class _ActivityItem extends StatelessWidget {
  final String type;
  final String timestamp;
  final String title;
  final String description;
  final Color typeBgColor;
  final Color typeColor;

  const _ActivityItem({
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    required this.typeBgColor,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge + timestamp row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: typeBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timestamp,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Content card
        Card(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final double gutterWidth;
  final double gutterPadding;
  final Color dotColor;
  final String typeLabel;
  final Color typeBg;
  final Color typeColor;
  final String timestamp;
  final String title;
  final String description;
  final bool isLast;

  const _TimelineEvent({
    required this.gutterWidth,
    required this.gutterPadding,
    required this.dotColor,
    required this.typeLabel,
    required this.typeBg,
    required this.typeColor,
    required this.timestamp,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    // height of the connector line to the next event:
    const double lineHeight = 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // — Label + Timestamp Row —
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // left gutter with dot and (optional) line
            SizedBox(
              width: gutterWidth,
              child: Column(
                children: [
                  // dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  // line
                  if (!isLast)
                    Container(
                      width: 2,
                      height: lineHeight,
                      color: dotColor.withOpacity(0.3),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // type pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(width: 8),

            // timestamp
            Text(
              timestamp,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // — Detail Card —
        Padding(
          padding: EdgeInsets.only(
            left: gutterWidth + gutterPadding,
            right: 0,
          ),
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}
