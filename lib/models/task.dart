// models/task.dart
import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String location;
  final String date;
  final String time;
  final int participants;
  final int maxParticipants;
  final String category;
  final Color color;
  final bool joined;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.participants,
    required this.maxParticipants,
    required this.category,
    required this.color,
    this.joined = false,
    this.completed = false,
  });
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
      category: "Environment",
      color: Colors.green,
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
      category: "Community",
      color: Colors.amber,
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
      category: "Healthcare",
      color: Colors.blue,
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
      category: "Environment",
      color: Colors.green,
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
      category: "Education",
      color: Colors.indigo,
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
      category: "Environment",
      color: Colors.green,
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
      category: "Environment",
      color: Colors.green,
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
      category: "Environment",
      color: Colors.grey,
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
      category: "Healthcare",
      color: Colors.grey,
      completed: true,
    ),
  ];
}