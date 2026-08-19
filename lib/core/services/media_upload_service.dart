import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';
import 'api_service.dart';

/// Uploads images and videos to our own Node.js backend server.
/// Files are compressed, stored in backend/uploads/ and served as static files.
class MediaUploadService {
  final Uuid _uuid = const Uuid();

  /// Compresses and uploads a single image to the backend.
  /// Returns the public URL on success, null on failure.
  Future<String?> uploadImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('File does not exist: $filePath', null, null, 'MEDIA_UPLOAD');
        return null;
      }

      // Compress before upload
      final compressedFile = await _compressImage(file);
      final fileToUpload = compressedFile ?? file;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          fileToUpload.path,
          filename: '${_uuid.v4()}.jpg',
        ),
      });

      final dio = ApiService().dio;
      final response = await dio.post('/upload', data: formData);

      // Clean up temp compressed file
      if (compressedFile != null &&
          compressedFile.path != file.path &&
          compressedFile.existsSync()) {
        compressedFile.deleteSync();
      }

      if (response.statusCode == 200 && response.data['url'] != null) {
        final url = response.data['url'] as String;
        AppLogger.s('Upload success: $url', tag: 'MEDIA_UPLOAD');
        return url;
      }

      AppLogger.e('Upload failed: ${response.data}', null, null, 'MEDIA_UPLOAD');
      return null;
    } catch (e, stack) {
      AppLogger.e('Upload exception: $e', e, stack, 'MEDIA_UPLOAD');
      return null;
    }
  }

  /// Compresses and uploads multiple images to the backend.
  /// Returns a map with 'urls' containing a list of strings on success.
  static Future<Map<String, dynamic>?> uploadMultipleImages(List<File> files) async {
    try {
      final service = MediaUploadService();
      final List<MultipartFile> multipartFiles = [];
      final List<File> tempFiles = [];

      for (var file in files) {
        if (!file.existsSync()) continue;
        
        final ext = path.extension(file.path).toLowerCase();
        final isVideo = ext == '.mp4' || ext == '.mov' || ext == '.avi' || ext == '.mkv';
        
        File fileToUpload = file;
        if (!isVideo) {
          final compressedFile = await service._compressImage(file);
          if (compressedFile != null) {
            fileToUpload = compressedFile;
            tempFiles.add(compressedFile);
          }
        }

        final uploadExt = isVideo ? ext : '.jpg';

        multipartFiles.add(await MultipartFile.fromFile(
          fileToUpload.path,
          filename: '${service._uuid.v4()}$uploadExt',
        ));
      }

      if (multipartFiles.isEmpty) return null;

      final formData = FormData.fromMap({
        'files': multipartFiles,
      });

      final dio = ApiService().dio;
      final response = await dio.post('/upload/multiple', data: formData);

      // Clean up temp compressed files
      for (var tempFile in tempFiles) {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      }

      if (response.statusCode == 200 && response.data['urls'] != null) {
        final List<dynamic> rawUrls = response.data['urls'];
        final List<String> stringUrls = rawUrls.map((e) => e['url'] as String).toList();
        AppLogger.s('Multiple upload success: $stringUrls', tag: 'MEDIA_UPLOAD');
        return {'urls': stringUrls};
      }

      AppLogger.e('Multiple upload failed: ${response.data}', null, null, 'MEDIA_UPLOAD');
      return null;
    } catch (e, stack) {
      AppLogger.e('Multiple upload exception: $e', e, stack, 'MEDIA_UPLOAD');
      return null;
    }
  }

  /// Uploads a video file to the backend.
  Future<String?> uploadVideo(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('Video file does not exist: $filePath', null, null, 'MEDIA_UPLOAD');
        return null;
      }

      final ext = path.extension(filePath).isNotEmpty ? path.extension(filePath) : '.mp4';
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: '${_uuid.v4()}$ext',
        ),
      });

      final dio = ApiService().dio;
      final response = await dio.post('/upload', data: formData);

      if (response.statusCode == 200 && response.data['url'] != null) {
        final url = response.data['url'] as String;
        AppLogger.s('Video upload success: $url', tag: 'MEDIA_UPLOAD');
        return url;
      }

      AppLogger.e('Video upload failed: ${response.data}', null, null, 'MEDIA_UPLOAD');
      return null;
    } catch (e, stack) {
      AppLogger.e('Video upload exception: $e', e, stack, 'MEDIA_UPLOAD');
      return null;
    }
  }

  /// Compresses the image and returns a temporary File.
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

      if (compressed != null) return File(compressed.path);
      return null;
    } catch (e) {
      AppLogger.e('Image compression failed: $e', e, null, 'MEDIA_UPLOAD');
      return null;
    }
  }
}
