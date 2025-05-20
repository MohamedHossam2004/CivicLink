import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static String? CLOUDINARY_CLOUD_NAME;
  static String? CLOUDINARY_API_KEY;
  static String? CLOUDINARY_API_SECRET;

  static String? _uploadBaseUrl;

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

    _uploadBaseUrl =
        'https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload';
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

  Future<String?> uploadImage(File imageFile) async {
    if (imageFile.path.isEmpty) {
      print('DEBUG: Skipped photo with empty path.');
      return null;
    }

    if (_uploadBaseUrl == null) {
      print(
          'ERROR: CloudinaryService not initialized properly. _uploadBaseUrl is null.');
      throw Exception(
          "CloudinaryService not initialized properly. _uploadBaseUrl is null.");
    }

    try {
      final uri = Uri.parse(_uploadBaseUrl!);
      var request = http.MultipartRequest('POST', uri);

      final timestamp =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final uuid = const Uuid();
      final publicId = 'report_${uuid.v4()}';

      final Map<String, dynamic> signatureParams = {
        'timestamp': timestamp,
        'public_id': publicId,
      };

      final signature = _generateCloudinarySignature(signatureParams);

      request.fields['timestamp'] = timestamp;
      request.fields['public_id'] = publicId;
      request.fields['api_key'] = CLOUDINARY_API_KEY!;
      request.fields['signature'] = signature;

      final mimeType = lookupMimeType(imageFile.path);
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: '$publicId.${imageFile.path.split('.').last.toLowerCase()}',
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));

      print('DEBUG: Attempting to upload ${imageFile.path} to Cloudinary...');

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);
        final imageUrl = result['secure_url'];

        print('DEBUG: Image uploaded successfully. URL: $imageUrl');
        return imageUrl;
      } else {
        final errorResponse = await response.stream.bytesToString();
        print(
            'ERROR: Cloudinary upload failed: ${response.statusCode} - $errorResponse');
        throw Exception(
            'Cloudinary upload failed: ${response.statusCode} - $errorResponse');
      }
    } catch (e) {
      print('ERROR: General error during image upload: $e');
      rethrow;
    }
  }
}
