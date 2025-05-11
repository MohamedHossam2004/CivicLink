import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gov_app/screens/ReportIssue/report_preview.dart';
import 'package:image_picker/image_picker.dart';

class ReportIssueStep3 extends StatefulWidget {
  final String issueType;
  final String description;
  final String location;
  final LatLng? coordinates;

  const ReportIssueStep3({
    Key? key,
    required this.issueType,
    required this.description,
    required this.location,
    this.coordinates,
  }) : super(key: key);

  @override
  State<ReportIssueStep3> createState() => _ReportIssueStep3State();
}

class _ReportIssueStep3State extends State<ReportIssueStep3> {
  final List<XFile?> _photos = [null, null, null]; // Three photo slots
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _photos[index] = image;
      });
    }
  }

  void _previewReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreview(
          issueType: widget.issueType,
          description: widget.description,
          location: widget.location,
          coordinates: widget.coordinates,
          photos: _photos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report an Issue'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Step 3 of 3'),
                    Text('100% Complete'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: Colors.grey[200],
                  color: Colors.green,
                  minHeight: 5,
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add photos of the issue (optional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Photo grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return GestureDetector(
                        onTap: () => _pickImage(index),
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _photos[index] != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photos[index]!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                              : index == 2
                              ? const Icon(
                            Icons.camera_alt,
                            color: Colors.grey,
                            size: 32,
                          )
                              : null,
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // Navigation buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: _previewReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(120, 40),
                        ),
                        child: const Text('Review Report'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
