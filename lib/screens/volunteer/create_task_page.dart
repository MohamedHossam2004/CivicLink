import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTaskPage extends StatefulWidget {
  final String userId;
  const CreateTaskPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _maxVolunteersController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  String _label = 'Volunteer';
  String _status = 'Open';

  bool _isSubmitting = false;

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate() ||
        _startTime == null ||
        _endTime == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestore.collection('tasks').add({
        'department': _departmentController.text,
        'description': _descriptionController.text,
        'requirements': _requirementsController.text,
        'phone': _phoneController.text,
        'maxVolunteers': int.parse(_maxVolunteersController.text),
        'location': {
          'latitude': double.parse(_latitudeController.text),
          'longitude': double.parse(_longitudeController.text),
        },
        'name': _nameController.text,
        'email': _emailController.text,
        'startTime': _startTime!.toUtc().toIso8601String(),
        'endTime': _endTime!.toUtc().toIso8601String(),
        'label': _label,
        'status': _status,
        'createdOn': FieldValue.serverTimestamp(),
        'currVolunteers': 0,
        'volunteeredUsers': [],
      });

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create task: $e')),
      );
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    final dateTime =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = dateTime;
      } else {
        _endTime = dateTime;
      }
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: type,
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Task'),
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  controller: _nameController,
                  label: 'Task Name',
                  validator: _required),
              _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  validator: _required),
              _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  validator: _required,
                  maxLines: 2),
              _buildTextField(
                  controller: _requirementsController,
                  label: 'Requirements',
                  maxLines: 2),
              _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  validator: _required,
                  type: TextInputType.phone),
              _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: _required,
                  type: TextInputType.emailAddress),
              _buildTextField(
                  controller: _latitudeController,
                  label: 'Latitude',
                  validator: _required,
                  type: TextInputType.number),
              _buildTextField(
                  controller: _longitudeController,
                  label: 'Longitude',
                  validator: _required,
                  type: TextInputType.number),
              _buildTextField(
                  controller: _maxVolunteersController,
                  label: 'Max Volunteers',
                  validator: _required,
                  type: TextInputType.number),
              const SizedBox(height: 8),
              DropdownButtonFormField(
                value: _label,
                items: const [
                  DropdownMenuItem(
                      value: 'Volunteer', child: Text('Volunteer')),
                  DropdownMenuItem(value: 'Other', child: Text('Other'))
                ],
                onChanged: (value) => setState(() => _label = value!),
                decoration: InputDecoration(
                  labelText: 'Label',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'Open', child: Text('Open')),
                  DropdownMenuItem(value: 'Closed', child: Text('Closed'))
                ],
                onChanged: (value) => setState(() => _status = value!),
                decoration: InputDecoration(
                  labelText: 'Status',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(_startTime == null
                    ? 'Pick Start Time'
                    : 'Start: $_startTime'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title:
                    Text(_endTime == null ? 'Pick End Time' : 'End: $_endTime'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Task',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? val) =>
      (val == null || val.trim().isEmpty) ? 'This field is required' : null;
}
