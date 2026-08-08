import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/imgbb_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/post_model.dart';
import '../repositories/post_repo.dart';

class PostController extends GetxController {
  final PostRepository _postRepo = PostRepository();

  // Reactive Lists
  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> myPosts = <PostModel>[].obs;
  final RxSet<String> savedPostIds = <String>{}.obs;
  final RxBool isLoading = true.obs;

  final RxInt postLimit = 20.obs;
  StreamSubscription<List<PostModel>>? _postsSubscription;
  final ScrollController feedScrollController = ScrollController();

  // Cache for Landlord Profiles to optimize scrolling
  final Map<String, Map<String, dynamic>> landlordProfilesCache = {};

  Future<Map<String, dynamic>?> getLandlordProfile(String uid) async {
    if (landlordProfilesCache.containsKey(uid)) {
      return landlordProfilesCache[uid];
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        landlordProfilesCache[uid] = doc.data() as Map<String, dynamic>;
        return landlordProfilesCache[uid];
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
    print('DEBUG: _updateSavedPostsList called. allPosts=${allPosts.length}, savedIds=${savedPostIds.length}, result=${savedPosts.length}');
  }

  @override
  void onInit() {
    super.onInit();
    _initPosts();

    feedScrollController.addListener(() {
      if (feedScrollController.position.pixels >=
          feedScrollController.position.maxScrollExtent - 200) {
        if (!isLoading.value) {
          loadMorePosts();
        }
      }
    });
  }

  Future<void> _initPosts() async {
    isLoading.value = true;
    try {
      final demoIds = ['demo_1', 'demo_2', 'demo_3', 'demo_4'];
      for (final id in demoIds) {
        await _postRepo.deletePost(id);
      }
      AppLogger.s('DELETED DEMO POSTS FROM FIREBASE', tag: 'POST_CTRL');
    } catch(e) {}


    _loadSavedPostsFromFirebase();

    _listenToPosts();

    // Fallback if stream takes too long or Play Services is missing
    Future.delayed(const Duration(seconds: 5), () {
      if (isLoading.value) {
        AppLogger.w(
          'Firestore stream taking too long. Disabling loading spinner.',
          tag: 'POST_CTRL',
        );
        isLoading.value = false;
      }
    });

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

  void _listenToPosts() {
    bool hasEmitted = false;
    _postsSubscription?.cancel();
    _postsSubscription = _postRepo
        .getAllPostsStream(limit: postLimit.value)
        .listen(
          (posts) {
            allPosts.assignAll(posts);
            _updateSavedPostsList();
            if (!hasEmitted) {
              isLoading.value = false;
              hasEmitted = true;
            }
          },
          onError: (e) {
            AppLogger.e('Post stream error: $e', e, null, 'POST_CTRL');
            isLoading.value = false;
            hasEmitted = true;
          },
        );
  }

  void loadMorePosts() {
    postLimit.value += 20;
    _listenToPosts();
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
    return allPosts.where((post) {
      // 1. Search Query filter (title or address)
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final matchTitle = post.title.toLowerCase().contains(query);
        final matchAddress = post.address.toLowerCase().contains(query);
        if (!matchTitle && !matchAddress) return false;
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
  }

  // Add a new Mess Post (Landlord)
  Future<bool> addMessPost({
    required String title,
    required double rent,
    required String address,
    required int seatCount,
    String? seatDescription,
    String? ownerPhone,
    required String bachelorType,
    String preferredTenant = 'Student / Job holder',
    required List<String> facilities,
    required List<String> images,
    String? trxId,
    String? senderNumber,
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
          latitude: 23.8103,
          longitude: 90.4125,
          images: finalImageUrls,
          seatCount: seatCount,
          seatDescription: seatDescription,
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
      ApiChecker.showSuccess(
        'Room listing published successfully! 🎉',
      );
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
      
      for (String path in updatedPost.images) {
        if (path.startsWith('http://') || path.startsWith('https://')) {
          finalImageUrls.add(path);
        } else {
          final url = await storageService.uploadImage(path);
          if (url != null) {
            finalImageUrls.add(url);
          }
        }
      }
      
      if (finalImageUrls.isEmpty && updatedPost.images.isNotEmpty) {
        throw 'Failed to upload images. Please check your internet connection or Firebase Storage rules.';
      }
      
      await _postRepo.updatePost(updatedPost.copyWith(images: finalImageUrls));
      ApiChecker.showSuccess('Room listing updated successfully! 🎉');
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
