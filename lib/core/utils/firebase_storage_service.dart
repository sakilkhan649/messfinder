import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'app_logger.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Compresses and uploads an image to Firebase Storage
  /// Returns the download URL if successful, otherwise null
  Future<String?> uploadPostImage(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('File does not exist: $filePath', null, null, 'STORAGE_SVC');
        return null;
      }

      // 1. Compress Image
      final compressedFile = await _compressImage(file);
      if (compressedFile == null) {
        return null;
      }

      // 2. Generate unique file name
      final String fileName = '${_uuid.v4()}.jpg';
      final Reference ref = _storage.ref().child('mess_images').child(fileName);

      // 3. Upload to Firebase Storage
      final UploadTask uploadTask = ref.putFile(compressedFile);
      final TaskSnapshot snapshot = await uploadTask;

      // 4. Get Download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up compressed temp file if it's not the original
      if (compressedFile.path != file.path && compressedFile.existsSync()) {
        compressedFile.deleteSync();
      }

      return downloadUrl;
    } catch (e) {
      AppLogger.e('Failed to upload image: $e', e, null, 'STORAGE_SVC');
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
      // Fallback to original file if compression fails
      return file;
    } catch (e) {
      AppLogger.e('Image compression failed: $e', e, null, 'STORAGE_SVC');
      return file; // Return original file as fallback
    }
  }

  /// Uploads a video to Firebase Storage
  /// Returns the download URL if successful, otherwise null
  Future<String?> uploadVideo(String filePath) async {
    try {
      final File file = File(filePath);
      if (!file.existsSync()) {
        AppLogger.e('File does not exist: $filePath', null, null, 'STORAGE_SVC');
        return null;
      }

      // 1. Generate unique file name
      final String fileName = '${_uuid.v4()}.mp4';
      final Reference ref = _storage.ref().child('chat_videos').child(fileName);

      // 2. Upload to Firebase Storage
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final TaskSnapshot snapshot = await uploadTask;

      // 3. Get Download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      AppLogger.e('Failed to upload video: $e', e, null, 'STORAGE_SVC');
      return null;
    }
  }
}
