import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../config/theme.dart';
import '../../utils/date_formatter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_advertisement_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

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

  Future<void> _deleteAdvertisement() async {
    try {
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Advertisement'),
            content: const Text(
                'Are you sure you want to delete this advertisement? This action cannot be undone.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;

      setState(() {
        _isLoading = true;
      });

      // Note: We don't need to delete images from Firebase Storage anymore
      // as we're using Cloudinary for image storage
      
      // Delete document from Firestore
      await _firestore
          .collection('advertisements')
          .doc(widget.advertisementId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Advertisement deleted successfully')),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting advertisement: $e')),
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

  IconData _getDocumentIcon(String documentUrl) {
    try {
      // Extract filename from Cloudinary URL
      Uri uri = Uri.parse(documentUrl);
      String filename = uri.pathSegments.last;
      
      // Check if there's a format/extension in the URL params
      String format = '';
      if (uri.queryParameters.containsKey('format')) {
        format = uri.queryParameters['format']!.toLowerCase();
      } else {
        // Try to extract extension from filename
        final extensionIndex = filename.lastIndexOf('.');
        if (extensionIndex != -1 && extensionIndex < filename.length - 1) {
          format = filename.substring(extensionIndex + 1).toLowerCase();
        }
      }
      
      // Determine icon based on format
      switch (format) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
        case 'csv':
          return Icons.table_chart;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow;
        case 'txt':
          return Icons.text_snippet;
        default:
          return Icons.insert_drive_file;
      }
    } catch (e) {
      print('Error getting document icon: $e');
      return Icons.insert_drive_file;
    }
  }

  String _getDocumentTypeName(String documentUrl) {
    try {
      // Extract filename from Cloudinary URL
      Uri uri = Uri.parse(documentUrl);
      String filename = uri.pathSegments.last;
      
      // Check if there's a format in the URL params
      String format = '';
      if (uri.queryParameters.containsKey('format')) {
        format = uri.queryParameters['format']!.toLowerCase();
      } else {
        // Try to extract extension from filename
        final extensionIndex = filename.lastIndexOf('.');
        if (extensionIndex != -1 && extensionIndex < filename.length - 1) {
          format = filename.substring(extensionIndex + 1).toLowerCase();
        }
      }
      
      // Determine document type based on format
      switch (format) {
        case 'pdf':
          return 'PDF Document';
        case 'doc':
        case 'docx':
          return 'Word Document';
        case 'xls':
        case 'xlsx':
          return 'Excel Spreadsheet';
        case 'csv':
          return 'CSV File';
        case 'ppt':
        case 'pptx':
          return 'PowerPoint Presentation';
        case 'txt':
          return 'Text Document';
        default:
          return 'Business Document';
      }
    } catch (e) {
      print('Error getting document type: $e');
      return 'Business Document';
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
          if (_isAdvertiser && _isOwner) ...[
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
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteAdvertisement,
            ),
          ],
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteAdvertisement,
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

                  // Phone Number
                  if (_advertisement!['phoneNumber'] != null) ...[
                    const Text(
                      'Contact',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        final phoneNumber = _advertisement!['phoneNumber'];
                        if (phoneNumber != null && phoneNumber.isNotEmpty) {
                          launchUrl(Uri.parse('tel:$phoneNumber'));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              _advertisement!['phoneNumber'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Call',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.grey[50],
                      ),
                      child: InkWell(
                        onTap: () => _launchUrl(documentUrl),
                        child: Row(
                          children: [
                            Icon(
                              _getDocumentIcon(documentUrl),
                              size: 36,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getDocumentTypeName(documentUrl),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    'Tap to view document',
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new,
                              color: AppTheme.primaryColor,
                            ),
                          ],
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
