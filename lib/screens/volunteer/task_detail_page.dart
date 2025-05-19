import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

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

  Color _getDepartmentColor(TaskDepartment department) {
    switch (department) {
      case TaskDepartment.Environment:
        return Colors.green;
      case TaskDepartment.Community:
        return Colors.orange;
      case TaskDepartment.Healthcare:
        return Colors.blue;
      case TaskDepartment.Education:
        return Colors.purple;
    }
  }

  Future<void> _handleVolunteer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _taskService.volunteerForTask(widget.task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully volunteered for the task!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
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
    final departmentColor = _getDepartmentColor(widget.task.department);
    final progress = widget.task.participants / widget.task.maxParticipants;
    final hasJoined = widget.task.volunteeredUsers.contains(widget.userId);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Task Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colored Header
                Container(
                  decoration: BoxDecoration(
                    color: departmentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.task.department.toString().split('.').last,
                          style: TextStyle(
                            color: departmentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.task.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.task.location,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(widget.task.date, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(widget.task.time, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Organized by & Volunteers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Placeholder for organizer avatar
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person, color: Colors.grey, size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Organized by', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '${widget.task.department.toString().split('.').last} Department',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.task.participants} of ${widget.task.maxParticipants} Volunteers',
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(departmentColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 18),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        widget.task.description,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 18),
                // // Requirements
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 20),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       const Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                //       const SizedBox(height: 8),
                //       Text(
                //         widget.task.description,
                //         style: const TextStyle(fontSize: 13),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 18),
                // Volunteers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Volunteers ( ${widget.task.volunteeredUsers.length} )', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(
                            widget.task.volunteeredUsers.length > 5 ? 5 : widget.task.volunteeredUsers.length,
                            (i) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.person, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          if (widget.task.volunteeredUsers.length > 5)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '+${widget.task.volunteeredUsers.length - 5}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: hasJoined || widget.task.participants >= widget.task.maxParticipants || _isLoading
                ? null
                : _handleVolunteer,
            style: ElevatedButton.styleFrom(
              backgroundColor: departmentColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.task.completed
                        ? 'Completed'
                        : hasJoined
                            ? 'Already Volunteered'
                            : widget.task.participants >= widget.task.maxParticipants
                                ? 'Task Full'
                                : 'Volunteer Now',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
} 