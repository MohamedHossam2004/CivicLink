import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;
  final String userId;

  const TaskDetailPage({
    Key? key,
    required this.task,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskService _taskService = TaskService();
  bool _isLoading = false;
  bool _isLoadingUserType = true;
  bool hasJoined = false;
  bool _isAdmin = false;
  bool _isAdvertiser = false;

  @override
  void initState() {
    super.initState();
    hasJoined = widget.task.volunteeredUsers.contains(widget.userId);
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    setState(() {
      _isLoadingUserType = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (mounted) {
        setState(() {
          _isAdmin = userDoc.data()?['type'] == 'admin' ||
              userDoc.data()?['type'] == 'Admin';
          _isAdvertiser = userDoc.data()?['type'] == 'advertiser' ||
              userDoc.data()?['type'] == 'Advertiser';
          _isLoadingUserType = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserType = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user type: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleVolunteer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (hasJoined) {
        await _taskService.withdrawFromTask(widget.task.id);
      } else {
        await _taskService.volunteerForTask(widget.task.id);
      }

      if (mounted) {
        setState(() {
          hasJoined = !hasJoined;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasJoined
                  ? 'Successfully withdrawn from the task!'
                  : 'Successfully volunteered for the task',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.task.name),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.task.name),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final updatedTask = Task.fromFirestore(snapshot.data!);
        final departmentColor =
            Task.getColorForDepartment(updatedTask.department);
        final progress = updatedTask.currVolunteers / updatedTask.maxVolunteers;
        final dateFormat = DateFormat('MMM d, y');
        final timeFormat = DateFormat('h:mm a');
        hasJoined = updatedTask.volunteeredUsers.contains(widget.userId);

        return Scaffold(
          backgroundColor: const Color(0xFF1A365D),
          appBar: AppBar(
            title: Text(
              updatedTask.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1A365D),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient background
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1A365D),
                        Color(0xFF0A1929),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.7],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        updatedTask.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedTask.label,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: Colors.white.withOpacity(0.8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(updatedTask.startTime),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time,
                              color: Colors.white.withOpacity(0.8), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${timeFormat.format(updatedTask.startTime)} - ${timeFormat.format(updatedTask.endTime)}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF0A1929),
                        Color(0xFF1A365D),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      stops: [0.0, 0.7],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          updatedTask.department.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedTask.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Requirements
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedTask.requirements,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Contact Information
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone,
                              color: Colors.white.withOpacity(0.8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            updatedTask.phone,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email,
                              color: Colors.white.withOpacity(0.8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            updatedTask.email,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress
                      const Text(
                        'Volunteer Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${updatedTask.currVolunteers} / ${updatedTask.maxVolunteers} volunteers',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      if (_isAdmin) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Volunteers List',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (updatedTask.volunteeredUsers.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No volunteers yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          )
                        else
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .where('uid',
                                    whereIn: updatedTask.volunteeredUsers)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 8),
                                        Text('Loading volunteers...'),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final volunteers = snapshot.data?.docs ?? [];

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: volunteers.length,
                                itemBuilder: (context, index) {
                                  final volunteer = volunteers[index].data()
                                      as Map<String, dynamic>;
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                          volunteer['firstName']?[0] ?? '?'),
                                    ),
                                    title: Text(
                                      '${volunteer['firstName']} ${volunteer['lastName']}',
                                    ),
                                    subtitle: Text(volunteer['email'] ?? ''),
                                  );
                                },
                              );
                            },
                          ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _isLoadingUserType
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : !_isAdmin && !_isAdvertiser
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (updatedTask.status == TaskStatus.Completed ||
                                    _isLoading)
                                ? null
                                : _handleVolunteer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              updatedTask.status == TaskStatus.Completed
                                  ? Colors.grey
                                  : hasJoined
                                      ? Colors.red
                                      : Colors.white,
                          foregroundColor: hasJoined
                              ? Colors.white
                              : const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : updatedTask.status == TaskStatus.Completed
                                ? const Text(
                                    'Task Completed',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : Text(
                                    hasJoined
                                        ? 'Withdraw from Task'
                                        : 'Volunteer for Task',
                                    style: TextStyle(
                                      color: hasJoined
                                          ? Colors.white
                                          : const Color(0xFF1E3A8A),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                      ),
                    )
                  : null,
        );
      },
    );
  }
}
