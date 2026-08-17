import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String mediaUrl;
  final bool isVideo;

  const MediaPreviewScreen({
    super.key,
    required this.mediaUrl,
    this.isVideo = false,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
              _videoController?.play();
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _downloadMedia() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dio = Dio();
      final ext = widget.isVideo ? 'mp4' : 'jpg';
      final fileName = 'MessFinder_${DateTime.now().millisecondsSinceEpoch}.$ext';

      Directory? dir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          dir = downloadDir;
        } else {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir?.path ?? ''}/$fileName';

      await dio.download(
        widget.mediaUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      Get.snackbar(
        'Downloaded Successfully',
        'Saved to: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF059669),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    } catch (e) {
      Get.snackbar(
        'Download Failed',
        'Could not save media: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        margin: EdgeInsets.all(16.r),
        borderRadius: 12.r,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _shareMedia() async {
    try {
      await SharePlus.instance.share(ShareParams(text: widget.mediaUrl));
    } catch (_) {
      // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.isVideo ? 'Video' : 'Photo',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16.sp),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
            tooltip: 'Share',
            onPressed: _shareMedia,
          ),
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: CircularProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white, size: 24),
            tooltip: 'Download',
            onPressed: _downloadMedia,
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Media View
          if (!widget.isVideo)
            PhotoView(
              imageProvider: NetworkImage(widget.mediaUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Color(0xFF059669)),
              ),
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
              ),
            )
          else if (_isVideoInitialized && _videoController != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      if (!_videoController!.value.isPlaying)
                        Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44.r),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            ),

          // Download Progress Bar
          if (_isDownloading)
            Positioned(
              bottom: 40.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: CircularProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        color: const Color(0xFF059669),
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      'Downloading (${(_downloadProgress * 100).toInt()}%)...',
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
