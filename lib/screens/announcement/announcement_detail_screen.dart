import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import '../../services/content_moderation_service.dart';
import '../../utils/date_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_announcement_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final AnnouncementService _service = AnnouncementService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  bool _isHelpful = false;
  bool _isAnonymous = false;
  bool _isAdmin = false;
  bool _isAdvertiser = false;

  @override
  void initState() {
    super.initState();
    _checkUserType();
  }

  Future<void> _checkUserType() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        // Refresh token to ensure we have the latest permissions
        await user.getIdToken(true);
        
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        final userType = userDoc.data()?['type'];
        print('User type: $userType');

        if (mounted) {
          setState(() {
            // Check for both lowercase and uppercase variants for better compatibility
            _isAdmin = userType == 'admin' || userType == 'Admin';
            _isAdvertiser = userType == 'advertiser' || userType == 'Advertiser';
          });
        }
      } catch (e) {
        print('Error checking user type: $e');
      }
    }
  }

  Future<void> _deleteAnnouncement() async {
    try {
      // Refresh token to ensure we have the latest permissions
      final user = _authService.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to delete announcements')),
        );
        return;
      }
      
      try {
        await user.getIdToken(true);
      } catch (e) {
        print('Error refreshing token: $e');
        // Continue anyway as this is just a precaution
      }
      
      // Show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Announcement'),
            content: const Text(
                'Are you sure you want to delete this announcement? This action cannot be undone.'),
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

      // Check if user is admin one more time
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userType = userDoc.data()?['type'];
      if (userType != 'admin' && userType != 'Admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only admins can delete announcements')),
        );
        return;
      }

      await _service.deleteAnnouncement(widget.announcementId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement deleted successfully')),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      print('Error deleting announcement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting announcement: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a comment')),
      );
      return;
    }

    _service.addComment(
      widget.announcementId,
      user.uid,
      commentText,
      isAnonymous: _isAnonymous,
    );
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  void _likeComment(String commentId) {
    _service.likeComment(commentId);
  }

  void _toggleHelpful() {
    setState(() {
      _isHelpful = !_isHelpful;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(_isHelpful ? 'Marked as helpful' : 'Removed from helpful')),
    );
  }

  void _toggleThanks() {
    setState(() {
      _isLiked = !_isLiked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isLiked ? 'Thanks added' : 'Thanks removed')),
    );
  }

  void _toggleSave() async {
    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save announcements')),
      );
      return;
    }

    try {
      // Get current saved status
      final isSaved =
          await _service.isAnnouncementSaved(widget.announcementId).first;

      if (isSaved) {
        // Unsave the announcement
        await _service.unsaveAnnouncement(widget.announcementId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement removed from saved')),
        );
      } else {
        // Save the announcement
        await _service.saveAnnouncement(widget.announcementId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement saved')),
        );
      }
    } catch (e) {
      print('Error toggling save status: $e');

      // Show a more informative error message
      final errorMessage = e.toString().contains('permission-denied')
          ? 'Permission denied. You may not have access to save announcements.'
          : 'Error saving announcement. Please try again later.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StreamBuilder<Announcement?>(
                      stream: _service
                          .getAnnouncementById(widget.announcementId)
                          .asStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return EditAnnouncementScreen(
                            announcementId: widget.announcementId,
                            announcement: snapshot.data!,
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteAnnouncement,
            ),
          ],
          if (!_isAdmin && !_isAdvertiser)
            StreamBuilder<bool>(
              stream: _service.isAnnouncementSaved(widget.announcementId),
              builder: (context, snapshot) {
                final isSaved = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.yellow : Colors.white,
                  ),
                  onPressed: _toggleSave,
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<Announcement?>(
        stream: _service.getAnnouncementById(widget.announcementId).asStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ));
          }

          final announcement = snapshot.data;
          if (announcement == null) {
            return const Center(child: Text('Announcement not found'));
          }

          // Get the image URLs directly from the announcement model
          final List<String> imageUrls = announcement.imageUrls;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Image Carousel
                    if (imageUrls.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          height: 250,
                          child: Stack(
                            children: [
                              PageView.builder(
                                itemCount: imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 20,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8B5CF6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    announcement.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Date
                            Text(
                              announcement.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormatter.formatWithTime(announcement.createdOn),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.business,
                                  size: 16,
                                  color: Color(0xFF8B5CF6),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  announcement.department,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Time Period
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF8B5CF6).withOpacity(0.1),
                                    const Color(0xFF6366F1).withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                                    child: const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'From: ${DateFormatter.formatWithTime(announcement.startTime)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'To: ${DateFormatter.formatWithTime(announcement.endTime)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Main content box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    offset: const Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Description
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    announcement.description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            _buildContactInfo(announcement),
                            const SizedBox(height: 20),
                            _buildActionButtons(),
                            const Divider(height: 32),
                            _buildCommentsSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isAdmin && !_isAdvertiser)
                CommentInputWidget(announcementId: widget.announcementId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactInfo(Announcement announcement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          // Phone
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      announcement.phone,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Email
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.email,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      announcement.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Document
          if (announcement.documentUrl != null && announcement.documentUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () => _launchUrl(announcement.documentUrl!),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getDocumentIcon(announcement.documentUrl!),
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Document',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _getDocumentTypeName(announcement.documentUrl!),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new,
                      color: Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
          return 'Document';
      }
    } catch (e) {
      print('Error getting document type: $e');
      return 'Document';
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!_isAdmin && !_isAdvertiser) ...[
          _buildActionButton(
            icon: Icons.thumb_up_outlined,
            label: 'Helpful',
            isActive: _isHelpful,
            onTap: _toggleHelpful,
          ),
          _buildActionButton(
            icon: Icons.favorite_outline,
            label: 'Thanks',
            isActive: _isLiked,
            onTap: _toggleThanks,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.red : Colors.grey.shade700,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.red : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return StreamBuilder<List<Comment>>(
      stream: _service.getCommentsForAnnouncement(widget.announcementId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final comments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comments (${comments.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (comments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: comments.length,
                separatorBuilder: (context, index) => const Divider(height: 32),
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildCommentItem(comment);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                comment.isAnonymous ? 'A' : comment.displayName.substring(0, 1),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatWithTime(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          _likeComment(comment.id);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                comment.likesCount.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {
                          // TODO: Implement reply functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Reply functionality not implemented')),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CommentInputWidget extends StatefulWidget {
  final String announcementId;

  const CommentInputWidget({
    super.key,
    required this.announcementId,
  });

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AnnouncementService _service = AnnouncementService();
  final AuthService _authService = AuthService();
  final ContentModerationService _moderationService =
      ContentModerationService();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // No need to initialize the moderation service here
    // It's now initialized in main.dart
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a comment')),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Check if comment is hateful - using custom model or built-in moderation
      final isHateful = await _moderationService
          .isCommentHatefulUsingCustomModel(commentText);

      if (isHateful) {
        // Comment is hateful, show alert and don't submit
        await _moderationService.showHatefulContentAlert(context);
      } else {
        // Comment is not hateful, proceed with submission
        await _service.addComment(
          widget.announcementId,
          user.uid,
          commentText,
          isAnonymous: _isAnonymous,
        );

        _commentController.clear();
        _focusNode.unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted successfully')),
        );
      }
    } catch (e) {
      // Show error if something went wrong
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting comment: $e')),
      );
    } finally {
      // Hide loading indicator
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value ?? false;
                  });
                },
              ),
              const Text('Post as Anonymous'),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Add Your Comment',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    : const Text('Post Comment'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
