import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _choicesControllers = <TextEditingController>[];
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Add initial choice field
    _choicesControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _choicesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitPoll() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    // Check if we have at least two non-empty options
    final validOptions = _choicesControllers
        .where((controller) => controller.text.trim().isNotEmpty)
        .length;
    if (validOptions < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least two poll options')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Format the expiry date as "YYYY-MM-DDT00:00:00Z"
      final formattedDate =
          "${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}T00:00:00Z";

      // Create poll document
      final pollRef = await FirebaseFirestore.instance.collection('polls').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': formattedDate,
        'isActive': true,
      });

      // Add choices
      for (var controller in _choicesControllers) {
        if (controller.text.trim().isNotEmpty) {
          await pollRef.collection('choices').add({
            'text': controller.text.trim(),
            'type': 'text',
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating poll: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Create Poll',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Poll Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                _expiryDate == null
                    ? 'Select Expiry Date *'
                    : 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                style: TextStyle(
                  color: _expiryDate == null ? Colors.red : null,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
            const SizedBox(height: 16),
            const Text(
              'Poll Options *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            const Text(
              '(At least 2 options required)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ..._choicesControllers.map((controller) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: 'Option *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an option';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_choicesControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle),
                        onPressed: () {
                          setState(() {
                            controller.dispose();
                            _choicesControllers.remove(controller);
                          });
                        },
                      ),
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _choicesControllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPoll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
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
                        'Create Poll',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
