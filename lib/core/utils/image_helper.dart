import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppImageHelper {
  static Widget buildImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade300,
        child: const Icon(Icons.home_work_rounded, color: Colors.grey),
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: 400, // Optimize memory usage
        memCacheHeight: 400, // Optimize memory usage
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
        ),
      );
    } else {
      return Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
        ),
      );
    }
  }
}
