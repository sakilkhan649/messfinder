import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/imgbb_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/post_model.dart';
import '../repositories/post_repo.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class PostController extends GetxController {
  final PostRepository _postRepo = PostRepository();

  // Location
  final Rx<Position?> userLocation = Rx<Position?>(null);

  // Reactive Lists
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> myPosts = <PostModel>[].obs;
  final RxSet<String> savedPostIds = <String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isFetchingMore = false.obs;
  final RxBool hasMorePosts = true.obs;

  String? lastDocument;
  int currentPage = 1;
  final int postLimit = 10;
  final ScrollController feedScrollController = ScrollController();

  // Cache for Landlord Profiles to optimize scrolling
  final Map<String, Map<String, dynamic>> landlordProfilesCache = {};

  // Future cache to prevent concurrent identical requests
  final Map<String, Future<Map<String, dynamic>?>> _profileFetchFutures = {};

  Future<Map<String, dynamic>?> getLandlordProfile(String uid) async {
    // If it's the current user, always return the latest local data
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      final user = auth.currentUser.value;
      if (user != null && user.uid == uid) {
        return user.toMap();
      }
    }

    if (landlordProfilesCache.containsKey(uid)) {
      return landlordProfilesCache[uid];
    }

    // If a fetch is already in progress for this uid, await and return it
    if (_profileFetchFutures.containsKey(uid)) {
      return await _profileFetchFutures[uid];
    }

    // Otherwise, create a new fetch Future and store it
    final fetchFuture = _fetchProfileFromFirestore(uid);
    _profileFetchFutures[uid] = fetchFuture;

    final result = await fetchFuture;

    // Once done, remove from pending futures
    _profileFetchFutures.remove(uid);

    return result;
  }

  Future<Map<String, dynamic>?> _fetchProfileFromFirestore(String uid) async {
    try {
      final res = await ApiService().dio.get('/auth/user/$uid');
      if (res.statusCode == 200 && res.data != null) {
        final data = Map<String, dynamic>.from(res.data);
        final photo = data['profile_image'] ?? data['photoUrl'];
        final map = {
          'uid': data['uid'],
          'name': data['name'] ?? 'Landlord',
          'phone': data['phone'] ?? '',
          'photoUrl': photo,
          'profile_image': photo,
          'isPaid': data['status'] == 'active' || data['isPaid'] == true,
          'role': data['role'] ?? 'landlord',
        };
        landlordProfilesCache[uid] = map;
        return map;
      }
    } catch (e) {
      debugPrint('Error fetching landlord profile: $e');
    }
    return {'uid': uid, 'name': 'Landlord', 'phone': ''};
  }

  // Filter states for Bachelor Feed
  final RxString selectedGenderFilter =
      'all'.obs; // 'all', 'male', 'female', 'both'
  final RxInt selectedBudgetFilter = 0.obs; // 0=All, 4000, 6000, 8000
  final RxString searchQuery = ''.obs;
  Timer? _searchDebounce;

  void updateSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
    });
  }

  final RxString mapSearchQuery = ''.obs;
  Timer? _mapSearchDebounce;

  void updateMapSearchQuery(String query) {
    if (_mapSearchDebounce?.isActive ?? false) _mapSearchDebounce!.cancel();
    _mapSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      mapSearchQuery.value = query;
    });
  }

  final RxString selectedDivisionFilter = 'All'.obs;
  final RxString selectedDistrictFilter = 'All'.obs;

  bool isSaved(String postId) => savedPostIds.contains(postId);

  void toggleSavePost(String postId) {
    if (savedPostIds.contains(postId)) {
      savedPostIds.remove(postId);
      _updateSavedPostsList();
      _syncSavedPostsToLocal();
      Get.snackbar(
        'Favorites',
        'Removed from your favorites list',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      savedPostIds.add(postId);
      _updateSavedPostsList();
      _syncSavedPostsToLocal();
      Get.snackbar(
        'Favorites ❤️',
        'Added to your favorites list! You can find it in the Favorites tab.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  final RxList<PostModel> savedPosts = <PostModel>[].obs;

  void _updateSavedPostsList() {
    savedPosts.assignAll(
      allPosts.where((post) => savedPostIds.contains(post.postId)).toList(),
    );
    AppLogger.i(
      'DEBUG: _updateSavedPostsList called. allPosts=${allPosts.length}, savedIds=${savedPostIds.length}, result=${savedPosts.length}',
    );
  }

  @override
  void onInit() {
    super.onInit();
    _initPosts();

    feedScrollController.addListener(() {
      if (feedScrollController.position.pixels >=
          feedScrollController.position.maxScrollExtent - 200) {
        if (!isLoading.value && !isFetchingMore.value) {
          loadMorePosts();
        }
      }
    });
  }

  Future<void> fetchUserLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      userLocation.value = position;
    }
  }

  Future<void> _initPosts() async {
    isLoading.value = true;
    try {
      // Demo post deletion removed so they don't disappear on reload
    } catch (e) {
      // Ignore error
    }

    // Attempt to fetch user location silently in the background
    fetchUserLocation();

    _loadSavedPostsFromLocal();

    await fetchInitialPosts();

    // Listen to current user's posts
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.currentUser, (user) {
        _loadSavedPostsFromLocal();
        if (user != null) {
          fetchMyPosts();
        } else {
          myPosts.clear();
        }
      });
      if (auth.currentUser.value != null) {
        fetchMyPosts();
      }
    }
  }

  Future<void> fetchMyPosts() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        if (auth.currentUser.value == null) {
          myPosts.clear();
          return;
        }
      }
      final posts = await _postRepo.getLandlordPosts();
      myPosts.assignAll(posts);
    } catch (e) {
      debugPrint('Error in fetchMyPosts: $e');
    }
  }

  Future<void> refreshPosts() async {
    await Future.wait([
      fetchInitialPosts(),
      fetchMyPosts(),
    ]);
  }

  Future<void> fetchInitialPosts() async {
    isLoading.value = true;
    hasMorePosts.value = true;
    currentPage = 1;
    lastDocument = null;
    final result = await _postRepo.getPaginatedPosts(
      limit: postLimit,
      page: 1,
      division: selectedDivisionFilter.value == 'All'
          ? null
          : selectedDivisionFilter.value,
      district: selectedDistrictFilter.value == 'All'
          ? null
          : selectedDistrictFilter.value,
    );
    final List<PostModel> fetchedPosts = result['posts'] as List<PostModel>;
    lastDocument = result['lastDocument'] as String?;

    if (fetchedPosts.length < postLimit) {
      hasMorePosts.value = false;
    }

    allPosts.assignAll(fetchedPosts);
    _updateSavedPostsList();
    isLoading.value = false;
  }

  void updateSearch(String query) {
    searchQuery.value = query;
  }

  void updateLocationFilter(String division, String district) {
    selectedDivisionFilter.value = division;
    selectedDistrictFilter.value = district;
    fetchInitialPosts();
  }

  Future<void> loadMorePosts() async {
    if (isFetchingMore.value || !hasMorePosts.value) return;
    isFetchingMore.value = true;
    final nextPage = currentPage + 1;
    final result = await _postRepo.getPaginatedPosts(
      limit: postLimit,
      page: nextPage,
      startAfter: lastDocument,
      division: selectedDivisionFilter.value == 'All'
          ? null
          : selectedDivisionFilter.value,
      district: selectedDistrictFilter.value == 'All'
          ? null
          : selectedDistrictFilter.value,
    );

    final List<PostModel> newPosts = result['posts'] as List<PostModel>;
    lastDocument = result['lastDocument'] as String?;

    if (newPosts.length < postLimit) {
      hasMorePosts.value = false;
    }

    if (newPosts.isNotEmpty) {
      currentPage = nextPage;
      allPosts.addAll(newPosts);
      _updateSavedPostsList();
    }

    isFetchingMore.value = false;
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> _loadSavedPostsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('savedPosts');
      if (savedList != null) {
        savedPostIds.assignAll(savedList);
        _updateSavedPostsList();
      }
    } catch (e) {
      AppLogger.e('Failed to load favorite posts from SharedPreferences: $e', e, null, 'POST_CTRL');
    }
  }

  Future<void> _syncSavedPostsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('savedPosts', savedPostIds.toList());
    } catch (e) {
      AppLogger.e('Failed to save favorite post to SharedPreferences: $e', e, null, 'POST_CTRL');
    }
  }

  // Computed list for Bachelor Feed after applying Search & Filters
  List<PostModel> get filteredPosts {
    final filtered = allPosts.where((post) {
      // 0. Auto-expiry filter (15 days)
      if (post.createdAt != null) {
        final age = DateTime.now().difference(post.createdAt!).inDays;
        if (age > 15) {
          return false;
        }
      }

      // 1. Search Query filter (title or address)
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final matchTitle = post.title.toLowerCase().contains(query);
        final matchAddress = post.address.toLowerCase().contains(query);
        final matchDistrict = post.district.toLowerCase().contains(query);
        final matchDivision = post.division.toLowerCase().contains(query);
        if (!matchTitle && !matchAddress && !matchDistrict && !matchDivision) {
          return false;
        }
      }
      // 2. Gender filter
      if (selectedGenderFilter.value != 'all') {
        final postType = post.bachelorType.trim().toLowerCase();
        final filterType = selectedGenderFilter.value.trim().toLowerCase();
        if (postType != filterType && postType != 'both') {
          return false;
        }
      }
      // 3. Budget filter
      if (selectedBudgetFilter.value > 0) {
        if (post.rent > selectedBudgetFilter.value) {
          return false;
        }
      }
      return true;
    }).toList();

    // 4. Always sort by newest first (Recent posts at the top)
    filtered.sort((a, b) {
      if (a.createdAt == null || b.createdAt == null) return 0;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return filtered;
  }

  List<PostModel> get mapFilteredPosts {
    List<PostModel> filtered = List.from(allPosts);

    // Apply same filters (budget, gender, location) BUT use mapSearchQuery instead of searchQuery

    // 1. Map Search Query
    if (mapSearchQuery.value.trim().isNotEmpty) {
      final query = mapSearchQuery.value.trim().toLowerCase();
      filtered = filtered.where((post) {
        return post.title.toLowerCase().contains(query) ||
            post.address.toLowerCase().contains(query) ||
            post.division.toLowerCase().contains(query) ||
            post.district.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Gender
    if (selectedGenderFilter.value != 'all') {
      filtered = filtered.where((post) {
        final bType = post.bachelorType.toLowerCase();
        if (selectedGenderFilter.value == 'male') {
          return bType.contains('male') || bType.contains('boy');
        } else if (selectedGenderFilter.value == 'female') {
          return bType.contains('female') || bType.contains('girl');
        }
        return true;
      }).toList();
    }

    // 3. Budget
    if (selectedBudgetFilter.value > 0) {
      filtered = filtered.where((post) {
        return post.rent <= selectedBudgetFilter.value;
      }).toList();
    }

    return filtered;
  }

  // Add a new Mess Post (Landlord)
  Future<bool> addMessPost({
    required String title,
    required double rent,
    required String address,
    required int seatCount,
    String? seatDescription,
    required String division,
    required String district,
    String? ownerPhone,
    required String bachelorType,
    String preferredTenant = 'Student / Job holder',
    required List<String> facilities,
    required List<String> images,
    String? videoPath,
    String? trxId,
    String? senderNumber,
    double latitude = 23.8103,
    double longitude = 90.4125,
  }) async {
    final auth = Get.find<AuthController>();
    final user = auth.currentUser.value;
    if (user == null) {
      ApiChecker.showError('Please log in again');
      return false;
    }

    try {
      isLoading.value = true;

      final storageService = ImgbbService();
      final List<String> finalImageUrls = [];

      for (String path in images) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          finalImageUrls.add(path);
        } else {
          final url = await storageService.uploadImage(path);
          if (url != null) finalImageUrls.add(url);
        }
      }

      if (finalImageUrls.isEmpty && images.isNotEmpty) {
        throw 'Image upload failed! Please check your internet connection and try again.\n\nTip: Cloudinary preset "messfinder_preset" must be set to "Unsigned" in Cloudinary dashboard.';
      }

      String? uploadedVideoUrl;
      if (videoPath != null && videoPath.isNotEmpty) {
        if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
          uploadedVideoUrl = videoPath;
        } else {
          uploadedVideoUrl = await storageService.uploadVideo(videoPath);
        }
      }

      final newPost = PostModel(
        postId: '',
        ownerUid: user.uid,
        ownerPhone: (ownerPhone != null && ownerPhone.trim().isNotEmpty)
            ? ownerPhone.trim()
            : user.phone,
        title: title,
        rent: rent,
        address: address,
        latitude: latitude,
        longitude: longitude,
        images: finalImageUrls,
        videoUrl: uploadedVideoUrl,
        seatCount: seatCount,
        seatDescription: seatDescription,
        division: division,
        district: district,
        bachelorType: bachelorType,
        preferredTenant: preferredTenant,
        facilities: facilities,
        isAvailable: true,
        isPublished: true,
        paymentStatus: 'approved',
        paymentTrxId: trxId,
        senderNumber: senderNumber,
        createdAt: DateTime.now(),
      );

      await _postRepo.addPost(newPost);

      // Broadcast push notification to bachelors (and others) about the new room
      try {
        final loc = address.split(',').first;
        final titleStr = 'New Room Available! 🏠';
        final bodyStr =
            'A new $bachelorType room is available in $loc. Rent: $rent';

        NotificationService().storeNotification(
          AppNotificationModel(
            id: '',
            title: titleStr,
            body: bodyStr,
            type: NotificationType.newPost,
            receiverUid: 'all',
            senderUid: user.uid,
            createdAt: DateTime.now(),
          ),
        );

        NotificationService().sendPushToTopic(
          topic: 'all_users',
          title: titleStr,
          body: bodyStr,
          data: {'type': 'new_post'},
        );
      } catch (e) {
        // ignore notification errors
      }

      await Future.wait([
        fetchInitialPosts(),
        fetchMyPosts(),
      ]);

      return true;
    } catch (e) {
      ApiChecker.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing Mess Post
  Future<bool> updateMessPost(PostModel updatedPost, {String? newVideoPath}) async {
    try {
      isLoading.value = true;

      final storageService = ImgbbService();
      final List<String> finalImageUrls = [];
      bool anyLocalUploadFailed = false;

      for (String path in updatedPost.images) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          finalImageUrls.add(path);
        } else {
          final url = await storageService.uploadImage(path);
          if (url != null) {
            finalImageUrls.add(url);
          } else {
            anyLocalUploadFailed = true;
          }
        }
      }

      // Only fail if there are no images at all after processing
      if (finalImageUrls.isEmpty) {
        throw 'Failed to upload images. Please check your internet connection.';
      }

      if (anyLocalUploadFailed) {
        ApiChecker.showError('Some images failed to upload and were skipped.');
      }

      String? finalVideoUrl = updatedPost.videoUrl;
      if (newVideoPath != null && newVideoPath.isNotEmpty) {
        if (newVideoPath.startsWith('http://') || newVideoPath.startsWith('https://')) {
          finalVideoUrl = newVideoPath;
        } else {
          final uploadedUrl = await storageService.uploadVideo(newVideoPath);
          if (uploadedUrl != null) {
            finalVideoUrl = uploadedUrl;
          }
        }
      }

      final finalPost = updatedPost.copyWith(images: finalImageUrls, videoUrl: finalVideoUrl);

      // Instant optimistic UI update
      final myIdx = myPosts.indexWhere((p) => p.postId == finalPost.postId);
      if (myIdx != -1) {
        myPosts[myIdx] = finalPost;
        myPosts.refresh();
      }
      final allIdx = allPosts.indexWhere((p) => p.postId == finalPost.postId);
      if (allIdx != -1) {
        allPosts[allIdx] = finalPost;
        allPosts.refresh();
      }

      await _postRepo.updatePost(finalPost);
      fetchMyPosts();
      return true;
    } catch (e) {
      ApiChecker.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete Mess Post
  Future<void> deleteMessPost(String postId) async {
    // Instant optimistic removal from UI
    myPosts.removeWhere((p) => p.postId == postId);
    allPosts.removeWhere((p) => p.postId == postId);
    savedPostIds.remove(postId);
    _updateSavedPostsList();
    try {
      await _postRepo.deletePost(postId);
      ApiChecker.showSuccess('Room listing deleted successfully');
    } catch (e) {
      fetchMyPosts();
      ApiChecker.showError(e.toString());
    }
  }

  // Toggle availability
  Future<void> togglePostStatus(String postId, bool currentStatus) async {
    final newStatus = !currentStatus;
    // Instant optimistic update in memory
    final myIdx = myPosts.indexWhere((p) => p.postId == postId);
    if (myIdx != -1) {
      myPosts[myIdx] = myPosts[myIdx].copyWith(isAvailable: newStatus);
      myPosts.refresh();
    }
    final allIdx = allPosts.indexWhere((p) => p.postId == postId);
    if (allIdx != -1) {
      allPosts[allIdx] = allPosts[allIdx].copyWith(isAvailable: newStatus);
      allPosts.refresh();
    }
    try {
      await _postRepo.toggleAvailability(postId, currentStatus);
      ApiChecker.showSuccess(
        currentStatus ? 'Listing deactivated' : 'Listing activated',
      );
    } catch (e) {
      fetchMyPosts();
      ApiChecker.showError(e.toString());
    }
  }
}
