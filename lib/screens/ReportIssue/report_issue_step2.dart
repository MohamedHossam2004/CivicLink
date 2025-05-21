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
      backgroundColor: const Color(0xFF1A365D),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report an Issue',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A365D),
        foregroundColor: Colors.white,
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
                    const Text('Step 2 of 3',
                        style: TextStyle(color: Colors.white)),
                    const Text('67% Complete',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF1A365D)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: LinearProgressIndicator(
                    value: 0.67,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.transparent),
                    minHeight: 5,
                  ),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location input field
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter address or location',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1E3A8A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    onChanged: (value) {
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
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
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
                                  // Set dark map style
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
                                onTap: _handleMapTap,
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('Back'),
                      ),
                      SizedBox(
                        width: 120,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
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
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
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
                                'Next',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
