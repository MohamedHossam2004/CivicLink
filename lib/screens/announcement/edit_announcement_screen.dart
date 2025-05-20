import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../utils/date_formatter.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final String announcementId;
  final Announcement announcement;

  const EditAnnouncementScreen({
    Key? key,
    required this.announcementId,
    required this.announcement,
  }) : super(key: key);

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final AnnouncementService _service = AnnouncementService();
  bool _isLoading = false;
  bool _isImportant = false;
  String _selectedLabel = 'General';
  DateTime? _startTime;
  DateTime? _endTime;

  final List<String> _labels = [
    'General',
    'Environment',
    'Community',
    'Healthcare',
    'Education',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.announcement.name;
    _descriptionController.text = widget.announcement.description;
    _phoneController.text = widget.announcement.phone;
    _emailController.text = widget.announcement.email;
    _departmentController.text = widget.announcement.department;
    _isImportant = widget.announcement.isImportant;
    _selectedLabel = widget.announcement.label;
    _startTime = widget.announcement.startTime;
    _endTime = widget.announcement.endTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStartTime) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? _startTime ?? DateTime.now()
          : _endTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _updateAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.updateAnnouncement(
        widget.announcementId,
        name: _nameController.text,
        description: _descriptionController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        department: _departmentController.text,
        label: _selectedLabel,
        isImportant: _isImportant,
        startTime: _startTime,
        endTime: _endTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating announcement: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Announcement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Department Field
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a department';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Label Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLabel,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _labels.map((String label) {
                  return DropdownMenuItem<String>(
                    value: label,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLabel = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Contact Information
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Range
              const Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Start Date
              ListTile(
                title: Text(_startTime != null
                    ? 'Start Date: ${DateFormatter.format(_startTime!)}'
                    : 'Select Start Date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),

              // End Date
              ListTile(
                title: Text(_endTime != null
                    ? 'End Date: ${DateFormatter.format(_endTime!)}'
                    : 'Select End Date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),

              const SizedBox(height: 16),

              // Important Toggle
              SwitchListTile(
                title: const Text('Mark as Important'),
                value: _isImportant,
                onChanged: (bool value) {
                  setState(() {
                    _isImportant = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAnnouncement,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Update Announcement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
