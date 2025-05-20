import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import './widgets/task_list_card.dart';
import './task_detail_page.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFFF4F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Volunteer Tasks'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: $_error'),
                  ElevatedButton(
                    onPressed: _fetchTasks,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshTasks,
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                    tabs: const [
                      Tab(text: 'Available'),
                      Tab(text: 'My Tasks'),
                      Tab(text: 'Completed'),
                    ],
                  ),

                  // Tab Content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildTaskList(_getAvailableTasks(), 'Available'),
                              _buildTaskList(
                                  _getMyVolunteeredTasks(), 'My Tasks'),
                              _buildTaskList(_getCompletedTasks(), 'Completed'),
                            ],
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String title) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 16),
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
              'No $title Tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no $title tasks available. Check back later for new opportunities!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
      ],
    );
  }
}
