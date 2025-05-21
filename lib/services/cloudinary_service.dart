import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;

enum CloudinaryResourceType {
  image,
  raw,  // For documents like PDF, DOCX, etc.
  video,
  auto
}

class CloudinaryService {
  static String? CLOUDINARY_CLOUD_NAME;
  static String? CLOUDINARY_API_KEY;
  static String? CLOUDINARY_API_SECRET;

  static Map<CloudinaryResourceType, String> _uploadBaseUrls = {};

  CloudinaryService._privateConstructor() {
    CLOUDINARY_CLOUD_NAME = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    CLOUDINARY_API_KEY = dotenv.env['CLOUDINARY_API_KEY'];
    CLOUDINARY_API_SECRET = dotenv.env['CLOUDINARY_API_SECRET'];

    if (CLOUDINARY_CLOUD_NAME == null || CLOUDINARY_CLOUD_NAME!.isEmpty) {
      throw Exception(
          "CLOUDINARY_CLOUD_NAME not found or empty in .env. Please check your .env file.");
    }
    if (CLOUDINARY_API_KEY == null || CLOUDINARY_API_KEY!.isEmpty) {
      throw Exception(
          "CLOUDINARY_API_KEY not found or empty in .env. Please check your .env file.");
    }
    if (CLOUDINARY_API_SECRET == null || CLOUDINARY_API_SECRET!.isEmpty) {
      throw Exception(
          "CLOUDINARY_API_SECRET not found or empty in .env. Please check your .env file.");
    }

    // Initialize base URLs for different resource types
    _uploadBaseUrls[CloudinaryResourceType.image] = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';
    _uploadBaseUrls[CloudinaryResourceType.raw] = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/raw/upload';
    _uploadBaseUrls[CloudinaryResourceType.video] = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/video/upload';
    _uploadBaseUrls[CloudinaryResourceType.auto] = 'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/auto/upload';
  }

  static final CloudinaryService _instance =
      CloudinaryService._privateConstructor();

  factory CloudinaryService() {
    return _instance;
  }

  String _generateCloudinarySignature(Map<String, dynamic> params) {
    final sortedKeys = params.keys.toList()..sort();
    final paramString =
        sortedKeys.map((key) => '$key=${params[key]}').join('&');

    final toSign = '$paramString$CLOUDINARY_API_SECRET';
    final signature = sha1.convert(utf8.encode(toSign)).toString();
    return signature;
  }

  // Determine resource type based on file extension
  CloudinaryResourceType _determineResourceType(String filepath) {
    final extension = path.extension(filepath).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return CloudinaryResourceType.image;
    } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension)) {
      return CloudinaryResourceType.video;
    } else if (['.pdf', '.doc', '.docx', '.txt', '.csv', '.xls', '.xlsx', '.ppt', '.pptx'].contains(extension)) {
      return CloudinaryResourceType.raw;
    }
    
    return CloudinaryResourceType.auto;
  }

  // Generic method to upload any file
  Future<String?> uploadFile(File file, {CloudinaryResourceType? resourceType, String? folder}) async {
    if (file.path.isEmpty) {
      print('DEBUG: Skipped file with empty path.');
      return null;
    }

    // Determine resource type if not specified
    resourceType ??= _determineResourceType(file.path);
    
    final baseUrl = _uploadBaseUrls[resourceType];
    if (baseUrl == null) {
      print('ERROR: Invalid resource type $resourceType');
      throw Exception("Invalid resource type $resourceType");
    }

    try {
      final uri = Uri.parse(baseUrl);
      var request = http.MultipartRequest('POST', uri);

      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final uuid = const Uuid();
      final fileName = path.basename(file.path);
      final publicId = '${folder ?? resourceType.toString().split('.').last}_${uuid.v4()}';

      final Map<String, dynamic> signatureParams = {
        'timestamp': timestamp,
        'public_id': publicId,
      };
      
      if (folder != null) {
        signatureParams['folder'] = folder;
      }

      final signature = _generateCloudinarySignature(signatureParams);

      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['api_key'] = CLOUDINARY_API_KEY!;
      request.fields['signature'] = signature;
      
      if (folder != null) {
        request.fields['folder'] = folder;
      }

      final mimeType = lookupMimeType(file.path);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));

      print('DEBUG: Attempting to upload ${file.path} to Cloudinary as ${resourceType.toString()}...');

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);
        final fileUrl = result['secure_url'];

        print('DEBUG: File uploaded successfully. URL: $fileUrl');
        return fileUrl;
      } else {
        final errorResponse = await response.stream.bytesToString();
        print('ERROR: Cloudinary upload failed: ${response.statusCode} - $errorResponse');
        throw Exception('Cloudinary upload failed: ${response.statusCode} - $errorResponse');
      }
    } catch (e) {
      print('ERROR: General error during file upload: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<String?> uploadImage(File imageFile) async {
    return uploadFile(imageFile, resourceType: CloudinaryResourceType.image, folder: 'images');
  }
  
  // Convenience method for documents
  Future<String?> uploadDocument(File documentFile) async {
    return uploadFile(documentFile, resourceType: CloudinaryResourceType.raw, folder: 'documents');
  }
}
