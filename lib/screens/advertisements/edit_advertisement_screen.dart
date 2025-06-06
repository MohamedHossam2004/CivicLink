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

class EditAdvertisementScreen extends StatefulWidget {
  final String advertisementId;
  final Map<String, dynamic> advertisement;

  const EditAdvertisementScreen({
    Key? key,
    required this.advertisementId,
    required this.advertisement,
  }) : super(key: key);

  @override
  State<EditAdvertisementScreen> createState() =>
      _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState extends State<EditAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _phoneController = TextEditingController();
  List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];
  File? _documentFile;
  String? _existingDocumentUrl;
  bool _isLoading = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  
  // Map related variables
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController.text = widget.advertisement['name'] ?? '';
    _existingDocumentUrl = widget.advertisement['documentUrl'];
    _latitudeController.text =
        widget.advertisement['location']?['latitude']?.toString() ?? '';
    _longitudeController.text =
        widget.advertisement['location']?['longitude']?.toString() ?? '';
    _phoneController.text = widget.advertisement['phoneNumber'] ?? '';
    _existingImageUrls =
        List<String>.from(widget.advertisement['imageUrls'] ?? []);
        
    // Initialize map location
    if (widget.advertisement['location'] != null) {
      final lat = widget.advertisement['location']['latitude'];
      final lng = widget.advertisement['location']['longitude'];
      
      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
        _markers = {
          Marker(
            markerId: const MarkerId('selected_location'),
            position: _selectedLocation!,
            infoWindow: const InfoWindow(title: 'Advertisement Location'),
          ),
        };
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
        _newImageFiles.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<List<String>> _uploadNewImages() async {
    List<String> uploadedUrls = [];

    for (var imageFile in _newImageFiles) {
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

  Future<void> _updateAdvertisement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newImageUrls = await _uploadNewImages();
      final allImageUrls = [..._existingImageUrls, ...newImageUrls];
      
      // Handle document upload or keep existing URL
      String? documentUrl = _existingDocumentUrl;
      
      if (_documentFile != null) {
        // Upload new document
        documentUrl = await _cloudinaryService.uploadDocument(_documentFile!);
      }

      await FirebaseFirestore.instance
          .collection('advertisements')
          .doc(widget.advertisementId)
          .update({
        'name': _nameController.text,
        'imageUrls': allImageUrls,
        'location': {
          'longitude': double.parse(_longitudeController.text),
          'latitude': double.parse(_latitudeController.text),
        },
        'documentUrl': documentUrl,
        'phoneNumber': _phoneController.text,
        'status': 'pending', // Reset status to pending for admin review
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating advertisement: $e')),
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
        title: const Text('Edit Advertisement'),
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
                imageFiles: _newImageFiles,
                documentFile: _documentFile,
                onImagesSelected: (files) {
                  setState(() {
                    _newImageFiles = files;
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
              
              // Existing Images
              if (_existingImageUrls.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Current Images',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingImageUrls.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _existingImageUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _existingImageUrls.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Show existing document URL if any
              if (_existingDocumentUrl != null && _documentFile == null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Current Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 36,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Business Document',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _existingDocumentUrl = null;
                          });
                        },
                        child: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
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
                'Tap on the map to update location',
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAdvertisement,
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
                          'Update Advertisement',
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
