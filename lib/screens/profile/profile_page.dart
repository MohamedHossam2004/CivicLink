// lib/screens/profile/profile_page.dart
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Hard-coded for now – swap with your Firebase calls later
  final int tasksCompleted = 12;
  final int reportsFiled = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            onPressed: () {},
          )
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
                const Text('John Doe',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Joined January 2025',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2) Three stat cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                      count: tasksCompleted.toString(),
                      label: 'Tasks Completed'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                      count: reportsFiled.toString(), label: 'Reports Filed'),
                ),
                const SizedBox(width: 8),
              ],
            ),
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
                  borderRadius: BorderRadius.circular(50),
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
              children: const [
                _OverviewTab(),
                _ActivityTab(),
                _SettingsTab(),
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
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // — Upcoming Tasks header —
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Upcoming Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {}, // TODO: View all tasks
              child: const Text('View All',
                  style: TextStyle(color: Color(0xFF7E57C2))),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // — Upcoming Tasks card —
        Card(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: const [
              _UpcomingTaskItem(
                title: 'Community Garden',
                date: 'May 22, 2025',
                time: '9:00 AM',
                joined: true,
                iconColor: Colors.green,
              ),
              Divider(height: 1),
              _UpcomingTaskItem(
                title: 'Food Drive',
                date: 'May 30, 2025',
                time: '1:00 PM',
                joined: true,
                iconColor: Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // — Recent Reports header —
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {}, // TODO: View all reports
              child: const Text('View All',
                  style: TextStyle(color: Color(0xFF7E57C2))),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // — Recent Reports card —
        Card(
          color: Colors.white,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: const [
              _RecentReportItem(
                title: 'Street Light Not Working',
                date: 'April 28, 2025',
                status: 'In Progress',
                statusBg: Color(0xFFFFF3E0), // light amber
                statusColor: Color(0xFFFFA000),
                iconColor: Color(0xFF90CAF9),
              ),
              Divider(height: 1),
              _RecentReportItem(
                title: 'Water Leak',
                date: 'April 15, 2025',
                status: 'Resolved',
                statusBg: Color(0xFFE8F5E9), // light green
                statusColor: Color(0xFF43A047),
                iconColor: Color(0xFFEF9A9A),
              ),
            ],
          ),
        ),
      ]),
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
        const Icon(Icons.access_time, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(time, style: const TextStyle(color: Colors.grey)),
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

class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  // toggles
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                _buildInfoTile('Full Name', 'John Doe'),
                const Divider(height: 1),
                _buildInfoTile('Email Address', 'john.doe@example.com'),
                const Divider(height: 1),
                _buildInfoTile('Phone Number', '+1 (555) 123-4567'),
                const Divider(height: 1),
                _buildInfoTile('Address', '123 Main St, Anytown, ST 12345'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification Settings
          const Text(
            'Notification Settings',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive alerts on your device'),
                  value: _pushEnabled,
                  onChanged: (v) => setState(() => _pushEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  subtitle: const Text('Receive updates via email'),
                  value: _emailEnabled,
                  onChanged: (v) => setState(() => _emailEnabled = v),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  subtitle:
                      const Text('Receive text messages for urgent updates'),
                  value: _smsEnabled,
                  onChanged: (v) => setState(() => _smsEnabled = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Actions
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
                  tileColor: Colors.white,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: navigate to change password
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: navigate to privacy settings
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: sign out logic
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for each info row with an edit icon.
  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      // tileColor: Colors.white,
      tileColor: Colors.white,
      title: Text(label),
      subtitle: Text(value),
      trailing: IconButton(
        icon: const Icon(Icons.edit, color: Color(0xFF7E57C2)),
        onPressed: () {
          // TODO: open edit dialog
        },
      ),
    );
  }
}

/// ----------------------------------
/// Activity Tab & Timeline Widgets
/// ----------------------------------

/// ----------------------------
/// Activity Tab (no line/dots)
/// ----------------------------
class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _ActivityItem(
            type: 'Task Joined',
            timestamp: 'Today, 10:30 AM',
            title: 'Community Garden',
            description:
                'You joined as a volunteer for the Community Garden project on May 22.',
            typeBgColor: const Color(0xFFEDE7F6),
            typeColor: const Color(0xFF7E57C2),
          ),
          const SizedBox(height: 16),
          _ActivityItem(
            type: 'Comment',
            timestamp: 'Yesterday, 3:45 PM',
            title: 'Water Maintenance Announcement',
            description:
                'You commented on the Water Maintenance announcement: “Will there be any compensation for businesses that need to close during this period?”',
            typeBgColor: const Color(0xFFE3F2FD),
            typeColor: const Color(0xFF1976D2),
          ),
          const SizedBox(height: 16),
          _ActivityItem(
            type: 'Report Filed',
            timestamp: 'April 28, 2025, 2:15 PM',
            title: 'Street Light Not Working',
            description:
                'You reported a broken street light at 123 Main Street. Status: In Progress.',
            typeBgColor: const Color(0xFFFFEBEE),
            typeColor: const Color(0xFFD32F2F),
          ),
        ],
      ),
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
