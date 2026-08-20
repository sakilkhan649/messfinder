import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_theme.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../../chat/views/chat_screen.dart';
import '../models/product_model.dart';
import '../controllers/marketplace_controller.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final isOwner = authController.currentUser.value?.uid == product.sellerUid;
    final RxInt currentImageIndex = 0.obs;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Premium Sliver App Bar
          SliverAppBar(
            expandedHeight: 280.h,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.all(8.r),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
            actions: [
              if (isOwner)
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                      onPressed: () => Get.to(() => AddProductScreen(product: product)),
                    ),
                  ),
                ),
              if (isOwner)
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(context, product),
                    ),
                  ),
                ),
              SizedBox(width: 8.w),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Slider
                  product.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: product.images.length,
                          onPageChanged: (index) {
                            currentImageIndex.value = index;
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: product.images[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                              errorWidget: (context, url, error) => Container(color: Colors.grey.shade100, child: const Icon(Icons.error, color: Colors.grey)),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(Icons.shopping_bag_outlined, size: 80.r, color: Colors.grey.shade400),
                        ),
                  // Gradient Overlay for smooth transition to content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100.h,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Dots Indicator
                  if (product.images.length > 1)
                    Positioned(
                      bottom: 24.h,
                      left: 0,
                      right: 0,
                      child: Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          product.images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            width: currentImageIndex.value == index ? 24.w : 8.w,
                            height: 6.h,
                            decoration: BoxDecoration(
                              color: currentImageIndex.value == index ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3.r),
                            ),
                          ),
                        ),
                      )),
                    ),
                ],
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      product.title,
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    // Price and Condition Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Tk ${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: product.condition == 'new' 
                                ? AppTheme.primaryColor.withValues(alpha: 0.1) 
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.condition == 'new' ? Icons.new_releases_rounded : Icons.history_rounded, 
                                size: 14.r, 
                                color: product.condition == 'new' ? AppTheme.primaryColor : Colors.orange,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                product.condition.capitalizeFirst ?? 'Used',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: product.condition == 'new' ? AppTheme.primaryColor : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    
                    // Location & Time Card
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 16.r),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${product.division}, ${product.district}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                if (product.createdAt != null)
                                  Text(
                                    'Posted ${timeago.format(product.createdAt!)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.sp,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    Divider(color: Colors.grey.shade100, thickness: 1.5),
                    SizedBox(height: 12.h),
                    
                    // Category
                    Text('Category', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    SizedBox(height: 8.h),
                    _buildCategoryChip(product.category),
                    
                    SizedBox(height: 16.h),
                    
                    // Description
                    Text('Description', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    SizedBox(height: 8.h),
                    Text(
                      product.description.isEmpty ? 'No description provided.' : product.description,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp, 
                        color: AppTheme.textSecondary, 
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: 16.h),
                    Divider(color: Colors.grey.shade100, thickness: 1.5),
                    SizedBox(height: 12.h),
                    
                    // Seller Profile
                    Text('Seller Information', style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26.r,
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                            backgroundImage: product.sellerImage != null && product.sellerImage!.isNotEmpty
                                ? NetworkImage(product.sellerImage!)
                                : null,
                            child: product.sellerImage == null || product.sellerImage!.isEmpty
                                ? Icon(Icons.person, color: AppTheme.primaryColor, size: 28.r)
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.sellerName ?? 'Unknown User',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15.sp, 
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                if (product.sellerPhone != null && product.sellerPhone!.isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.phone_rounded, size: 12.r, color: AppTheme.textSecondary),
                                      SizedBox(width: 4.w),
                                      Text(
                                        product.sellerPhone!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.sp, 
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
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
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isOwner 
        ? null 
        : Container(
            padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h, top: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () async {
                  final chatCtrl = Get.find<ChatController>();
                  final chatId = await chatCtrl.createOrGetChatRoom(
                      product.sellerUid, product.sellerName ?? 'Seller', product.sellerImage);
                  Get.to(() => ChatScreen(
                      chatRoomId: chatId,
                      targetUserId: product.sellerUid,
                      targetUserName: product.sellerName ?? 'Seller',
                      targetUserPhoto: product.sellerImage));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      'Message Seller',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.category_rounded, size: 14.r, color: AppTheme.primaryColor),
          SizedBox(width: 6.w),
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete Product', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this product?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final ctrl = Get.find<MarketplaceController>();
              bool success = await ctrl.deleteProduct(product.productId!);
              if (success) {
                Get.back(); // Go back to marketplace list
                Get.snackbar('Success', 'Product deleted');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
