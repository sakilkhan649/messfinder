import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../controllers/marketplace_controller.dart';
import '../models/product_model.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';
import '../../auth/controllers/auth_controller.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MarketplaceController controller = Get.put(MarketplaceController());

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
                    Get.to(() => const AddProductScreen());
                  },
                  icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 26.r),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(132.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Bar
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
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
                    // Categories Horizontal List
                    Container(
                      height: 58.h,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
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
                                  color: isSelected ? (category == 'All' ? accentColor : primaryColor) : Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: isSelected ? (category == 'All' ? accentColor : primaryColor) : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (category == 'All' ? accentColor : primaryColor).withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : [],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? Colors.white : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            
            // Products Grid
            Obx(() {
              if (controller.isLoading.value && controller.products.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                );
              }

              if (controller.hasError.value && controller.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48.r),
                        SizedBox(height: 12.h),
                        Text(
                          controller.errorMessage.value,
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: 12.h),
                        ElevatedButton(
                          onPressed: controller.fetchProducts,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                          child: const Text('Retry'),
                        )
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
                        Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 64.r),
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

              return SliverPadding(
                padding: EdgeInsets.all(16.w),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = constraints.crossAxisExtent > 800 ? 4 : (constraints.crossAxisExtent > 500 ? 3 : 2);
                    double totalSpacing = 16.w * (crossAxisCount - 1);
                    double itemWidth = (constraints.crossAxisExtent - totalSpacing) / crossAxisCount;
                    double itemHeight = 260.h;
                    
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: itemWidth / itemHeight,
                        crossAxisSpacing: 16.w,
                        mainAxisSpacing: 16.h,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return ProductCard(product: controller.products[index]);
                        },
                        childCount: controller.products.length,
                      ),
                    );
                  }
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
                      child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isMyProduct = authController != null && product.sellerUid == authController.currentUser.value?.uid;

    return GestureDetector(
      onTap: () {
        if (!isMyProduct) {
          Get.to(() => ProductDetailsScreen(product: product));
        }
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
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        width: double.infinity,
                        height: double.infinity,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
              ),
            ),
            // Details
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tk ${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  SizedBox(
                    height: 32.sp,
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
                      Icon(Icons.location_on_outlined, size: 12.r, color: AppTheme.textSecondary),
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
                        product.createdAt != null ? timeago.format(product.createdAt!) : '',
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (isMyProduct)
                        PopupMenuButton<String>(
                          child: Icon(Icons.more_horiz, size: 20.r, color: Colors.grey.shade700),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Get.to(() => AddProductScreen(product: product));
                            } else if (value == 'delete') {
                              _confirmDelete(context, product.productId!);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit, color: Colors.blue, size: 20),
                                  SizedBox(width: 8.w),
                                  Text('Edit', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8.w),
                                  Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
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
