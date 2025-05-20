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
  bool hasJoined = false;

  @override
  void initState() {
    super.initState();
    hasJoined = widget.task.volunteeredUsers.contains(widget.userId);
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
              hasJoined ? 'Successfully withdrawn from the task!' : 'Successfully volunteered for the task',
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
      stream: FirebaseFirestore.instance.collection('tasks').doc(widget.task.id).snapshots(),
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
        final departmentColor = Task.getColorForDepartment(updatedTask.department);
        final progress = updatedTask.currVolunteers / updatedTask.maxVolunteers;
        final dateFormat = DateFormat('MMM d, y');
        final timeFormat = DateFormat('h:mm a');
        hasJoined = updatedTask.volunteeredUsers.contains(widget.userId);

        return Scaffold(
          appBar: AppBar(
            title: Text(updatedTask.name),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient background
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        departmentColor,
                        departmentColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
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
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            dateFormat.format(updatedTask.startTime),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${timeFormat.format(updatedTask.startTime)} - ${timeFormat.format(updatedTask.endTime)}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Department
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: departmentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          updatedTask.department.toString().split('.').last,
                          style: TextStyle(
                            color: departmentColor,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedTask.description,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        updatedTask.requirements,
                        style: TextStyle(
                          color: Colors.grey[600],
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            updatedTask.phone,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            updatedTask.email,
                            style: TextStyle(
                              color: Colors.grey[600],
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(departmentColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${updatedTask.currVolunteers} / ${updatedTask.maxVolunteers} volunteers',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: (updatedTask.status == TaskStatus.Completed || _isLoading)
                  ? null
                  : _handleVolunteer,
              style: ElevatedButton.styleFrom(
                backgroundColor: updatedTask.status == TaskStatus.Completed ? Colors.grey : hasJoined ? Colors.red : departmentColor,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : updatedTask.status == TaskStatus.Completed
                      ? Text(
                          'Task Completed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          hasJoined ? 'Withdraw from Task' : 'Volunteer for Task',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
        );
      },
    );
  }
} 