import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((error) {
        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.red),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 4 / 5, // A nice default placeholder for feed videos
        child: Container(
          color: Colors.black.withValues(alpha: 0.05),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Facebook-style aspect ratio limit:
    // If video is taller than 4:5 (0.8), crop it to 4:5.
    // Otherwise, show it at its natural aspect ratio.
    double videoRatio = _controller.value.aspectRatio;
    double displayRatio = videoRatio < 0.8 ? 0.8 : videoRatio;

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Container(
        width: double.infinity,
        color: Colors.black, // Dark background for any edge cases
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: displayRatio,
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
            if (!_controller.value.isPlaying)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2.0,
                  ),
                ),
                padding: EdgeInsets.all(14.r),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 40.r,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
