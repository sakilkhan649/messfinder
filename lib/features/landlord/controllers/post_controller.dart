import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/network/api_checker.dart';
import '../../../core/utils/app_logger.dart';
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

  // Cache for Landlord Profiles to optimize scrolling
  final Map<String, Map<String, dynamic>> landlordProfilesCache = {};

  Future<Map<String, dynamic>?> getLandlordProfile(String uid) async {
    if (landlordProfilesCache.containsKey(uid)) {
      return landlordProfilesCache[uid];
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
      _syncSavedPostsToFirebase();
      Get.snackbar(
        'Favorites',
        'Removed from your favorites list',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } else {
      savedPostIds.add(postId);
      _syncSavedPostsToFirebase();
      Get.snackbar(
        'Favorites ❤️',
        'Added to your favorites list! You can find it in the Favorites tab.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  List<PostModel> get savedPosts =>
      allPosts.where((post) => savedPostIds.contains(post.postId)).toList();

  @override
  void onInit() {
    super.onInit();
    _initPosts();
  }

  Future<void> _initPosts() async {
    isLoading.value = true;
    try {
      await _postRepo.seedDemoPostsIfNeeded();
    } catch (e) {
      AppLogger.w('Seed demo posts failed/timed out: $e', tag: 'POST_CTRL');
    }
    
    _loadSavedPostsFromFirebase();

    bool hasEmitted = false;
    
    // Listen to all posts
    _postRepo.getAllPostsStream().listen((posts) {
      allPosts.assignAll(posts);
      if (!hasEmitted) {
        isLoading.value = false;
        hasEmitted = true;
      }
    }, onError: (e) {
      AppLogger.e('পোস্ট স্ট্রিম এরর: $e', e, null, 'POST_CTRL');
      isLoading.value = false;
      hasEmitted = true;
    });

    // Fallback if stream takes too long or Play Services is missing
    Future.delayed(const Duration(seconds: 5), () {
      if (!hasEmitted) {
        AppLogger.w('Firestore stream taking too long. Disabling loading spinner.', tag: 'POST_CTRL');
        isLoading.value = false;
      }
    });

    // If landlord is logged in, listen to their posts
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      ever(auth.currentUser, (_) {
        _loadSavedPostsFromFirebase();
      });
      if (auth.currentUser.value != null && auth.currentUser.value!.isLandlord) {
        _postRepo
            .getLandlordPostsStream(auth.currentUser.value!.uid)
            .listen((posts) {
          myPosts.assignAll(posts);
        });
      }
    }
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
            }
          }
        }
      }
    } catch (e) {
      AppLogger.e('ফায়ারবেস থেকে পছন্দের মেস লোড করতে সমস্যা: $e', e, null, 'POST_CTRL');
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
      AppLogger.e('ফায়ারবেসে পছন্দের মেস সেভ করতে সমস্যা: $e', e, null, 'POST_CTRL');
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
  Future<void> addMessPost({
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
      return;
    }

    try {
      isLoading.value = true;
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
        images: images.isEmpty
            ? [
                'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=800&auto=format&fit=crop'
              ]
            : images,
        seatCount: seatCount,
        seatDescription: seatDescription,
        bachelorType: bachelorType,
        preferredTenant: preferredTenant,
        facilities: facilities,
        isAvailable: true,
        isPublished: false,
        paymentStatus: 'pending',
        paymentTrxId: trxId,
        senderNumber: senderNumber,
        createdAt: DateTime.now(),
      );

      await _postRepo.addPost(newPost);
      ApiChecker.showSuccess(
          'Room listing submitted for review! ⏳ It will go live once payment is verified.');
    } catch (e) {
      ApiChecker.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Update an existing Mess Post
  Future<void> updateMessPost(PostModel updatedPost) async {
    try {
      isLoading.value = true;
      await _postRepo.updatePost(updatedPost);
      ApiChecker.showSuccess('Room listing updated successfully! 🎉');
    } catch (e) {
      ApiChecker.showError(e.toString());
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
          currentStatus ? 'Listing deactivated' : 'Listing activated');
    } catch (e) {
      ApiChecker.showError(e.toString());
    }
  }
}
