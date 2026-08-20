import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/marketplace_controller.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/profile_avatar_leading.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MarketplaceController controller = Get.find<MarketplaceController>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: () => controller.fetchProducts(isRefresh: true),
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              surfaceTintColor: AppTheme.primaryColor,
              automaticallyImplyLeading: false,
              leading: const ProfileAvatarLeading(),
              title: Text(
                'Marketplace',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20.sp,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    Get.bottomSheet(
                      const AddProductScreen(),
                      isScrollControlled: true,
                    );
                  },
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                    size: 26.r,
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(56.h),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (value) => controller.searchProducts(value),
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: Colors.white,
                      ),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        hintText: 'Search products...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          color: Colors.white70,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white70,
                          size: 20.r,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 16.h),
                child: const PromotionalCarousel(),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                height: 58.h,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Obx(() {
                  final currentCategory = controller.selectedCategory.value;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: controller.categories.length,
                    itemBuilder: (context, index) {
                      final category = controller.categories[index];
                      final isSelected = currentCategory == category;
                      final Color primaryColor = const Color(0xFF059669);
                      final Color accentColor = const Color(0xFFF59E0B);

                      return GestureDetector(
                        onTap: () {
                          controller.setFilters(category: category);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (category == 'All'
                                      ? accentColor
                                      : primaryColor)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected
                                  ? (category == 'All'
                                        ? accentColor
                                        : primaryColor)
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          (category == 'All'
                                                  ? accentColor
                                                  : primaryColor)
                                              .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            // Products Grid
            Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }

              if (controller.hasError.value && controller.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48.r,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          controller.errorMessage.value,
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: controller.fetchProducts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (controller.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.grey,
                          size: 64.r,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No products found.',
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = controller.products;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final chunkIndex = index;
                    final startIndex = chunkIndex * 4;
                    if (startIndex >= products.length) return null;

                    final endIndex = (startIndex + 4) > products.length ? products.length : (startIndex + 4);
                    final chunkProducts = products.sublist(startIndex, endIndex);

                    final isGrid = chunkIndex % 2 == 0;

                    bool showHeader = controller.selectedCategory.value == 'All' || chunkIndex == 0;

                    Widget header = showHeader ? Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chunkProducts.first.category,
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              controller.setFilters(category: chunkProducts.first.category);
                              // Scroll to top if needed, or simply let it refresh
                              controller.scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Text(
                              'See All',
                              style: GoogleFonts.poppins(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ) : SizedBox(height: 8.h);

                    if (isGrid) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
                                double totalSpacing = 16.w * (crossAxisCount - 1);
                                double itemWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;
                                double itemHeight = 260.h;
                                
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: itemWidth / itemHeight,
                                    crossAxisSpacing: 16.w,
                                    mainAxisSpacing: 16.h,
                                  ),
                                  itemCount: chunkProducts.length,
                                  itemBuilder: (context, i) => ProductCard(product: chunkProducts[i]),
                                );
                              }
                            ),
                          ),
                        ],
                      );
                    } else {
                      double screenWidth = MediaQuery.of(context).size.width;
                      double viewportFrac = screenWidth > 800 ? 0.25 : (screenWidth > 500 ? 0.33 : 0.48);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: CarouselSlider.builder(
                              key: ValueKey('carousel_${controller.selectedCategory.value}_$chunkIndex'),
                              itemCount: chunkProducts.length,
                              itemBuilder: (context, i, realIndex) {
                                return Container(
                                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                                  child: ProductCard(product: chunkProducts[i]),
                                );
                              },
                              options: CarouselOptions(
                                height: 260.h,
                                autoPlay: true,
                                autoPlayInterval: const Duration(seconds: 3),
                                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                                autoPlayCurve: Curves.fastOutSlowIn,
                                viewportFraction: viewportFrac,
                                enableInfiniteScroll: chunkProducts.length > (1 / viewportFrac).ceil(),
                                padEnds: false,
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                  childCount: (products.length / 4).ceil(),
                ),
              );
            }),

            // Loading indicator at bottom
            Obx(() {
              if (controller.isLoadingMore.value) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : null;
    final isMyProduct =
        authController != null &&
        product.sellerUid == authController.currentUser.value?.uid;

    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailsScreen(product: product));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        height: double.infinity,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            // Details
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Tk ${product.price.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: product.condition.toLowerCase() == 'new'
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          product.condition.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: product.condition.toLowerCase() == 'new'
                                ? Colors.green
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    height: 40.h,
                    child: Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        height: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12.r,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          '${product.division}, ${product.district}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.createdAt != null
                            ? timeago.format(product.createdAt!)
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (isMyProduct)
                        GestureDetector(
                          onTapDown: (TapDownDetails details) async {
                            final value = await showMenu<String>(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                details.globalPosition.dx -
                                    120, // Forces left boundary
                                details.globalPosition.dy -
                                    100, // Forces top boundary (opens upwards)
                                MediaQuery.of(context).size.width -
                                    details
                                        .globalPosition
                                        .dx, // Anchors right edge to the touch point
                                MediaQuery.of(context).size.height -
                                    details
                                        .globalPosition
                                        .dy, // Anchors bottom edge
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              constraints: const BoxConstraints(maxWidth: 120),
                              items: [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Edit',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Delete',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            if (!context.mounted) return;

                            if (value == 'edit') {
                              Get.to(() => AddProductScreen(product: product));
                            } else if (value == 'delete') {
                              _confirmDelete(context, product.productId!);
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.w, top: 8.h),
                            child: Icon(
                              Icons.more_horiz,
                              size: 20.r,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: () {
                            Get.to(
                              () => ProductDetailsScreen(product: product),
                            );
                          },
                          borderRadius: BorderRadius.circular(4.r),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            child: Text(
                              'Details',
                              style: GoogleFonts.poppins(
                                fontSize: 11.sp,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String productId) {
    Get.defaultDialog(
      title: 'Delete Product',
      titleStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      middleText: 'Are you sure you want to delete this product?',
      middleTextStyle: GoogleFonts.poppins(),
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      cancelTextColor: Colors.grey.shade800,
      onConfirm: () {
        Get.back();
        Get.find<MarketplaceController>().deleteProduct(productId);
      },
    );
  }
}

class PromotionalCarousel extends StatefulWidget {
  const PromotionalCarousel({super.key});

  @override
  State<PromotionalCarousel> createState() => _PromotionalCarouselState();
}

class _PromotionalCarouselState extends State<PromotionalCarousel> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();

    return Obx(() {
      final featuredProducts = controller.products.where((p) => p.images.isNotEmpty).take(5).toList();

      if (featuredProducts.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          CarouselSlider(
            carouselController: _controller,
            options: CarouselOptions(
              height: 160.h,
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.85,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
            items: featuredProducts.map((product) => GestureDetector(
              onTap: () {
                Get.to(() => ProductDetailsScreen(product: product));
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12.r)),
                  child: Stack(
                    children: <Widget>[
                      CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) => Container(color: Colors.grey.shade200),
                      ),
                      Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: 0.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromARGB(200, 0, 0, 0),
                                Color.fromARGB(0, 0, 0, 0)
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 10.h, horizontal: 20.w),
                          child: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: featuredProducts.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => _controller.animateToPage(entry.key),
                child: Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.primaryColor)
                        .withValues(alpha: _current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    });
  }
}
