import 'package:flutter/material.dart';
import '../../../models/task.dart';

class TaskListCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskListCard({
    Key? key,
    required this.task,
    required this.onTap,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final departmentColor = _getDepartmentColor(task.department);
    final progress = task.participants / task.maxParticipants;

    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          // Main Card
          Container(
            margin: const EdgeInsets.only(left: 6), // Make space for the stripe
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: departmentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.department.toString().split('.').last,
                              style: TextStyle(
                                color: departmentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Task Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, 
                            size: 16, 
                            color: Colors.grey[600]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.calendar_today_outlined, 
                            size: 16, 
                            color: Colors.grey[600]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.date,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined, 
                            size: 16, 
                            color: Colors.grey[600]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.time,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.people_outline, 
                            size: 16, 
                            color: Colors.grey[600]
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.participants}/${task.maxParticipants}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(departmentColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Left Stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
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
    );
  }
} 