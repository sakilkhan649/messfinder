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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () {
                Get.to(() => AddProductScreen(product: product));
              },
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider / Header Image
            SizedBox(
              height: 250.h,
              width: double.infinity,
              child: product.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: product.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: product.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Icon(Icons.image_not_supported, size: 64.r, color: Colors.grey),
                    ),
            ),
            
            // Info
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: GoogleFonts.poppins(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Tk${product.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      _buildChip(Icons.category_outlined, product.category),
                      SizedBox(width: 8.w),
                      _buildChip(
                        product.condition == 'new' ? Icons.new_releases_outlined : Icons.replay_outlined, 
                        product.condition.capitalizeFirst ?? 'Used'
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 16.r),
                      SizedBox(width: 4.w),
                      Text(
                        '${product.division}, ${product.district}',
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13.sp),
                      ),
                      const Spacer(),
                      if (product.createdAt != null)
                        Text(
                          timeago.format(product.createdAt!),
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12.sp),
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  const Divider(),
                  SizedBox(height: 16.h),

                  Text('Description', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8.h),
                  Text(
                    product.description.isEmpty ? 'No description provided.' : product.description,
                    style: GoogleFonts.poppins(fontSize: 14.sp, color: AppTheme.textSecondary, height: 1.5),
                  ),

                  SizedBox(height: 24.h),
                  const Divider(),
                  SizedBox(height: 16.h),

                  // Seller Info
                  Text('Seller', style: GoogleFonts.poppins(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: product.sellerImage != null && product.sellerImage!.isNotEmpty
                            ? NetworkImage(product.sellerImage!)
                            : null,
                        child: product.sellerImage == null || product.sellerImage!.isEmpty
                            ? Icon(Icons.person, color: Colors.grey, size: 30.r)
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName ?? 'Unknown User',
                              style: GoogleFonts.poppins(fontSize: 15.sp, fontWeight: FontWeight.w600),
                            ),
                            if (product.sellerPhone != null && product.sellerPhone!.isNotEmpty)
                              Text(
                                product.sellerPhone!,
                                style: GoogleFonts.poppins(fontSize: 13.sp, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner ? null : SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: ElevatedButton.icon(
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
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: Text(
              'Message Seller',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: AppTheme.primaryColor),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              final ctrl = Get.find<MarketplaceController>();
              bool success = await ctrl.deleteProduct(product.productId!);
              if (success) {
                Get.back(); // Go back to marketplace list
                Get.snackbar('Success', 'Product deleted');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
