import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/utils/api_constants.dart';
import '../models/product_model.dart';

class MarketplaceController extends GetxController {
  final ApiService _apiService = ApiService();

  var products = <ProductModel>[].obs;
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

  Future<bool> addProduct({
    required String title,
    required String description,
    required double price,
    required String condition,
    required String category,
    required List<File> localImages,
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

      final data = {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'category': category,
        'images': uploadedImageUrls,
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

      final data = {
        'title': title,
        'description': description,
        'price': price,
        'condition': condition,
        'category': category,
        'images': allImageUrls,
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
}
