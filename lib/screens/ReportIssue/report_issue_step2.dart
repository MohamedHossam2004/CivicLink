import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gov_app/screens/ReportIssue/report_issue_step3.dart';
import 'package:location/location.dart';

class ReportIssueStep2 extends StatefulWidget {
  final String issueType;
  final String description;

  const ReportIssueStep2({
    Key? key,
    required this.issueType,
    required this.description,
  }) : super(key: key);

  @override
  State<ReportIssueStep2> createState() => _ReportIssueStep2State();
}

class _ReportIssueStep2State extends State<ReportIssueStep2> {
  final TextEditingController _locationController = TextEditingController();
  bool _isMapVisible = false;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    // Call _getCurrentLocation when the screen initializes
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Implement the _getCurrentLocation method
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
            infoWindow: const InfoWindow(title: 'Issue Location'),
          ),
        };

        // Update the location controller with a readable address
        // In a real implementation, you would use reverse geocoding here
        _locationController.text =
            'Current Location (${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)})';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
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
          infoWindow: const InfoWindow(title: 'Issue Location'),
        ),
      };

      // Update location text
      _locationController.text =
          'Selected Location (${tappedPoint.latitude.toStringAsFixed(4)}, ${tappedPoint.longitude.toStringAsFixed(4)})';
    });
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step 2 of 3'),
                    Text('67% Complete'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.67,
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
                    'Where is the issue located?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location input field
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter address or location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implement address search/geocoding
                      if (value.isNotEmpty) {
                        setState(() {
                          _isMapVisible = true;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Map
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
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
                  ),

                  const SizedBox(height: 20),

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
                        onPressed: _selectedLocation == null
                            ? null // Disable button if no location is selected
                            : () {
                                // Navigate to next step
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReportIssueStep3(
                                      issueType: widget.issueType,
                                      description: widget.description,
                                      location: _locationController.text,
                                      coordinates: _selectedLocation,
                                    ),
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 40),
                        ),
                        child: const Text('Next'),
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
