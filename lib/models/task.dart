// models/task.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskDepartment {
  Healthcare,
  Environment,
  Education,
  Community,
}

class Task {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String time;
  final int participants;
  final int maxParticipants;
  final TaskDepartment department;
  final Color color;
  final bool joined;
  final bool completed;
  final String createdBy; // Admin who created the task
  final DateTime createdAt;
  final List<String> volunteeredUsers; // List of user IDs who volunteered

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.participants,
    required this.maxParticipants,
    required this.department,
    required this.color,
    required this.createdBy,
    DateTime? createdAt,
    List<String>? volunteeredUsers,
    this.joined = false,
    this.completed = false,
  }) : this.createdAt = createdAt ?? DateTime.now(),
       this.volunteeredUsers = volunteeredUsers ?? [];

  // Convert Firestore document to Task object
  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print('Converting Firestore doc to Task. ID: ${doc.id}, Data: $data');
    
    // Get the volunteered users list and calculate participants
    List<String> volunteeredUsers = List<String>.from(data['volunteeredUsers'] ?? []);
    int participants = volunteeredUsers.length;
    print('Volunteers: $volunteeredUsers, Participants: $participants');

    return Task(
      id: data['id'] ?? doc.id, // Try to use stored ID first, fallback to doc.id
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      participants: participants,
      maxParticipants: data['maxParticipants'] ?? 0,
      department: TaskDepartment.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (data['department'] ?? '').toLowerCase(),
        orElse: () => TaskDepartment.Community,
      ),
      color: getColorForDepartment(TaskDepartment.values.firstWhere(
        (e) => e.toString().split('.').last.toLowerCase() == (data['department'] ?? '').toLowerCase(),
        orElse: () => TaskDepartment.Community,
      )),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      volunteeredUsers: volunteeredUsers,
      completed: data['completed'] ?? false,
    );
  }

  // Convert Task object to Firestore document
  Map<String, dynamic> toFirestore() {
    final data = {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date,
      'time': time,
      'maxParticipants': maxParticipants,
      'department': department.toString().split('.').last,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'volunteeredUsers': volunteeredUsers,
      'completed': completed,
    };
    print('Converting Task to Firestore data: $data');
    return data;
  }

  // Convert department string to enum
  static TaskDepartment getDepartmentFromString(String department) {
    return TaskDepartment.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == department.toLowerCase(),
      orElse: () => TaskDepartment.Community,
    );
  }

  // Get color based on department
  static Color getColorForDepartment(TaskDepartment department) {
    switch (department) {
      case TaskDepartment.Healthcare:
        return Colors.blue;
      case TaskDepartment.Environment:
        return Colors.green;
      case TaskDepartment.Education:
        return Colors.indigo;
      case TaskDepartment.Community:
        return Colors.amber;
    }
  }

  // Create a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? date,
    String? time,
    int? participants,
    int? maxParticipants,
    TaskDepartment? department,
    Color? color,
    String? createdBy,
    DateTime? createdAt,
    List<String>? volunteeredUsers,
    bool? joined,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      department: department ?? this.department,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      volunteeredUsers: volunteeredUsers ?? List.from(this.volunteeredUsers),
      joined: joined ?? this.joined,
      completed: completed ?? this.completed,
    );
  }
}
