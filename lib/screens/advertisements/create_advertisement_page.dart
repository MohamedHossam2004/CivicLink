import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/file_upload_widget.dart';

class CreateAdvertisementPage extends StatefulWidget {
  const CreateAdvertisementPage({Key? key}) : super(key: key);

  @override
  State<CreateAdvertisementPage> createState() => _CreateAdvertisementPageState();
}

class _CreateAdvertisementPageState extends State<CreateAdvertisementPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  List<File> _imageFiles = [];
  File? _documentFile;
  bool _isLoading = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  // Map related variables
  bool _isMapVisible = false;
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
        _isMapVisible = true;

        // Add marker for the selected location
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            infoWindow: const InfoWindow(title: 'Advertisement Location'),
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
          infoWindow: const InfoWindow(title: 'Advertisement Location'),
        ),
      };

      // Update location controllers
      _latitudeController.text = tappedPoint.latitude.toString();
      _longitudeController.text = tappedPoint.longitude.toString();
    });
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> uploadedUrls = [];
    
    for (var imageFile in _imageFiles) {
      try {
        // Use CloudinaryService instead of direct Firebase Storage
        final url = await _cloudinaryService.uploadImage(imageFile);
        if (url != null) {
          uploadedUrls.add(url);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
    
    return uploadedUrls;
  }

  Future<void> _createAdvertisement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final imageUrls = await _uploadImages();
      String? documentUrl;
      
      // Upload document if one is selected
      if (_documentFile != null) {
        documentUrl = await _cloudinaryService.uploadDocument(_documentFile!);
      }
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await FirebaseFirestore.instance.collection('advertisements').add({
        'name': _nameController.text,
        'userId': userId,
        'imageUrls': imageUrls,
        'location': {
          'longitude': double.parse(_longitudeController.text),
          'latitude': double.parse(_latitudeController.text),
        },
        'createdOn': Timestamp.now(),
        'documentUrl': documentUrl,
        'phoneNumber': _phoneController.text,
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating advertisement: $e')),
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
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Advertisement'),
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
              // File Upload Widget
              FileUploadWidget(
                imageFiles: _imageFiles,
                documentFile: _documentFile,
                onImagesSelected: (files) {
                  setState(() {
                    _imageFiles = files;
                  });
                },
                onDocumentSelected: (file) {
                  setState(() {
                    _documentFile = file;
                  });
                },
                allowMultipleImages: true,
                documentLabel: 'Business Document',
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone number field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Map section
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter latitude';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
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
                                  infoWindow: const InfoWindow(title: 'Advertisement Location'),
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter longitude';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
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
                                  infoWindow: const InfoWindow(title: 'Advertisement Location'),
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

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAdvertisement,
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Create Advertisement',
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