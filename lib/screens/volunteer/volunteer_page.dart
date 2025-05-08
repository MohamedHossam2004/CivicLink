import 'package:flutter/material.dart';

class VolunteerPage extends StatefulWidget {
  const VolunteerPage({Key? key}) : super(key: key);

  @override
  _VolunteerPageState createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = "All Tasks";
  
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
    backgroundColor: const Color(0xFFF8FAFC), // slate-50
    appBar: AppBar(
      title: const Text('Volunteer Tasks'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            // Filter action
          },
        ),
      ],
    ),
    body: Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAvailableTasks(),
                    _buildMyTasks(),
                    _buildCompletedTasks(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildCategoryFilter() {
    final categories = [
      "All Tasks",
      "Environment",
      "Community",
      "Education",
      "Healthcare",
    ];
    
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0), // slate-200
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9), // violet-600 : slate-100
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B), // white : slate-800
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // slate-100
          borderRadius: BorderRadius.circular(9999),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          labelColor: const Color(0xFF8B5CF6), // violet-700
          unselectedLabelColor: const Color(0xFF64748B), // slate-500
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Tasks'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAvailableTasks() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildTaskCard(
          id: "1",
          title: "Park Cleanup",
          description: "Help clean up Central Park by collecting trash and maintaining the green spaces.",
          location: "Central Park",
          date: "May 15, 2025",
          time: "9:00 AM - 12:00 PM",
          participants: 12,
          maxParticipants: 20,
          category: "Environment",
          color: const Color(0xFF22C55E), // green-500
        ),
        _buildTaskCard(
          id: "2",
          title: "Food Drive",
          description: "Collect and distribute food donations to local shelters and families in need.",
          location: "Community Center",
          date: "May 18, 2025",
          time: "10:00 AM - 2:00 PM",
          participants: 8,
          maxParticipants: 15,
          category: "Community",
          color: const Color(0xFFF59E0B), // amber-500
        ),
        _buildTaskCard(
          id: "3",
          title: "Senior Assistance",
          description: "Help elderly residents with grocery shopping, home maintenance, and companionship.",
          location: "Riverside Homes",
          date: "May 22, 2025",
          time: "2:00 PM - 5:00 PM",
          participants: 5,
          maxParticipants: 10,
          category: "Healthcare",
          color: const Color(0xFF3B82F6), // blue-500
        ),
        _buildTaskCard(
          id: "4",
          title: "Tree Planting",
          description: "Plant new trees along Riverside Park to improve air quality and beautify the area.",
          location: "Riverside Park",
          date: "May 25, 2025",
          time: "8:00 AM - 1:00 PM",
          participants: 15,
          maxParticipants: 25,
          category: "Environment",
          color: const Color(0xFF22C55E), // green-500
        ),
        _buildTaskCard(
          id: "5",
          title: "Youth Mentoring",
          description: "Mentor young students in academic subjects and provide guidance for their future.",
          location: "Public Library",
          date: "Every Saturday",
          time: "2:00 PM - 4:00 PM",
          participants: 12,
          maxParticipants: 20,
          category: "Education",
          color: const Color(0xFF6366F1), // indigo-500
        ),
      ],
    );
  }
  
  Widget _buildMyTasks() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildTaskCard(
          id: "6",
          title: "Community Garden",
          description: "Maintain the community garden by watering plants, weeding, and harvesting vegetables.",
          location: "Downtown Garden",
          date: "May 22, 2025",
          time: "9:00 AM - 11:00 AM",
          participants: 7,
          maxParticipants: 10,
          category: "Environment",
          color: const Color(0xFF22C55E), // green-500
          joined: true,
        ),
        _buildTaskCard(
          id: "7",
          title: "Recycling Drive",
          description: "Collect recyclable materials from residents and educate them about proper recycling practices.",
          location: "City Hall",
          date: "May 30, 2025",
          time: "1:00 PM - 5:00 PM",
          participants: 20,
          maxParticipants: 25,
          category: "Environment",
          color: const Color(0xFF22C55E), // green-500
          joined: true,
        ),
      ],
    );
  }
  
  Widget _buildCompletedTasks() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildTaskCard(
          id: "8",
          title: "Beach Cleanup",
          description: "Cleaned up the local beach by removing trash and plastic waste.",
          location: "Sunset Beach",
          date: "April 25, 2025",
          time: "8:00 AM - 12:00 PM",
          participants: 30,
          maxParticipants: 30,
          category: "Environment",
          color: const Color(0xFF94A3B8), // slate-400
          completed: true,
        ),
        _buildTaskCard(
          id: "9",
          title: "Vaccination Drive",
          description: "Assisted healthcare workers in organizing and managing a community vaccination event.",
          location: "Health Center",
          date: "April 15, 2025",
          time: "9:00 AM - 4:00 PM",
          participants: 15,
          maxParticipants: 15,
          category: "Healthcare",
          color: const Color(0xFF94A3B8), // slate-400
          completed: true,
        ),
      ],
    );
  }
  
  Widget _buildTaskCard({
  required String id,
  required String title,
  required String description,
  required String location,
  required String date,
  required String time,
  required int participants,
  required int maxParticipants,
  required String category,
  required Color color,
  bool joined = false,
  bool completed = false,
}) {
  final progress = (participants / maxParticipants) * 100;
  
  return GestureDetector(
    onTap: () {
      // Navigate to task detail
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildCategoryBadge(category),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // This is likely the problematic container - make sure it has proper constraints
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: participants / maxParticipants,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$participants/$maxParticipants',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                if (!joined && !completed)
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Join'),
                  )
                else if (joined && !completed)
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Leave'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Widget _buildCategoryBadge(String category) {
    Color bgColor;
    Color textColor;
    
    switch (category) {
      case 'Environment':
        bgColor = const Color(0xFFDCFCE7); // green-100
        textColor = const Color(0xFF166534); // green-800
        break;
      case 'Community':
        bgColor = const Color(0xFFFEF3C7); // amber-100
        textColor = const Color(0xFF92400E); // amber-800
        break;
      case 'Education':
        bgColor = const Color(0xFFE0E7FF); // indigo-100
        textColor = const Color(0xFF3730A3); // indigo-800
        break;
      case 'Healthcare':
        bgColor = const Color(0xFFDBEAFE); // blue-100
        textColor = const Color(0xFF1E40AF); // blue-800
        break;
      default:
        bgColor = const Color(0xFFF1F5F9); // slate-100
        textColor = const Color(0xFF1E293B); // slate-800
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0), // slate-200
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
            isSelected: false,
            onTap: () {
              // Navigate to home
            },
          ),
          _buildNavItem(
            icon: Icons.check_circle,
            label: 'Tasks',
            isSelected: true,
            onTap: () {
              // Already on tasks
            },
          ),
          _buildNavItem(
            icon: Icons.chat,
            label: 'Chat',
            isSelected: false,
            onTap: () {
              // Navigate to chat
            },
          ),
          _buildNavItem(
            icon: Icons.calendar_today,
            label: 'Calendar',
            isSelected: false,
            onTap: () {
              // Navigate to calendar
            },
          ),
          _buildNavItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: false,
            onTap: () {
              // Navigate to profile
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEDE9FE) : const Color(0xFFF1F5F9), // violet-100 : slate-100
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B), // violet-600 : slate-500
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF64748B), // violet-600 : slate-500
              ),
            ),
          ],
        ),
      ),
    );
  }
}