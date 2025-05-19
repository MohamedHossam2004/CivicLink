import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Clear all tasks from Firestore
  Future<void> clearAllTasks() async {
    final batch = _firestore.batch();
    final snapshots = await _firestore.collection('tasks').get();
    
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    final snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  // Get tasks by department
  Future<List<Task>> getTasksByDepartment(TaskDepartment department) async {
    final snapshot = await _firestore
        .collection('tasks')
        .where('department', isEqualTo: department.toString().split('.').last)
        .get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  // Get tasks by user
  Future<List<Task>> getTasksByUser(String userId) async {
    print('Getting tasks by user: $userId');
    final snapshot = await _firestore
        .collection('tasks')
        .where('volunteeredUsers', arrayContains: userId)
        .get();
    return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
  }

  // Volunteer for a task
  Future<void> volunteerForTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Must be logged in to volunteer';

    print('=== VOLUNTEER OPERATION START ===');
    print('Task ID: $taskId');
    print('User ID: ${user.uid}');
    print('User email: ${user.email}');
    print('Auth token: ${await user.getIdToken()}');

    try {
      // Get the task document reference
      final taskRef = _firestore.collection('tasks').doc(taskId);
      print('Task reference created');
      
      // Get the current task data
      final taskDoc = await taskRef.get();
      if (!taskDoc.exists) {
        print('ERROR: Task does not exist');
        throw 'Task does not exist';
      }

      final data = taskDoc.data()!;
      print('Current task data: $data');
      
      // Verify the task data structure
      if (!data.containsKey('volunteeredUsers')) {
        print('ERROR: Task is missing volunteeredUsers field');
        print('Available fields: ${data.keys.toList()}');
        // Initialize volunteeredUsers if it doesn't exist
        await taskRef.update({'volunteeredUsers': []});
        print('Initialized volunteeredUsers array');
      }

      final List<String> volunteers = List<String>.from(data['volunteeredUsers'] ?? []);
      print('Current volunteers: $volunteers');
      
      // Check if user already volunteered
      if (volunteers.contains(user.uid)) {
        print('ERROR: User already volunteered');
        throw 'You have already volunteered for this task';
      }

      // Check if task is full
      final int maxParticipants = data['maxParticipants'] ?? 0;
      print('Max participants: $maxParticipants');
      print('Current participants: ${volunteers.length}');
      
      if (volunteers.length >= maxParticipants) {
        print('ERROR: Task is full');
        throw 'This task is already full';
      }

      // Add user to volunteers list
      volunteers.add(user.uid);
      print('Updated volunteers list: $volunteers');

      // Create the update data
      final updateData = {
        'volunteeredUsers': volunteers,
        'participants': volunteers.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      print('Update data to be written: $updateData');

      // Perform the update
      print('Attempting to update Firestore...');
      try {
        await taskRef.update(updateData);
        print('Firestore update completed successfully');
      } catch (e) {
        print('ERROR: Firestore update failed');
        print('Error details: $e');
        // Try to get more information about the error
        if (e is FirebaseException) {
          print('Firebase error code: ${e.code}');
          print('Firebase error message: ${e.message}');
        }
        rethrow;
      }

      // Verify the update
      final updatedDoc = await taskRef.get();
      final updatedData = updatedDoc.data()!;
      print('Verification - Updated task data: $updatedData');
      
      final updatedVolunteers = List<String>.from(updatedData['volunteeredUsers'] ?? []);
      if (!updatedVolunteers.contains(user.uid)) {
        print('ERROR: Verification failed - user not found in updated volunteers list');
        throw 'Failed to update task - please try again';
      }

      print('=== VOLUNTEER OPERATION SUCCESSFUL ===');
    } catch (e, stackTrace) {
      print('=== VOLUNTEER OPERATION FAILED ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Withdraw from a task
  Future<void> withdrawFromTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Must be logged in to withdraw';

    print('Attempting to withdraw from task: $taskId');
    print('Current user: ${user.uid}');

    try {
      // Get the task document reference
      final taskRef = _firestore.collection('tasks').doc(taskId);
      
      // Get the current task data
      final taskDoc = await taskRef.get();
      if (!taskDoc.exists) {
        print('Task does not exist: $taskId');
        throw 'Task does not exist';
      }

      print('Task data before withdrawal: ${taskDoc.data()}');
      
      // Update the task using a direct update instead of a transaction
      final data = taskDoc.data()!;
      final List<String> volunteers = List<String>.from(data['volunteeredUsers'] ?? []);
      
      print('Current volunteers before withdrawal: $volunteers');

      // Check if user is volunteered
      if (!volunteers.contains(user.uid)) {
        print('User not found in volunteers list');
        throw 'You are not volunteered for this task';
      }

      // Remove user from volunteers list
      volunteers.remove(user.uid);
      print('Updated volunteers list after withdrawal: $volunteers');

      // Create the update data
      final updateData = {
        'volunteeredUsers': volunteers,
        'participants': volunteers.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      print('Update data for withdrawal: $updateData');

      // Update the document
      await taskRef.update(updateData);
      print('Withdrawal successful');

    } catch (e) {
      print('Error in withdrawFromTask: $e');
      rethrow;
    }
  }

  // Check if current user is volunteered for a task
  Future<bool> isUserVolunteered(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('Checking volunteer status for task: $taskId');
      print('Current user: ${user.uid}');

      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        print('Task not found: $taskId');
        return false;
      }

      final data = taskDoc.data()!;
      print('Task data: $data');
      
      final List<String> volunteers = List<String>.from(data['volunteeredUsers'] ?? []);
      print('Volunteers list: $volunteers');
      
      final bool isVolunteered = volunteers.contains(user.uid);
      print('Is user volunteered: $isVolunteered');
      
      return isVolunteered;
    } catch (e) {
      print('Error checking volunteer status: $e');
      return false;
    }
  }
} 