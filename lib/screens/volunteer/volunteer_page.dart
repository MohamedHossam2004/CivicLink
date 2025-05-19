import 'package:flutter/material.dart';
import '../../models/task.dart';
import './widgets/task_list_card.dart';
import './task_detail_page.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerPage extends StatefulWidget {
  final String userId;

  const VolunteerPage({Key? key, required this.userId}) : super(key: key);

  @override
  _VolunteerPageState createState() => _VolunteerPageState();
}

class _VolunteerPageState extends State<VolunteerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskDepartment? _selectedDepartment;
  List<Task> _allTasks = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    var filteredTasks = tasks;
    
    // Apply department filter
    if (_selectedDepartment != null) {
      filteredTasks = filteredTasks.where((task) => task.department == _selectedDepartment).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) =>
        task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        task.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filteredTasks;
  }

  List<Task> _getAvailableTasks() {
    return _getFilteredTasks(_allTasks.where((task) => 
      !task.completed && 
      !task.volunteeredUsers.contains(widget.userId) &&
      task.participants < task.maxParticipants
    ).toList());
  }

  List<Task> _getMyVolunteeredTasks() {
    print('User ID: ${widget.userId}');
    return _getFilteredTasks(_allTasks.where((task) => 
      !task.completed && 
      task.volunteeredUsers.contains(widget.userId)
    ).toList());
  }

  List<Task> _getCompletedTasks() {
    return _getFilteredTasks(_allTasks.where((task) => 
      task.completed && 
      task.volunteeredUsers.contains(widget.userId)
    ).toList());
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
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                
                // Department Filter
                _buildDepartmentFilter(),
                
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
                          _buildTasksList(_getAvailableTasks()),
                          _buildTasksList(_getMyVolunteeredTasks()),
                          _buildTasksList(_getCompletedTasks()),
                        ],
                      ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TaskListCard(
            task: tasks[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailPage(
                    task: tasks[index],
                    userId: widget.userId,
                  ),
                ),
              ).then((_) => _fetchTasks()); // Refresh tasks after returning from detail page
            },
          ),
        );
      },
    );
  }

  Widget _buildDepartmentFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Tasks'),
            selected: _selectedDepartment == null,
            onSelected: (bool selected) {
              setState(() {
                _selectedDepartment = null;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: Colors.deepPurple[100],
            checkmarkColor: Colors.deepPurple,
            labelStyle: TextStyle(
              color: _selectedDepartment == null ? Colors.deepPurple : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          ...TaskDepartment.values.map((department) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(department.toString().split('.').last),
                selected: _selectedDepartment == department,
                onSelected: (bool selected) {
                  setState(() {
                    _selectedDepartment = selected ? department : null;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.deepPurple[100],
                checkmarkColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: _selectedDepartment == department ? Colors.deepPurple : Colors.black,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
} 