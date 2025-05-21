import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gov_app/screens/ReportIssue/report_confirmation.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/report_service.dart';

class ReportPreview extends StatefulWidget {
  final String issueType;
  final String description;
  final String location;
  final LatLng? coordinates;
  final List<XFile?> photos;

  const ReportPreview({
    Key? key,
    required this.issueType,
    required this.description,
    required this.location,
    this.coordinates,
    required this.photos,
  }) : super(key: key);

  @override
  State<ReportPreview> createState() => _ReportPreviewState();
}

class _ReportPreviewState extends State<ReportPreview> {
  bool _isSubmitting = false;

  Future<void> _submitReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportService = ReportService();

      final List<XFile> photosToUpload =
          widget.photos.whereType<XFile>().toList();
      if (photosToUpload.isNotEmpty) {
        try {} catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo upload failed: $e')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      final String reportId = await reportService.submitReport(
        issueType: widget.issueType,
        description: widget.description,
        location: widget.location,
        coordinates: widget.coordinates,
        photos: widget.photos,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportConfirmation(
            reportId: reportId,
            issueType: widget.issueType,
            description: widget.description,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final validPhotoCount =
        widget.photos.where((photo) => photo != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFF1A365D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text('Review Report', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Your Report',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please review the information below before submitting your report.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Issue Type'),
                  _buildInfoCard(widget.issueType),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Description'),
                  _buildInfoCard(widget.description.isEmpty
                      ? 'No description provided'
                      : widget.description),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Location'),
                  _buildInfoCard(widget.location),
                  const SizedBox(height: 16),
                  if (widget.coordinates != null) ...[
                    _buildSectionTitle('Map'),
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: widget.coordinates!,
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('selected_location'),
                              position: widget.coordinates!,
                              infoWindow:
                                  const InfoWindow(title: 'Issue Location'),
                            ),
                          },
                          myLocationEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          zoomGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          compassEnabled: false,
                          onMapCreated: (controller) {
                            controller.setMapStyle('''
                              [
                                {
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#242f3e"
                                    }
                                  ]
                                },
                                {
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#746855"
                                    }
                                  ]
                                },
                                {
                                  "elementType": "labels.text.stroke",
                                  "stylers": [
                                    {
                                      "color": "#242f3e"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "administrative.locality",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#d59563"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "poi",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#d59563"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "poi.park",
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#263c3f"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "poi.park",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#6b9a76"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road",
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#38414e"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road",
                                  "elementType": "geometry.stroke",
                                  "stylers": [
                                    {
                                      "color": "#212a37"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#9ca5b3"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road.highway",
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#746855"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road.highway",
                                  "elementType": "geometry.stroke",
                                  "stylers": [
                                    {
                                      "color": "#1f2835"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "road.highway",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#f3d19c"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "transit",
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#2f3948"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "transit.station",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#d59563"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "water",
                                  "elementType": "geometry",
                                  "stylers": [
                                    {
                                      "color": "#17263c"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "water",
                                  "elementType": "labels.text.fill",
                                  "stylers": [
                                    {
                                      "color": "#515c6d"
                                    }
                                  ]
                                },
                                {
                                  "featureType": "water",
                                  "elementType": "labels.text.stroke",
                                  "stylers": [
                                    {
                                      "color": "#17263c"
                                    }
                                  ]
                                }
                              ]
                            ''');
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSectionTitle('Photos ($validPhotoCount)'),
                  if (validPhotoCount > 0)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.photos.length,
                        itemBuilder: (context, index) {
                          final photo = widget.photos[index];
                          if (photo == null) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photo.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    _buildInfoCard('No photos attached'),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A365D),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                  child: const Text('Back'),
                ),
                SizedBox(
                  width: 150,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF1A365D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text(
                                'Submit Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1A365D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        content,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
