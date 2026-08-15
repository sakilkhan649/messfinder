import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'app_logger.dart';

// Note: Keeping the class name ImgbbService to avoid renaming across all controllers,
// but it now uses Cloudinary internally for fast, free, and unblocked image hosting.
class ImgbbService {
  final Uuid _uuid = const Uuid();
  
  static const String _cloudinaryCloudName = 'xtdzn8zq'; 
  static const String _uploadPreset = 'messfinder_preset';

  /// Compresses and uploads an image to Cloudinary
  /// Returns the direct image URL if successful, otherwise null
  Future<String?> uploadImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('File does not exist: $filePath', null, null, 'CLOUDINARY_SVC');
        return null;
      }

      // 1. Compress Image (Important to keep upload fast)
      final compressedFile = await _compressImage(file);
      if (compressedFile == null) {
        return null;
      }

      // 2. Upload to Cloudinary via Unsigned POST request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload'),
      );
      
      request.fields['upload_preset'] = _uploadPreset;
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          compressedFile.path,
        ),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      // Clean up compressed temp file if it's not the original
      if (compressedFile.path != file.path && compressedFile.existsSync()) {
        compressedFile.deleteSync();
      }

      if (response.statusCode == 200 && jsonResponse['secure_url'] != null) {
        String downloadUrl = jsonResponse['secure_url'];
        AppLogger.s('Cloudinary Upload Success: $downloadUrl', tag: 'CLOUDINARY_SVC');
        return downloadUrl;
      } else {
        AppLogger.e('Cloudinary Upload Failed: ${jsonResponse['error']?['message']}', null, null, 'CLOUDINARY_SVC');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.e('Failed to upload image to Cloudinary: $e', e, stackTrace, 'CLOUDINARY_SVC');
      return null;
    }
  }

  /// Compresses the image and returns a temporary file
  Future<File?> _compressImage(File file) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(tempDir.path, '${_uuid.v4()}_compressed.jpg');

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed != null) {
        return File(compressed.path);
      }
      return file;
    } catch (e) {
      AppLogger.e('Image compression failed: $e', e, null, 'IMGBB_SVC');
      return file; 
    }
  }
}
