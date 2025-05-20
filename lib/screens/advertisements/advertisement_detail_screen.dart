import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../utils/date_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_advertisement_screen.dart';

class AdvertisementDetailScreen extends StatefulWidget {
  final String advertisementId;
  final bool isAdmin;
  final Function(String, String) onStatusUpdate;

  const AdvertisementDetailScreen({
    Key? key,
    required this.advertisementId,
    this.isAdmin = false,
    required this.onStatusUpdate,
  }) : super(key: key);

  @override
  State<AdvertisementDetailScreen> createState() =>
      _AdvertisementDetailScreenState();
}

class _AdvertisementDetailScreenState extends State<AdvertisementDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PageController _pageController = PageController();
  bool _isLoading = true;
  Map<String, dynamic>? _advertisement;
  GoogleMapController? _mapController;
  bool _isAdvertiser = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _fetchAdvertisement();
    _checkUserType();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAdvertisement() async {
    try {
      final doc = await _firestore
          .collection('advertisements')
          .doc(widget.advertisementId)
          .get();

      if (doc.exists) {
        setState(() {
          _advertisement = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching advertisement: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (mounted) {
        setState(() {
          _isAdvertiser = userDoc.data()?['type'] == 'advertiser';
          _isOwner =
              _advertisement != null && _advertisement!['userId'] == user.uid;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      );
    }

    if (_advertisement == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Advertisement Details'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Advertisement not found'),
        ),
      );
    }

    final imageUrls = List<String>.from(_advertisement!['imageUrls'] ?? []);
    final documentUrl = _advertisement!['documentUrl'] as String?;
    final location = _advertisement!['location'] as Map<String, dynamic>?;
    final createdOn = (_advertisement!['createdOn'] as Timestamp).toDate();

    final LatLng? locationLatLng = location != null
        ? LatLng(
            location['latitude'] as double,
            location['longitude'] as double,
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advertisement Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdvertiser && _isOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF1E293B)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditAdvertisementScreen(
                      advertisementId: widget.advertisementId,
                      advertisement: _advertisement!,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (imageUrls.isNotEmpty)
              Stack(
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Page Indicators
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        imageUrls.length,
                        (index) => StreamBuilder<int>(
                          stream: Stream.periodic(
                            const Duration(milliseconds: 100),
                            (_) => _pageController.hasClients
                                ? _pageController.page?.round() ?? 0
                                : 0,
                          ),
                          builder: (context, snapshot) {
                            final currentPage = snapshot.data ?? 0;
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentPage == index
                                    ? AppTheme.primaryColor
                                    : Colors.white.withOpacity(0.5),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    _advertisement!['name'] ?? 'Untitled Advertisement',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormatter.format(createdOn),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location Map
                  if (locationLatLng != null) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: locationLatLng,
                            zoom: 15,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                          markers: {
                            Marker(
                              markerId:
                                  const MarkerId('advertisement_location'),
                              position: locationLatLng,
                              infoWindow: InfoWindow(
                                title: _advertisement!['name'] ??
                                    'Advertisement Location',
                              ),
                            ),
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Business Information
                  if (documentUrl != null) ...[
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _launchUrl(documentUrl),
                      icon: const Icon(Icons.description),
                      label: const Text('View Document'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],

                  // Admin Approval Buttons
                  if (widget.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => widget.onStatusUpdate(
                                  widget.advertisementId, 'approved'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Approve Advertisement'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => widget.onStatusUpdate(
                                  widget.advertisementId, 'declined'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Decline Advertisement'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
