import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import 'notification_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Listen for task updates and status changes
  void startTaskUpdateListener() {
    _firestore.collection('tasks')
      .snapshots()
      .listen((snapshot) {
        // Handle snapshot changes
        for (final change in snapshot.docChanges) {
          // Only process modified documents (status changes)
          if (change.type == DocumentChangeType.modified) {
            final taskData = change.doc.data() as Map<String, dynamic>?;
            if (taskData != null) {
              final task = Task.fromFirestore(change.doc);
              
              // Check for status changes
              if (change.oldIndex == -1 || change.newIndex == -1) {
                // Cannot determine if status actually changed, but we can still check
                // important status changes like task completion
                if (task.status == TaskStatus.Completed) {
                  _sendTaskStatusNotification(task, 'Task Completed', 
                    'A task you volunteered for has been marked as completed.');
                } else if (task.status == TaskStatus.Cancelled) {
                  _sendTaskStatusNotification(task, 'Task Cancelled', 
                    'A task you volunteered for has been cancelled.');
                }
              }

              // Check for volunteer updates - notify if someone new joined
              List<String> volunteeredUsers = List<String>.from(taskData['volunteeredUsers'] ?? []);
              if (volunteeredUsers.isNotEmpty && task.currVolunteers > 0) {
                // Could notify task creator or other volunteers
                // For now, we'll just notify the task creator or department
              }
            }
          } else if (change.type == DocumentChangeType.added) {
            // This is a new task - we can notify users interested in this department
            final taskData = change.doc.data() as Map<String, dynamic>?;
            if (taskData != null) {
              final task = Task.fromFirestore(change.doc);
              
              // For now, we don't notify users when tasks are created
              // This would require knowing which users are interested in which departments
            }
          }
        }
      });
  }

  // Helper to send notifications about task status changes
  Future<void> _sendTaskStatusNotification(Task task, String title, String body) async {
    // Notify all volunteers
    for (final userId in task.volunteeredUsers) {
      await _notificationService.sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: 'task_update',
        data: {
          'taskId': task.id,
          'status': task.status.toString(),
        },
      );
    }
  }

  Future<void> volunteerForTask(String taskId) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      final taskDoc = await taskRef.get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final task = Task.fromFirestore(taskDoc);
      if (!task.canVolunteer) {
        if (task.status == TaskStatus.Completed) {
          throw Exception('You cannot volunteer for a completed task.');
        } else if (task.status == TaskStatus.Cancelled) {
          throw Exception('You cannot volunteer for a cancelled task.');
        } else if (task.currVolunteers >= task.maxVolunteers) {
          throw Exception('Task is already full');
        } else {
          throw Exception('Task is not open for volunteering');
        }
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await taskRef.update({
        'currVolunteers': FieldValue.increment(1),
        'volunteeredUsers': FieldValue.arrayUnion([currentUserId])
      });

      // Send confirmation notification to the volunteer
      await _notificationService.sendNotificationToUser(
        userId: currentUserId,
        title: 'Task Volunteering Confirmed',
        body: 'You have successfully volunteered for: ${task.name}',
        type: 'task_volunteered',
        data: {
          'taskId': task.id,
        },
      );
      
    } catch (e) {
      throw Exception('Failed to volunteer for task: $e');
    }
  }

  Future<void> withdrawFromTask(String taskId) async {
    try {
      final taskRef = _firestore.collection('tasks').doc(taskId);
      final taskDoc = await taskRef.get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      final task = Task.fromFirestore(taskDoc);
      if (!task.canWithdraw) {
        if (task.status == TaskStatus.Completed) {
          throw Exception('You cannot withdraw from a completed task.');
        } else if (task.status == TaskStatus.Cancelled) {
          throw Exception('You cannot withdraw from a cancelled task.');
        } else {
          throw Exception('Task is not open for withdrawing');
        }
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await taskRef.update({
        'currVolunteers': FieldValue.increment(-1),
        'volunteeredUsers': FieldValue.arrayRemove([currentUserId])
      });

      // Send notification about withdrawal
      await _notificationService.sendNotificationToUser(
        userId: currentUserId,
        title: 'Task Withdrawal Confirmed',
        body: 'You have withdrawn from: ${task.name}',
        type: 'task_withdrawn',
        data: {
          'taskId': task.id,
        },
      );

    } catch (e) {
      throw Exception('Failed to withdraw from task: $e');
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        
        // Helper function to parse dates
        DateTime parseDate(dynamic date) {
          if (date == null || date == '') return DateTime.now();
          if (date is Timestamp) return date.toDate();
          if (date is String) {
            try {
              return DateTime.parse(date);
            } catch (e) {
              // Only log if it's not an empty string
              if (date.trim().isNotEmpty) {
                print('Error parsing date: $date');
              }
              return DateTime.now();
            }
          }
          return DateTime.now();
        }

        // Helper function to parse location
        Map<String, double> parseLocation(Map<String, dynamic>? locationData) {
          if (locationData == null) return {'latitude': 0.0, 'longitude': 0.0};
          
          return {
            'latitude': (locationData['latitude'] is int) 
                ? (locationData['latitude'] as int).toDouble() 
                : (locationData['latitude'] as double? ?? 0.0),
            'longitude': (locationData['longitude'] is int) 
                ? (locationData['longitude'] as int).toDouble() 
                : (locationData['longitude'] as double? ?? 0.0),
          };
        }

        return Task(
          id: doc.id,
          label: data['label'] ?? '',
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          requirements: data['requirements'] ?? '',
          department: Task.getDepartmentFromString(data['department'] ?? ''),
          status: TaskStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
            orElse: () => TaskStatus.Open,
          ),
          createdOn: parseDate(data['createdOn']),
          startTime: parseDate(data['startTime']),
          endTime: parseDate(data['endTime']),
          currVolunteers: data['currVolunteers'] ?? 0,
          maxVolunteers: data['maxVolunteers'] ?? 0,
          volunteeredUsers: List<String>.from(data['volunteeredUsers'] ?? []),
          phone: data['phone'] ?? '',
          email: data['email'] ?? '',
          location: parseLocation(data['location'] as Map<String, dynamic>?),
        );
      }).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<List<Task>> getTasksByDepartment(TaskDepartment department) async {
    try {
      final QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('department', isEqualTo: department.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .get();

      return tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tasks by department: $e');
    }
  }

  Future<List<Task>> getUserTasks(String userId) async {
    try {
      final QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('volunteeredUsers', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return tasksSnapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user tasks: $e');
    }
  }
} 