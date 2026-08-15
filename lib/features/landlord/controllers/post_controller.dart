import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  DocumentSnapshot? lastDocument;
  final int postLimit = 10;
  StreamSubscription<List<PostModel>>? _postsSubscription;
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        landlordProfilesCache[uid] = data;
        return data;
      }
    } catch (e) {
      AppLogger.e('Failed to fetch landlord profile: $e', e, null, 'POST_CTRL');
    }
    return null;
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
  
  final RxString selectedDivisionFilter = 'All'.obs;
  final RxString selectedDistrictFilter = 'All'.obs;

  bool isSaved(String postId) => savedPostIds.contains(postId);

  void toggleSavePost(String postId) {
    if (savedPostIds.contains(postId)) {
      savedPostIds.remove(postId);
      _updateSavedPostsList();
      _syncSavedPostsToFirebase();
      Get.snackbar(
        'Favorites',
        'Removed from your favorites list',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      savedPostIds.add(postId);
      _updateSavedPostsList();
      _syncSavedPostsToFirebase();
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
      allPosts.where((post) => savedPostIds.contains(post.postId)).toList()
    );
    AppLogger.i('DEBUG: _updateSavedPostsList called. allPosts=${allPosts.length}, savedIds=${savedPostIds.length}, result=${savedPosts.length}');
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
    } catch(e) {
      // Ignore error
    }

    // Attempt to fetch user location silently in the background
    fetchUserLocation();

    _loadSavedPostsFromFirebase();

    await fetchInitialPosts();

    // Listen to current user's posts
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.currentUser, (_) {
        _loadSavedPostsFromFirebase();
      });
      if (auth.currentUser.value != null) {
        _postRepo.getLandlordPostsStream(auth.currentUser.value!.uid).listen((
          posts,
        ) {
          myPosts.assignAll(posts);
        });
      }
    }
  }

  Future<void> fetchInitialPosts() async {
    isLoading.value = true;
    hasMorePosts.value = true;
    lastDocument = null;
    final result = await _postRepo.getPaginatedPosts(
      limit: postLimit,
      division: selectedDivisionFilter.value == 'All' ? null : selectedDivisionFilter.value,
      district: selectedDistrictFilter.value == 'All' ? null : selectedDistrictFilter.value,
    );
    final List<PostModel> fetchedPosts = result['posts'] as List<PostModel>;
    lastDocument = result['lastDocument'] as DocumentSnapshot?;
    
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
    final result = await _postRepo.getPaginatedPosts(
      limit: postLimit,
      startAfter: lastDocument,
      division: selectedDivisionFilter.value == 'All' ? null : selectedDivisionFilter.value,
      district: selectedDistrictFilter.value == 'All' ? null : selectedDistrictFilter.value,
    );
    
    final List<PostModel> newPosts = result['posts'] as List<PostModel>;
    lastDocument = result['lastDocument'] as DocumentSnapshot?;
    
    if (newPosts.length < postLimit) {
      hasMorePosts.value = false;
    }

    
    if (newPosts.isNotEmpty) {
      allPosts.addAll(newPosts);
      _updateSavedPostsList();
    }
    
    isFetchingMore.value = false;
  }

  @override
  void onClose() {
    _postsSubscription?.cancel();
    super.onClose();
  }

  Future<void> refreshPosts() async {
    await _initPosts();
  }

  Future<void> _loadSavedPostsFromFirebase() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final user = auth.currentUser.value;
        if (user != null && user.uid.isNotEmpty) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data.containsKey('savedPosts') && data['savedPosts'] is List) {
              final List<dynamic> savedList = data['savedPosts'];
              savedPostIds.assignAll(savedList.map((e) => e.toString()));
              _updateSavedPostsList();
            }
          }
        }
      }
    } catch (e) {
      AppLogger.e(
        'Failed to load favorite posts from Firebase: $e',
        e,
        null,
        'POST_CTRL',
      );
    }
  }

  Future<void> _syncSavedPostsToFirebase() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final user = auth.currentUser.value;
        if (user != null && user.uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'savedPosts': savedPostIds.toList(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      AppLogger.e(
        'Failed to save favorite post to Firebase: $e',
        e,
        null,
        'POST_CTRL',
      );
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
        if (!matchTitle && !matchAddress && !matchDistrict && !matchDivision) return false;
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

    // 4. Sort by distance if location available, otherwise by newest
    if (userLocation.value != null) {
      final lat = userLocation.value!.latitude;
      final lng = userLocation.value!.longitude;
      filtered.sort((a, b) {
        final distA = LocationService.calculateDistanceInKm(lat, lng, a.latitude, a.longitude);
        final distB = LocationService.calculateDistanceInKm(lat, lng, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });
    } else {
      filtered.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
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
          if (url != null) {
            finalImageUrls.add(url);
          }
        }
      }

        if (finalImageUrls.isEmpty && images.isNotEmpty) {
          throw 'Failed to upload images. Please check your internet connection or Firebase Storage rules.';
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
        final bodyStr = 'A new $bachelorType room is available in $loc. Rent: $rent';
        
        NotificationService().storeNotification(AppNotificationModel(
          id: '',
          title: titleStr,
          body: bodyStr,
          type: NotificationType.newPost,
          receiverUid: 'all',
          senderUid: user.uid,
          createdAt: DateTime.now(),
        ));
        
        NotificationService().sendPushToTopic(
          topic: 'all_users',
          title: titleStr,
          body: bodyStr,
          data: {'type': 'new_post'},
        );
      } catch (e) {
        // ignore notification errors
      }

      await fetchInitialPosts();
      
      return true;
    } catch (e) {
      ApiChecker.showError(e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing Mess Post
  Future<bool> updateMessPost(PostModel updatedPost) async {
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
      
      await _postRepo.updatePost(updatedPost.copyWith(images: finalImageUrls));
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
    try {
      await _postRepo.deletePost(postId);
      ApiChecker.showSuccess('Room listing deleted successfully');
    } catch (e) {
      ApiChecker.showError(e.toString());
    }
  }

  // Toggle availability
  Future<void> togglePostStatus(String postId, bool currentStatus) async {
    try {
      await _postRepo.toggleAvailability(postId, currentStatus);
      ApiChecker.showSuccess(
        currentStatus ? 'Listing deactivated' : 'Listing activated',
      );
    } catch (e) {
      ApiChecker.showError(e.toString());
    }
  }
}
