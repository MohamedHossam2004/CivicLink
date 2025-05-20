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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Review Report'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Please review the information below before submitting your report.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
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
                        border: Border.all(color: Colors.grey.shade300),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 45),
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
                      : const Text('Submit Report'),
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
        ),
      ),
    );
  }

  Widget _buildInfoCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(content),
    );
  }
}
