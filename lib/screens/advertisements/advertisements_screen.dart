import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../utils/date_formatter.dart';
import 'advertisement_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchAdvertisements();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('advertisements')
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
                    'No Advertisements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There are currently no advertisements available.',
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
                              // Title
                              Text(
                                ad['name'] ?? 'Untitled Advertisement',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
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
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _launchUrl(documentUrl),
                                    icon: const Icon(Icons.description),
                                    label:
                                        const Text('View Business Information'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
