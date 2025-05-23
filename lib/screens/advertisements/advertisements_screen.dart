import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../utils/date_formatter.dart';
import 'advertisement_detail_screen.dart';
import 'create_advertisement_page.dart';
import 'package:path/path.dart' as path;

class AdvertisementsScreen extends StatefulWidget {
  const AdvertisementsScreen({Key? key}) : super(key: key);

  @override
  State<AdvertisementsScreen> createState() => _AdvertisementsScreenState();
}

class _AdvertisementsScreenState extends State<AdvertisementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String? _error;
  final PageController _pageController = PageController();
  bool _isAdvertiser = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchAdvertisements();
    _checkUserType();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkUserType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          _isAdvertiser = userDoc.data()?['type'] == 'advertiser';
          _isAdmin = userDoc.data()?['type'] == 'Admin';
        });
      }
    }
  }

  Future<void> _fetchAdvertisements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch advertisements from Firestore
      final snapshot = await _firestore
          .collection('advertisements')
          .orderBy('createdOn', descending: true)
          .get();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching advertisements: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _updateAdvertisementStatus(String advertisementId, String status) async {
    try {
      await _firestore
          .collection('advertisements')
          .doc(advertisementId)
          .update({'status': status});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Advertisement $status successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advertisements',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAdvertiser)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF1E293B),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAdvertisementPage(),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('advertisements')
            .where('status', isEqualTo: _isAdmin ? null : 'approved')
            .orderBy('createdOn', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          }

          final advertisements = snapshot.data?.docs ?? [];

          if (advertisements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isAdmin ? 'No Advertisements' : 'No Approved Advertisements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isAdmin 
                        ? 'There are currently no advertisements in the system.'
                        : 'There are currently no approved advertisements available.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: advertisements.length,
            itemBuilder: (context, index) {
              final ad = advertisements[index].data() as Map<String, dynamic>;
              final imageUrls = List<String>.from(ad['imageUrls'] ?? []);
              final documentUrl = ad['documentUrl'] as String?;
              final location = ad['location'] as Map<String, dynamic>?;
              final createdOn = (ad['createdOn'] as Timestamp).toDate();
              final status = ad['status'] as String? ?? 'pending';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvertisementDetailScreen(
                            advertisementId: advertisements[index].id,
                            isAdmin: _isAdmin,
                            onStatusUpdate: _updateAdvertisementStatus,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Carousel
                        if (imageUrls.isNotEmpty)
                          Stack(
                            children: [
                              SizedBox(
                                height: 200,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: imageUrls.length,
                                  itemBuilder: (context, imageIndex) {
                                    return ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                      child: Image.network(
                                        imageUrls[imageIndex],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[100],
                                            child: const Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Page Indicators
                              Positioned(
                                bottom: 8,
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
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
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
                              // Title and Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ad['name'] ?? 'Untitled Advertisement',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  if (_isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'approved'
                                            ? Colors.green.withOpacity(0.1)
                                            : status == 'declined'
                                                ? Colors.red.withOpacity(0.1)
                                                : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'approved'
                                              ? Colors.green
                                              : status == 'declined'
                                                  ? Colors.red
                                                  : Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Date and Location Row
                              Row(
                                children: [
                                  // Date
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormatter.format(createdOn),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  // Location
                                  if (location != null)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${location['latitude']}, ${location['longitude']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Document Link
                              if (documentUrl != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                    color: Colors.grey[50],
                                  ),
                                  child: InkWell(
                                    onTap: () => _launchUrl(documentUrl),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getDocumentIcon(documentUrl),
                                          size: 24,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: const Text(
                                            'View Business Document',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.open_in_new,
                                          size: 20,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
