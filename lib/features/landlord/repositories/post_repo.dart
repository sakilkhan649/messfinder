import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all mess posts for Bachelor Feed (Only approved & published)
  Stream<List<PostModel>> getAllPostsStream() {
    return _firestore
        .collection(ApiConstants.postsCollection)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) {
        if (post.isAvailable == false) return false;
        final status = post.paymentStatus.trim().toLowerCase();
        return status == 'approved' ||
            status == 'paid' ||
            status == 'success';
      }).toList();
      // Sort in memory by createdAt descending
      posts.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return posts;
    });
  }

  Future<void> togglePostAvailability(String postId, bool isAvailable) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({
        'isAvailable': isAvailable,
      });
      AppLogger.s('Post availability status updated ($postId): isAvailable=$isAvailable',
          tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to update post availability status: $e';
    }
  }

  // Stream pending posts for Admin Dashboard
  Stream<List<PostModel>> getPendingPostsStream() {
    return _firestore
        .collection(ApiConstants.postsCollection)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) =>
              post.paymentStatus.trim().toLowerCase() == 'pending')
          .toList();
      posts.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return posts;
    });
  }

  // Stream ALL mess posts for Admin Dashboard (Pending, Approved, Rejected)
  Stream<List<PostModel>> getAdminAllPostsStream() {
    return _firestore
        .collection(ApiConstants.postsCollection)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      posts.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return posts;
    });
  }

  // Approve a post by Admin
  Future<void> approvePost(String postId) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({
        'isPublished': true,
        'paymentStatus': 'approved',
      });
      AppLogger.s('Post approved successfully: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to approve post: $e';
    }
  }

  // Reject a post by Admin
  Future<void> rejectPost(String postId) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({
        'isPublished': false,
        'paymentStatus': 'rejected',
      });
      AppLogger.s('Post rejected: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to reject post: $e';
    }
  }

  // Stream only Landlord's posts
  Stream<List<PostModel>> getLandlordPostsStream(String ownerUid) {
    return _firestore
        .collection(ApiConstants.postsCollection)
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      posts.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return posts;
    });
  }

  // Add a new mess post
  Future<String> addPost(PostModel post) async {
    try {
      AppLogger.i('Saving new mess post: ${post.title}', tag: 'POST_REPO');
      final docRef = _firestore.collection(ApiConstants.postsCollection).doc();
      final postWithId = post.copyWith(postId: docRef.id);
      await docRef.set(postWithId.toMap());
      AppLogger.s('Mess post saved successfully', tag: 'POST_REPO');
      return docRef.id;
    } catch (e, stack) {
      AppLogger.e('Error saving mess post: $e', e, stack, 'POST_REPO');
      throw 'Failed to save mess post: $e';
    }
  }

  // Delete a mess post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .delete();
      AppLogger.s('Post deleted successfully: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to delete post: $e';
    }
  }

  // Update an existing mess post
  Future<void> updatePost(PostModel post) async {
    try {
      AppLogger.i('Updating mess post: ${post.title}', tag: 'POST_REPO');
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(post.postId)
          .update(post.toMap());
      AppLogger.s('Mess post updated successfully', tag: 'POST_REPO');
    } catch (e, stack) {
      AppLogger.e('Error updating mess post: $e', e, stack, 'POST_REPO');
      throw 'Failed to update mess post: $e';
    }
  }

  // Toggle seat availability
  Future<void> toggleAvailability(String postId, bool currentStatus) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({'isAvailable': !currentStatus});
    } catch (e) {
      throw 'Failed to update status: $e';
    }
  }

  // Automatically seed demo posts if no posts exist yet
  Future<void> seedDemoPostsIfNeeded() async {
    try {
      final snapshot = await _firestore
          .collection(ApiConstants.postsCollection)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        AppLogger.i('No mess posts found, creating demo posts...',
            tag: 'POST_REPO');
        final List<PostModel> demoPosts = [
          PostModel(
            postId: 'demo_1',
            ownerUid: 'demo_landlord_1',
            ownerPhone: '01712345678',
            title: 'Mirpur-10 Pleasant Student Mess',
            rent: 3800,
            address: 'Block-D, Road-4, Mirpur-10, Dhaka',
            latitude: 23.8069,
            longitude: 90.3687,
            images: [
              'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=800&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?q=80&w=800&auto=format&fit=crop'
            ],
            seatCount: 2,
            bachelorType: 'male',
            facilities: ['WiFi', 'Generator', 'Filtered Water', 'CCTV', 'Meal System'],
            isAvailable: true,
            isPublished: true,
            paymentStatus: 'approved',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          PostModel(
            postId: 'demo_2',
            ownerUid: 'demo_landlord_2',
            ownerPhone: '01819876543',
            title: 'Uttara Sector 11 Exclusive Female Mess',
            rent: 5500,
            address: 'Road-7, Sector-11, Uttara, Dhaka',
            latitude: 23.8759,
            longitude: 90.3795,
            images: [
              'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=800&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=800&auto=format&fit=crop'
            ],
            seatCount: 1,
            bachelorType: 'female',
            facilities: ['WiFi', 'Lift', 'Generator', 'CCTV', 'Attached Bathroom', 'Security Guard'],
            isAvailable: true,
            isPublished: true,
            paymentStatus: 'approved',
            createdAt: DateTime.now().subtract(const Duration(hours: 12)),
          ),
          PostModel(
            postId: 'demo_3',
            ownerUid: 'demo_landlord_3',
            ownerPhone: '01911223344',
            title: 'Dhanmondi-32 Executive & Student Mess',
            rent: 6200,
            address: 'House-15, Road-5, Dhanmondi, Dhaka',
            latitude: 23.7509,
            longitude: 90.3772,
            images: [
              'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?q=80&w=800&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?q=80&w=800&auto=format&fit=crop'
            ],
            seatCount: 3,
            bachelorType: 'both',
            facilities: ['WiFi', 'Lift', 'Generator', 'Parking', 'Balcony', 'Meal System'],
            isAvailable: true,
            isPublished: true,
            paymentStatus: 'approved',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          PostModel(
            postId: 'demo_4',
            ownerUid: 'demo_landlord_4',
            ownerPhone: '01678901234',
            title: 'Banani Chairman Bari Bright & Airy Room',
            rent: 7000,
            address: 'Block-F, Banani, Dhaka',
            latitude: 23.7937,
            longitude: 90.4066,
            images: [
              'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?q=80&w=800&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1493809842364-78817add7ffb?q=80&w=800&auto=format&fit=crop'
            ],
            seatCount: 2,
            bachelorType: 'male',
            facilities: ['WiFi', 'Lift', 'Generator', 'Attached Bathroom', 'Filtered Water'],
            isAvailable: true,
            isPublished: true,
            paymentStatus: 'approved',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ];

        for (final post in demoPosts) {
          await _firestore
              .collection(ApiConstants.postsCollection)
              .doc(post.postId)
              .set(post.toMap());
        }
        AppLogger.s('Demo mess posts seeded successfully', tag: 'POST_REPO');
      }
    } catch (e) {
      AppLogger.w('Failed to save demo posts (possibly offline): $e', tag: 'POST_REPO');
    }
  }
}
