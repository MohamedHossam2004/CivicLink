import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileUploadWidget extends StatefulWidget {
  final List<File> imageFiles;
  final File? documentFile;
  final Function(List<File>) onImagesSelected;
  final Function(File?) onDocumentSelected;
  final bool allowMultipleImages;
  final List<String>? allowedDocumentExtensions;
  final String? documentLabel;

  const FileUploadWidget({
    Key? key,
    required this.imageFiles,
    this.documentFile,
    required this.onImagesSelected,
    required this.onDocumentSelected,
    this.allowMultipleImages = false,
    this.allowedDocumentExtensions = const [
      'pdf', 'doc', 'docx', 'txt', 'csv', 'xls', 'xlsx'
    ],
    this.documentLabel = 'Supporting Document',
  }) : super(key: key);

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      List<XFile> selectedImages = [];
      
      if (widget.allowMultipleImages) {
        selectedImages = await _imagePicker.pickMultiImage();
      } else {
        final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          selectedImages = [image];
        }
      }
      
      if (selectedImages.isNotEmpty) {
        final newImages = selectedImages.map((image) => File(image.path)).toList();
        
        if (widget.allowMultipleImages) {
          final updatedImages = [...widget.imageFiles, ...newImages];
          widget.onImagesSelected(updatedImages);
        } else {
          widget.onImagesSelected(newImages);
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        final newImage = File(image.path);
        if (widget.allowMultipleImages) {
          final updatedImages = [...widget.imageFiles, newImage];
          widget.onImagesSelected(updatedImages);
        } else {
          widget.onImagesSelected([newImage]);
        }
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedDocumentExtensions,
      );
      
      if (result != null) {
        final File file = File(result.files.single.path!);
        widget.onDocumentSelected(file);
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<File>.from(widget.imageFiles);
    updatedImages.removeAt(index);
    widget.onImagesSelected(updatedImages);
  }

  void _removeDocument() {
    widget.onDocumentSelected(null);
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Images section
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        
        // Image preview grid or empty state
        if (widget.imageFiles.isEmpty) 
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 56,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to add images',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recommended size: 1200 x 800 px',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else 
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.imageFiles.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Container(
                        width: 144,
                        height: 144,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            widget.imageFiles[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Image selection buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: Text(widget.imageFiles.isEmpty ? 'Select Images' : 'Add More Images'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Document section
        Text(
          widget.documentLabel ?? 'Supporting Document',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        
        // Document preview or empty state
        if (widget.documentFile == null)
          GestureDetector(
            onTap: _pickDocument,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 48,
                    color: Theme.of(context).primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload document',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, DOC, DOCX, XLS, XLSX, etc.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[50],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentIcon(widget.documentFile!.path),
                    size: 36,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.basename(widget.documentFile!.path),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFileSize(widget.documentFile!),
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _removeDocument,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Remove', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        if (widget.documentFile == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        else 
          OutlinedButton.icon(
            onPressed: _pickDocument,
            icon: const Icon(Icons.change_circle_outlined),
            label: const Text('Change Document'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
      ],
    );
  }
  
  IconData _getDocumentIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      case '.csv':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
} 