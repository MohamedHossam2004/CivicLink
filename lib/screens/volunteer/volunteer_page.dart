import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import './widgets/task_list_card.dart';
import './task_detail_page.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './create_task_page.dart';
import '../announcement/create_announcement_page.dart';

class FilterBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onTap;

  const FilterBar({
    Key? key,
    required this.filters,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1A365D)
                      : const Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1A365D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class VolunteerPage extends StatefulWidget {
  final String? initialTaskId;
  final String userId;

  const VolunteerPage({
    Key? key,
    this.initialTaskId,
    required this.userId,
  }) : super(key: key);

  @override
  _VolunteerPageState createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  List<Task> _allTasks = [];
  List<Task> _myTasks = [];
  List<Task> _completedTasks = [];
  List<Task> _cancelledTasks = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final snapshot = await _firestore
          .collection('tasks')
          .orderBy('createdOn', descending: true)
          .get();

      final now = DateTime.now();
      final tasks = snapshot.docs
          .map((doc) {
            try {
              final task = Task.fromFirestore(doc);
              // Only include tasks that haven't ended
              if (task.endTime.isAfter(now)) {
                return task;
              }
              return null;
            } catch (e) {
              print('Error parsing task ${doc.id}: $e');
              return null;
            }
          })
          .where((task) => task != null)
          .cast<Task>()
          .toList();

      // Filter tasks by status
      _allTasks =
          tasks.where((task) => task.status == TaskStatus.Open).toList();
      _myTasks = tasks
          .where((task) => task.volunteeredUsers.contains(widget.userId))
          .toList();
      _completedTasks =
          tasks.where((task) => task.status == TaskStatus.Completed).toList();
      _cancelledTasks =
          tasks.where((task) => task.status == TaskStatus.Cancelled).toList();

      setState(() {
        _isLoading = false;
      });

      // If initialTaskId is provided, scroll to that task
      if (widget.initialTaskId != null) {
        final taskIndex =
            _allTasks.indexWhere((task) => task.id == widget.initialTaskId);
        if (taskIndex != -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              taskIndex * 200.0, // Approximate height of each task card
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          });
        }
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    var filteredTasks = tasks;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks
          .where((task) =>
              task.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              task.description
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filteredTasks;
  }

  List<Task> _getAvailableTasks() {
    return _getFilteredTasks(_allTasks
        .where((task) =>
            task.status != TaskStatus.Completed &&
            task.status != TaskStatus.Cancelled &&
            !task.volunteeredUsers.contains(widget.userId) &&
            task.currVolunteers < task.maxVolunteers)
        .toList());
  }

  List<Task> _getMyVolunteeredTasks() {
    return _getFilteredTasks(_allTasks
        .where((task) =>
            task.status != TaskStatus.Completed &&
            task.status != TaskStatus.Cancelled &&
            task.volunteeredUsers.contains(widget.userId))
        .toList());
  }

  List<Task> _getCompletedTasks() {
    return _getFilteredTasks(_allTasks
        .where((task) =>
            task.status == TaskStatus.Completed &&
            task.volunteeredUsers.contains(widget.userId))
        .toList());
  }

  Future<void> _refreshTasks() async {
    await _fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF2F7),
      floatingActionButton: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.hasError) {
            return const SizedBox();
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final isAdmin = userData['type'] == 'Admin';

          if (!isAdmin) return const SizedBox();

          return FloatingActionButton(
            backgroundColor: const Color(0xFF1E3A8A),
            child: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1A365D),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.task, color: Colors.white),
                          title: const Text('Create Task',
                              style: TextStyle(color: Colors.white)),
                          onTap: () async {
                            Navigator.pop(context);
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CreateTaskPage(userId: widget.userId),
                              ),
                            );
                            if (created == true) _refreshTasks();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $_error',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A365D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _fetchTasks,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A365D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshTasks,
              color: const Color(0xFF1E3A8A),
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
                    // Header Section
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Volunteer Opportunities',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join our community and make a difference',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Search Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search tasks...',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tabs
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicator: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          dividerColor: Colors.transparent,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Available',
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 8),
                                  Text('My Tasks'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.done_all, size: 18),
                                  SizedBox(width: 8),
                                  Text('Completed'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tab Content
                    Expanded(
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading tasks...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildTaskList(
                                    _getAvailableTasks(), 'Available'),
                                _buildTaskList(
                                    _getMyVolunteeredTasks(), 'My Tasks'),
                                _buildTaskList(
                                    _getCompletedTasks(), 'Completed'),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String title) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A365D).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF2F7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 48,
                color: const Color(0xFF1A365D).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $title Tasks',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A365D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are currently no $title tasks available.\nCheck back later for new opportunities!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF1A365D).withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                _refreshTasks();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tasks.length} tasks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) => TaskListCard(
              task: task,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskDetailPage(
                      task: task,
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}
