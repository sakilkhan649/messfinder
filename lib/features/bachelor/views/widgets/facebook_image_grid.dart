import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_helper.dart';

class FacebookImageGrid extends StatelessWidget {
  final List<String> images;
  final double height;
  final double borderRadius;

  const FacebookImageGrid({
    super.key,
    required this.images,
    this.height = 200,
    this.borderRadius = 0,
  });

  void _openGallery(BuildContext context, int initialIndex) {
    Get.to(
      () => _FullScreenGallery(
        images: images,
        initialIndex: initialIndex,
      ),
      transition: Transition.fadeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        height: height.h,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48.r,
          color: Colors.grey.shade400,
        ),
      );
    }

    Widget content;

    if (images.length == 1) {
      content = GestureDetector(
        onTap: () => _openGallery(context, 0),
        child: AppImageHelper.buildImage(
          images[0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (images.length == 2) {
      content = Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openGallery(context, 0),
              child: AppImageHelper.buildImage(
                images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: GestureDetector(
              onTap: () => _openGallery(context, 1),
              child: AppImageHelper.buildImage(
                images[1],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ],
      );
    } else if (images.length == 3) {
      content = Column(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openGallery(context, 0),
              child: AppImageHelper.buildImage(
                images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 1),
                    child: AppImageHelper.buildImage(
                      images[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 2),
                    child: AppImageHelper.buildImage(
                      images[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 or more images
      content = Column(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => _openGallery(context, 0),
              child: AppImageHelper.buildImage(
                images[0],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 1),
                    child: AppImageHelper.buildImage(
                      images[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 2),
                    child: AppImageHelper.buildImage(
                      images[2],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGallery(context, 3),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImageHelper.buildImage(
                          images[3],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (images.length > 4)
                          Container(
                            color: Colors.black.withValues(alpha: 0.5),
                            alignment: Alignment.center,
                            child: Text(
                              '+${images.length - 4}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: borderRadius > 0
          ? BorderRadius.vertical(top: Radius.circular(borderRadius))
          : BorderRadius.zero,
      child: SizedBox(
        height: height.h,
        width: double.infinity,
        child: content,
      ),
    );
  }
}

class _FullScreenGallery extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    final RxInt currentIndex = initialIndex.obs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Obx(() => Text(
          '${currentIndex.value + 1} of ${images.length}',
          style: const TextStyle(color: Colors.white),
        )),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            // Removed heroAttributes to prevent "Multiple heroes share the same tag" crashes
            // when the same post appears in multiple places in the app.
          );
        },
        itemCount: images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        pageController: PageController(initialPage: initialIndex),
        onPageChanged: (int index) {
          currentIndex.value = index;
        },
      ),
    );
  }
}
