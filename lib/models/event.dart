// models/event.dart
import 'package:flutter/material.dart';

class Event {
  final int id;
  final String title;
  final String time;
  final String? location;
  final String category;
  final String department;
  final Color color;
  final DateTime date;

  Event({
    required this.id,
    required this.title,
    required this.time,
    this.location,
    required this.category,
    required this.department,
    required this.color,
    required this.date,
  });
}

// Sample events data
List<Event> getEvents() {
  return [
    Event(
      id: 1,
      title: "Park Cleanup",
      time: "9:00 AM - 12:00 PM",
      location: "Central Park",
      category: "Volunteer",
      department: "Environmental Department",
      color: Colors.green,
      date: DateTime(2025, 5, 15),
    ),
    Event(
      id: 2,
      title: "City Council Meeting",
      time: "2:00 PM - 3:30 PM",
      location: "City Hall",
      category: "Government",
      department: "City Council",
      color: Colors.blue,
      date: DateTime(2025, 5, 15),
    ),
    Event(
      id: 3,
      title: "Utility Bill Payment Deadline",
      time: "All Day",
      category: "Payment",
      department: "Finance Department",
      color: Colors.amber,
      date: DateTime(2025, 5, 20),
    ),
    Event(
      id: 4,
      title: "Public Vaccination Drive",
      time: "10:00 AM - 4:00 PM",
      location: "Community Center",
      category: "Health",
      department: "Health Department",
      color: Colors.red,
      date: DateTime(2025, 5, 22),
    ),
    Event(
      id: 5,
      title: "Food Distribution",
      time: "1:00 PM - 5:00 PM",
      location: "Downtown Square",
      category: "Community",
      department: "Social Services",
      color: Colors.indigo,
      date: DateTime(2025, 5, 25),
    ),
    Event(
      id: 6,
      title: "Road Construction Begins",
      time: "7:00 AM - 5:00 PM",
      location: "Main Street",
      category: "Infrastructure",
      department: "Public Works",
      color: Colors.orange,
      date: DateTime(2025, 5, 18),
    ),
    Event(
      id: 7,
      title: "Public Budget Hearing",
      time: "6:00 PM - 8:00 PM",
      location: "City Hall",
      category: "Government",
      department: "Finance Department",
      color: Colors.blue,
      date: DateTime(2025, 5, 27),
    ),
    Event(
      id: 8,
      title: "Farmers Market",
      time: "8:00 AM - 1:00 PM",
      location: "City Square",
      category: "Community",
      department: "Economic Development",
      color: Colors.indigo,
      date: DateTime(2025, 5, 8),
    ),
  ];
}