import 'package:flutter/material.dart';
import '../../../models/task.dart';
import '../../../services/task_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onRefresh;

  const TaskCard({
    Key? key,
    required this.task,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  final TaskService _taskService = TaskService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isVolunteered = false;
  bool _isLoading = false;
  late Task _currentTask;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _checkVolunteerStatus();
    _listenToTaskChanges();
  }

  void _listenToTaskChanges() {
    _firestore
        .collection('tasks')
        .doc(_currentTask.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _currentTask = Task.fromFirestore(snapshot);
        });
      }
    });
  }

  Future<void> _checkVolunteerStatus() async {
    final status = await _taskService.isUserVolunteered(_currentTask.id);
    if (mounted) {
      setState(() {
        _isVolunteered = status;
      });
    }
  }

  Future<void> _toggleVolunteer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isVolunteered) {
        await _taskService.withdrawFromTask(_currentTask.id);
      } else {
        await _taskService.volunteerForTask(_currentTask.id);
      }

      setState(() {
        _isVolunteered = !_isVolunteered;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isVolunteered
                  ? 'Successfully volunteered for task!'
                  : 'Successfully withdrawn from task',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh parent if callback provided
      widget.onRefresh?.call();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentColor = Task.getColorForDepartment(_currentTask.department);
    final progress = _currentTask.currVolunteers / _currentTask.maxVolunteers;
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to task detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentTask.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentTask.label,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildVolunteerButton(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentTask.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(_currentTask.startTime),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${timeFormat.format(_currentTask.startTime)} - ${timeFormat.format(_currentTask.endTime)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_currentTask.currVolunteers}/${_currentTask.maxVolunteers} Volunteers',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: departmentColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: departmentColor,
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

  Widget _buildVolunteerButton() {
    if (_isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    return TextButton(
      onPressed: _toggleVolunteer,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: _isVolunteered ? Colors.grey.shade200 : departmentColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        _isVolunteered ? 'Withdraw' : 'Volunteer',
        style: TextStyle(
          color: _isVolunteered ? Colors.grey : departmentColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 