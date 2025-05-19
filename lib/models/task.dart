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

// Sample tasks data
List<Task> getTasks() {
  return [
    Task(
      id: "1",
      title: "Park Cleanup",
      description: "Help clean up Central Park by collecting trash and maintaining the green spaces.",
      location: "Central Park",
      date: "May 15, 2025",
      time: "9:00 AM - 12:00 PM",
      participants: 12,
      maxParticipants: 20,
      department: TaskDepartment.Environment,
      color: Colors.green,
      createdBy: "admin1",
    ),
    Task(
      id: "2",
      title: "Food Drive",
      description: "Collect and distribute food donations to local shelters and families in need.",
      location: "Community Center",
      date: "May 18, 2025",
      time: "10:00 AM - 2:00 PM",
      participants: 8,
      maxParticipants: 15,
      department: TaskDepartment.Community,
      color: Colors.amber,
      createdBy: "admin1",
    ),
    Task(
      id: "3",
      title: "Senior Assistance",
      description: "Help elderly residents with grocery shopping, home maintenance, and companionship.",
      location: "Riverside Homes",
      date: "May 22, 2025",
      time: "2:00 PM - 5:00 PM",
      participants: 5,
      maxParticipants: 10,
      department: TaskDepartment.Healthcare,
      color: Colors.blue,
      createdBy: "admin2",
    ),
    Task(
      id: "4",
      title: "Tree Planting",
      description: "Plant new trees along Riverside Park to improve air quality and beautify the area.",
      location: "Riverside Park",
      date: "May 25, 2025",
      time: "8:00 AM - 1:00 PM",
      participants: 15,
      maxParticipants: 25,
      department: TaskDepartment.Environment,
      color: Colors.green,
      createdBy: "admin1",
    ),
    Task(
      id: "5",
      title: "Youth Mentoring",
      description: "Mentor young students in academic subjects and provide guidance for their future.",
      location: "Public Library",
      date: "Every Saturday",
      time: "2:00 PM - 4:00 PM",
      participants: 12,
      maxParticipants: 20,
      department: TaskDepartment.Education,
      color: Colors.indigo,
      createdBy: "admin2",
    ),
    Task(
      id: "6",
      title: "Community Garden",
      description: "Maintain the community garden by watering plants, weeding, and harvesting vegetables.",
      location: "Downtown Garden",
      date: "May 22, 2025",
      time: "9:00 AM - 11:00 AM",
      participants: 7,
      maxParticipants: 10,
      department: TaskDepartment.Environment,
      color: Colors.green,
      createdBy: "admin1",
      joined: true,
    ),
    Task(
      id: "7",
      title: "Recycling Drive",
      description: "Collect recyclable materials from residents and educate them about proper recycling practices.",
      location: "City Hall",
      date: "May 30, 2025",
      time: "1:00 PM - 5:00 PM",
      participants: 20,
      maxParticipants: 25,
      department: TaskDepartment.Environment,
      color: Colors.green,
      createdBy: "admin2",
      joined: true,
    ),
    Task(
      id: "8",
      title: "Beach Cleanup",
      description: "Cleaned up the local beach by removing trash and plastic waste.",
      location: "Sunset Beach",
      date: "April 25, 2025",
      time: "8:00 AM - 12:00 PM",
      participants: 30,
      maxParticipants: 30,
      department: TaskDepartment.Environment,
      color: Colors.grey,
      createdBy: "admin1",
      completed: true,
    ),
    Task(
      id: "9",
      title: "Vaccination Drive",
      description: "Assisted healthcare workers in organizing and managing a community vaccination event.",
      location: "Health Center",
      date: "April 15, 2025",
      time: "9:00 AM - 4:00 PM",
      participants: 15,
      maxParticipants: 15,
      department: TaskDepartment.Healthcare,
      color: Colors.grey,
      createdBy: "admin2",
      completed: true,
    ),
  ];
}