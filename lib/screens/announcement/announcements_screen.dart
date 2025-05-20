import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import 'announcement_detail_screen.dart';
import '../../utils/date_formatter.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  final AnnouncementService _service = AnnouncementService();
  late TabController _tabController;
  String _currentFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  Stream<List<Announcement>>? _announcementsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _announcementsStream = _service.getAllAnnouncements();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = 'All';
            _announcementsStream = _service.getAllAnnouncements();
            break;
          case 1:
            _currentFilter = 'Important';
            _announcementsStream = _service.getImportantAnnouncements();
            break;
          case 2:
            _currentFilter = 'Saved';
            // TODO: Implement saved announcements
            _announcementsStream = Stream.value([]);
            break;
        }
      });
    }
  }

  void _onDepartmentSelected(String department) {
    setState(() {
      _currentFilter = department;
      _announcementsStream = _service.filterByDepartment(department);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  if (value.isEmpty) {
                    // Reset to current filter if search is empty
                    switch (_currentFilter) {
                      case 'All':
                        _announcementsStream = _service.getAllAnnouncements();
                        break;
                      case 'Important':
                        _announcementsStream =
                            _service.getImportantAnnouncements();
                        break;
                      default:
                        if (_currentFilter == 'Saved') {
                          // TODO: Implement saved announcements
                          _announcementsStream = Stream.value([]);
                        } else {
                          _announcementsStream =
                              _service.filterByDepartment(_currentFilter);
                        }
                    }
                  } else {
                    // Apply search filter
                    _announcementsStream = _service.searchAnnouncements(value);
                  }
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Important'),
                Tab(text: 'Saved'),
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
          const SizedBox(height: 8),
          _buildDepartmentChips(),
          Expanded(
            child: StreamBuilder<List<Announcement>>(
              stream: _announcementsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final announcements = snapshot.data ?? [];

                if (announcements.isEmpty) {
                  return const Center(child: Text('No announcements found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount:
                      announcements.length + 1, // +1 for featured announcement
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Show featured announcement at the top
                      final featuredAnnouncement = announcements.firstWhere(
                        (a) => a.isImportant,
                        orElse: () => announcements.first,
                      );
                      return _buildFeaturedAnnouncement(featuredAnnouncement);
                    }
                    // Show regular announcements
                    final announcement = announcements[index - 1];
                    return _buildAnnouncementCard(announcement);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Documents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChips() {
    final departments = [
      'Environmental Services',
      'Water and Sewage',
      'Transportation',
      'Parks and Recreation',
      'Public Health'
    ];

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('All'),
              selected: _currentFilter == 'All',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilter = 'All';
                    _announcementsStream = _service.getAllAnnouncements();
                  });
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: _currentFilter == 'All' ? Colors.blue : Colors.black,
              ),
            ),
          ),
          ...departments
              .map((department) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(department),
                      selected: _currentFilter == department,
                      onSelected: (selected) {
                        if (selected) _onDepartmentSelected(department);
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.blue.withOpacity(0.2),
                      checkmarkColor: Colors.blue,
                      labelStyle: TextStyle(
                        color: _currentFilter == department
                            ? Colors.blue
                            : Colors.black,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final Color categoryColor = _getCategoryColor(announcement.label);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnnouncementDetailScreen(
                announcementId: announcement.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          announcement.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          announcement.label,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    announcement.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Posted on ${DateFormatter.format(announcement.createdOn)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if (announcement.isImportant) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'Important',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Colored bar on the left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedAnnouncement(Announcement announcement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
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
              'Featured Announcement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            announcement.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement.description,
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
              const SizedBox(width: 4),
              Text(
                'Posted on ${DateFormatter.format(announcement.createdOn)}',
                style: const TextStyle(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  announcement.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementDetailScreen(
                        announcementId: announcement.id,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                child: const Text('Read More'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    // Generate a random color based on the category string
    // This ensures the same category always gets the same color
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.deepPurple,
    ];

    // Use the category string to generate a consistent index
    final index = category.toLowerCase().hashCode.abs() % colors.length;
    return colors[index];
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Announcements'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                leading: Radio<String>(
                  value: 'All',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    Navigator.pop(context);
                    setState(() {
                      _currentFilter = 'All';
                      _announcementsStream = _service.getAllAnnouncements();
                    });
                  },
                ),
              ),
              ListTile(
                title: const Text('Environmental Services'),
                leading: Radio<String>(
                  value: 'Environmental Services',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _onDepartmentSelected(value!);
                  },
                ),
              ),
              ListTile(
                title: const Text('Water and Sewage'),
                leading: Radio<String>(
                  value: 'Water and Sewage',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _onDepartmentSelected(value!);
                  },
                ),
              ),
              ListTile(
                title: const Text('Transportation'),
                leading: Radio<String>(
                  value: 'Transportation',
                  groupValue: _currentFilter,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _onDepartmentSelected(value!);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
