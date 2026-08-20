import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../marketplace/controllers/marketplace_controller.dart';
import '../../marketplace/views/add_product_screen.dart';
import '../../marketplace/views/marketplace_screen.dart' show ProductCard;

class MyProductsScreen extends StatelessWidget {
  final UserModel user;

  const MyProductsScreen({super.key, required this.user});

  void _onAddProductPressed() async {
    await Get.bottomSheet(const AddProductScreen(), isScrollControlled: true);
    if (Get.isRegistered<MarketplaceController>()) {
      Get.find<MarketplaceController>().fetchMyProducts(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MarketplaceController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchMyProducts(user.uid);
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'My Products',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddProductPressed,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text(
          'Add Product',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.myProducts.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (controller.myProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80.r, color: Colors.grey.shade400),
                SizedBox(height: 16.h),
                Text(
                  'No products found',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async {
            await controller.fetchMyProducts(user.uid);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(16.r),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16.h,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ProductCard(product: controller.myProducts[index]);
                    },
                    childCount: controller.myProducts.length,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
