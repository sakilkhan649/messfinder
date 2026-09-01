import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/utils/api_constants.dart';
import '../models/product_model.dart';
import '../../../core/services/notification_service.dart';
import '../../notifications/models/app_notification_model.dart';
import '../../auth/controllers/auth_controller.dart';

class MarketplaceController extends GetxController {
  final ApiService _apiService = ApiService();

  var products = <ProductModel>[].obs;
  var myProducts = <ProductModel>[].obs;
  var isLoading = false.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  // Filters
  var selectedCategory = 'All'.obs;
  var selectedDivision = ''.obs;
  var selectedDistrict = ''.obs;
  var searchQuery = ''.obs;

  final List<String> categories = ['All', 'Furniture', 'Electronics', 'Books', 'Utensils', 'Others'];

  // Pagination
  int _currentOffset = 0;
  final int _limit = 10;
  var hasMoreData = true.obs;
  var isLoadingMore = false.obs;
  
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    fetchProducts(isRefresh: true);
  }
  
  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      fetchProducts();
    }
  }

  Future<void> fetchProducts({bool isRefresh = false}) async {
    try {
      if (isRefresh) {
        _currentOffset = 0;
        hasMoreData.value = true;
        isLoading.value = true;
      } else {
        if (!hasMoreData.value || isLoadingMore.value) return;
        isLoadingMore.value = true;
      }
      hasError.value = false;

      final queryParams = <String, dynamic>{
        'limit': _limit,
        'offset': _currentOffset,
      };
      
      if (selectedCategory.value != 'All') queryParams['category'] = selectedCategory.value;
      if (selectedDivision.value.isNotEmpty) queryParams['division'] = selectedDivision.value;
      if (selectedDistrict.value.isNotEmpty) queryParams['district'] = selectedDistrict.value;
      if (searchQuery.value.isNotEmpty) queryParams['search'] = searchQuery.value;

      final response = await _apiService.dio.get(
        ApiConstants.products,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final newProducts = data.map((e) => ProductModel.fromJson(e)).toList();

        if (newProducts.length < _limit) {
          hasMoreData.value = false;
        }

        if (isRefresh) {
          products.value = newProducts;
        } else {
          products.addAll(newProducts);
        }

        _currentOffset += newProducts.length;
      }
    } on DioException catch (e) {
      hasError.value = true;
      errorMessage.value = e.message ?? 'Failed to load products';
      debugPrint('Error fetching products: ${e.message}');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void setFilters({String? category, String? division, String? district}) {
    if (category != null) selectedCategory.value = category;
    if (division != null) selectedDivision.value = division;
    if (district != null) selectedDistrict.value = district;
    fetchProducts(isRefresh: true);
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    fetchProducts(isRefresh: true);
  }

  Future<void> fetchMyProducts(String uid) async {
    try {
      isLoading.value = true;
      hasError.value = false;

      final response = await _apiService.dio.get(ApiConstants.userProducts(uid));

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        myProducts.value = data.map((e) => ProductModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      hasError.value = true;
      errorMessage.value = e.message ?? 'Failed to load your products';
      debugPrint('Error fetching user products: ${e.message}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required String condition,
    required String category,
    required List<File> localImages,
    String? videoPath,
    required String division,
    required String district,
  }) async {
    try {
      isLoading.value = true;
      
      // Upload images first
      List<String> uploadedImageUrls = [];
      if (localImages.isNotEmpty) {
        final uploadResponse = await MediaUploadService.uploadMultipleImages(localImages);
        if (uploadResponse != null && uploadResponse['urls'] != null) {
          uploadedImageUrls = List<String>.from(uploadResponse['urls']);
        }
      }
      // Upload video if any
      String? uploadedVideoUrl;
      if (videoPath != null && videoPath.isNotEmpty) {
        if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
          uploadedVideoUrl = videoPath;
        } else {
          uploadedVideoUrl = await MediaUploadService().uploadVideo(videoPath);
        }
      }

      final data = {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'category': category,
        'images': uploadedImageUrls,
        'videoUrl': uploadedVideoUrl,
        'division': division,
        'district': district,
      };

      final response = await _apiService.dio.post(
        ApiConstants.products,
        data: data,
      );

      if (response.statusCode == 201) {
        final newProduct = ProductModel.fromJson(response.data);
        products.insert(0, newProduct);
        myProducts.insert(0, newProduct);
        
        _sendProductNotifications(title, price, category, division, district);
        
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Error adding product: ${e.message}');
      Get.snackbar('Error', 'Failed to add product',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String condition,
    required String category,
    required List<String> existingImages,
    required List<File> newLocalImages,
    String? newVideoPath,
    required String division,
    required String district,
    required String status,
  }) async {
    try {
      isLoading.value = true;
      
      List<String> allImageUrls = List.from(existingImages);
      
      // Upload new images if any
      if (newLocalImages.isNotEmpty) {
        final uploadResponse = await MediaUploadService.uploadMultipleImages(newLocalImages);
        if (uploadResponse != null && uploadResponse['urls'] != null) {
          allImageUrls.addAll(List<String>.from(uploadResponse['urls']));
        }
      }
      // Upload video if any
      String? finalVideoUrl;
      if (newVideoPath != null && newVideoPath.isNotEmpty) {
        if (newVideoPath.startsWith('http://') || newVideoPath.startsWith('https://')) {
          finalVideoUrl = newVideoPath;
        } else {
          finalVideoUrl = await MediaUploadService().uploadVideo(newVideoPath);
        }
      }

      final data = {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'category': category,
        'images': allImageUrls,
        'videoUrl': finalVideoUrl,
        'division': division,
        'district': district,
        'status': status,
      };

      final response = await _apiService.dio.put(
        ApiConstants.productById(productId),
        data: data,
      );

      if (response.statusCode == 200) {
        final updatedProduct = ProductModel.fromJson(response.data);
        final index = products.indexWhere((p) => p.productId == productId);
        if (index != -1) {
          products[index] = updatedProduct;
        }
        final myIndex = myProducts.indexWhere((p) => p.productId == productId);
        if (myIndex != -1) {
          myProducts[myIndex] = updatedProduct;
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Error updating product: ${e.message}');
      Get.snackbar('Error', 'Failed to update product',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      final response = await _apiService.dio.delete(ApiConstants.productById(productId));
      if (response.statusCode == 200) {
        products.removeWhere((p) => p.productId == productId);
        myProducts.removeWhere((p) => p.productId == productId);
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint('Error deleting product: ${e.message}');
      Get.snackbar('Error', 'Failed to delete product',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
  }

  void _sendProductNotifications(String title, double price, String category, String division, String district) {
    try {
      if (!Get.isRegistered<AuthController>()) return;
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      if (user == null) return;

      // 1. Personal upload complete notification for author
      final authorTitle = 'Product Posted Successfully! 🎉';
      final authorBody = 'Your product "$title" is now live on the marketplace.';

      NotificationService().storeNotification(
        AppNotificationModel(
          id: '',
          title: authorTitle,
          body: authorBody,
          type: NotificationType.general,
          receiverUid: user.uid,
          senderUid: 'system',
          createdAt: DateTime.now(),
        ),
      );

      NotificationService().showLocalNotification(
        title: authorTitle,
        body: authorBody,
        imageUrl: user.photoUrl,
      );

      // 2. Broadcast push notification to all users about the new product
      final titleStr = 'New Item in Marketplace! 🛒';
      final bodyStr = '$title is available for Tk $price in $district, $division.';

      NotificationService().storeNotification(
        AppNotificationModel(
          id: '',
          title: titleStr,
          body: bodyStr,
          type: NotificationType.newPost,
          receiverUid: 'all_users',
          senderUid: user.uid,
          createdAt: DateTime.now(),
        ),
      );

      NotificationService().sendPushToTopic(
        topic: 'all_users',
        title: titleStr,
        body: bodyStr,
        senderUid: user.uid,
        senderPhotoUrl: user.photoUrl ?? '',
        data: {'type': 'new_product', 'senderUid': user.uid},
      );
    } catch (e) {
      debugPrint('Error sending product notifications: $e');
    }
  }
}
