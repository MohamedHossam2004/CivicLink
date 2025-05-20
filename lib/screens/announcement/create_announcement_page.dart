import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class CreateAnnouncementPage extends StatefulWidget {
  final String userId;
  const CreateAnnouncementPage({Key? key, required this.userId})
      : super(key: key);

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _departmentController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentUrlController = TextEditingController();
  final _emailController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  String _label = 'Education';
  bool _isImportant = false;
  bool _isSubmitting = false;
  
  // Map related variables
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Location location = Location();

      // Check if location services are enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      // Check if permission is granted
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      // Get the current location
      final locationData = await location.getLocation();

      setState(() {
        _selectedLocation = LatLng(
          locationData.latitude ?? 0.0,
          locationData.longitude ?? 0.0,
        );

        // Add marker for the selected location
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            infoWindow: const InfoWindow(title: 'Announcement Location'),
          ),
        };

        // Update the location controllers
        _latitudeController.text = _selectedLocation!.latitude.toString();
        _longitudeController.text = _selectedLocation!.longitude.toString();
      });

      // Move camera to the current location if map controller is available
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _selectedLocation!,
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  // Handle map tap to update location
  void _handleMapTap(LatLng tappedPoint) {
    setState(() {
      _selectedLocation = tappedPoint;

      // Update marker
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: tappedPoint,
          infoWindow: const InfoWindow(title: 'Announcement Location'),
        ),
      };

      // Update location controllers
      _latitudeController.text = tappedPoint.latitude.toString();
      _longitudeController.text = tappedPoint.longitude.toString();
    });
  }

  Future<void> _submitAnnouncement() async {
    if (!_formKey.currentState!.validate() ||
        _startTime == null ||
        _endTime == null) return;

    setState(() => _isSubmitting = true);

    try {
      await _firestore.collection('announcements').add({
        'department': _departmentController.text,
        'description': _descriptionController.text,
        'documentUrl': _documentUrlController.text,
        'email': _emailController.text,
        'location': {
          'latitude': double.parse(_latitudeController.text),
          'longitude': double.parse(_longitudeController.text),
        },
        'name': _nameController.text,
        'phone': _phoneController.text,
        'startTime': _startTime!.toUtc().toIso8601String(),
        'endTime': _endTime!.toUtc().toIso8601String(),
        'label': _label,
        'isImportant': _isImportant,
        'createdOn': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create announcement: $e')),
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
  void dispose() {
    _departmentController.dispose();
    _descriptionController.dispose();
    _documentUrlController.dispose();
    _emailController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: const Color(0xFF8B5CF6),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  controller: _nameController,
                  label: 'Announcement Title',
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
                  controller: _documentUrlController, label: 'Document URL'),
              _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  validator: _required,
                  type: TextInputType.emailAddress),
              _buildTextField(
                  controller: _phoneController,
                  label: 'Phone',
                  validator: _required,
                  type: TextInputType.phone),
                  
              // Map section
              const SizedBox(height: 16),
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap on the map to select location or provide coordinates',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _selectedLocation != null
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation!,
                          zoom: 15,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onTap: _handleMapTap,
                      )
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Location Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _required,
                      onChanged: (value) {
                        if (value.isNotEmpty && _longitudeController.text.isNotEmpty) {
                          try {
                            final lat = double.parse(value);
                            final lng = double.parse(_longitudeController.text);
                            
                            setState(() {
                              _selectedLocation = LatLng(lat, lng);
                              _markers = {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(title: 'Announcement Location'),
                                ),
                              };
                            });
                            
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(_selectedLocation!),
                            );
                          } catch (e) {
                            // Invalid number format
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _required,
                      onChanged: (value) {
                        if (value.isNotEmpty && _latitudeController.text.isNotEmpty) {
                          try {
                            final lat = double.parse(_latitudeController.text);
                            final lng = double.parse(value);
                            
                            setState(() {
                              _selectedLocation = LatLng(lat, lng);
                              _markers = {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(title: 'Announcement Location'),
                                ),
                              };
                            });
                            
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLng(_selectedLocation!),
                            );
                          } catch (e) {
                            // Invalid number format
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const SizedBox(height: 8),
              DropdownButtonFormField(
                value: _label,
                items: const [
                  DropdownMenuItem(
                      value: 'Education', child: Text('Education')),
                  DropdownMenuItem(
                      value: 'Community', child: Text('Community')),
                  DropdownMenuItem(value: 'Health', child: Text('Health'))
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
              SwitchListTile(
                title: const Text('Mark as Important'),
                value: _isImportant,
                onChanged: (val) => setState(() => _isImportant = val),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(_startTime == null
                    ? 'Pick Start Time'
                    : 'Start: ${_startTime.toString()}'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title:
                    Text(_endTime == null ? 'Pick End Time' : 'End: ${_endTime.toString()}'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnnouncement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Announcement',
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
