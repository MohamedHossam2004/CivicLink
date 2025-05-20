// models/task.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskDepartment {
  EnvironmentalServices,
  CommunityEvents,
  Education,
  HealthServices,
  CommunityServices
}

enum TaskStatus { Cancelled, Open, Completed }

class Task {
  final String id;
  final String label;
  final String name;
  final String description;
  final String requirements;
  final TaskDepartment department;
  final TaskStatus status;
  final DateTime createdOn;
  final DateTime startTime;
  final DateTime endTime;
  final int currVolunteers;
  final int maxVolunteers;
  final List<String> volunteeredUsers;
  final String phone;
  final String email;
  final Map<String, double> location;

  Task({
    required this.id,
    required this.label,
    required this.name,
    required this.description,
    required this.requirements,
    required this.department,
    required this.status,
    required this.createdOn,
    required this.startTime,
    required this.endTime,
    required this.currVolunteers,
    required this.maxVolunteers,
    required this.volunteeredUsers,
    required this.phone,
    required this.email,
    required this.location,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();

      if (date is Timestamp) {
        return date.toDate();
      }

      if (date is String) {
        try {
          // Try parsing ISO format
          return DateTime.parse(date);
        } catch (e) {
          try {
            // Try parsing Firestore timestamp string format
            final milliseconds = int.tryParse(date);
            if (milliseconds != null) {
              return DateTime.fromMillisecondsSinceEpoch(milliseconds);
            }
          } catch (e) {
            print('Error parsing date: $date');
          }
        }
      }

      return DateTime.now();
    }

    // Helper function to convert location values to double
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
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'name': name,
      'description': description,
      'requirements': requirements,
      'department': department.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdOn': Timestamp.fromDate(createdOn),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'currVolunteers': currVolunteers,
      'maxVolunteers': maxVolunteers,
      'volunteeredUsers': volunteeredUsers,
      'phone': phone,
      'email': email,
      'location': location,
    };
  }

  // Convert department string to enum
  static TaskDepartment getDepartmentFromString(String department) {
    // Create a map of display names to enum values
    final Map<String, TaskDepartment> departmentMap = {
      'Environmental Services': TaskDepartment.EnvironmentalServices,
      'Community Events': TaskDepartment.CommunityEvents,
      'Education': TaskDepartment.Education,
      'Health Services': TaskDepartment.HealthServices,
      'Community Services': TaskDepartment.CommunityServices,
    };

    // Try to find the department in the map
    return departmentMap[department] ?? TaskDepartment.CommunityEvents;
  }

  // Get color based on department
  static Color getColorForDepartment(TaskDepartment department) {
    switch (department) {
      case TaskDepartment.EnvironmentalServices:
        return const Color(0xFF4CAF50); // Material Green
      case TaskDepartment.CommunityEvents:
        return const Color(0xFFFF9800); // Material Orange
      case TaskDepartment.Education:
        return const Color(0xFF3F51B5); // Material Indigo
      case TaskDepartment.HealthServices:
        return const Color(0xFFE53935); // Material Red
      case TaskDepartment.CommunityServices:
        return const Color(0xFF2196F3); // Material Blue
    }
  }

  // Create a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? label,
    String? name,
    String? description,
    String? requirements,
    TaskDepartment? department,
    TaskStatus? status,
    DateTime? createdOn,
    DateTime? startTime,
    DateTime? endTime,
    int? currVolunteers,
    int? maxVolunteers,
    List<String>? volunteeredUsers,
    String? phone,
    String? email,
    Map<String, double>? location,
  }) {
    return Task(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      department: department ?? this.department,
      status: status ?? this.status,
      createdOn: createdOn ?? this.createdOn,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currVolunteers: currVolunteers ?? this.currVolunteers,
      maxVolunteers: maxVolunteers ?? this.maxVolunteers,
      volunteeredUsers: volunteeredUsers ?? List.from(this.volunteeredUsers),
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? Map.from(this.location),
    );
  }

  // Returns true if the task can be volunteered for
  bool get canVolunteer {
    return status == TaskStatus.Open && currVolunteers < maxVolunteers;
  }

  // Returns true if the task can be withdrawn from
  bool get canWithdraw {
    return status == TaskStatus.Open;
  }

  // Returns the correct action message for volunteering/withdrawing
  String getActionMessage(bool joined) {
    if (status == TaskStatus.Completed) {
      return 'This task is completed.';
    } else if (status == TaskStatus.Cancelled) {
      return 'This task is cancelled.';
    } else if (joined) {
      return 'Successfully volunteered from the task';
    } else {
      return 'Successfully withdrew from the task';
    }
  }
}
