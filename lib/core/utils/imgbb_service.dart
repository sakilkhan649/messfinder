import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'app_logger.dart';

class ImgbbService {
  static const String _apiKey = '7dc645a72f0ce2d1d47497a1af02f620'; 
  final Uuid _uuid = const Uuid();

  /// Compresses and uploads an image to ImgBB
  /// Returns the direct image URL if successful, otherwise null
  Future<String?> uploadImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('File does not exist: $filePath', null, null, 'IMGBB_SVC');
        return null;
      }

      // 1. Compress Image (Important to keep upload fast)
      final compressedFile = await _compressImage(file);
      if (compressedFile == null) {
        return null;
      }

      // 2. Upload to ImgBB
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
      );
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
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

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        String downloadUrl = jsonResponse['data']['url'];
        AppLogger.s('ImgBB Upload Success: $downloadUrl', tag: 'IMGBB_SVC');
        return downloadUrl;
      } else {
        AppLogger.e('ImgBB Upload Failed: ${jsonResponse['error']?['message']}', null, null, 'IMGBB_SVC');
        return null;
      }

    } catch (e) {
      AppLogger.e('Failed to upload image to ImgBB: $e', e, null, 'IMGBB_SVC');
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
