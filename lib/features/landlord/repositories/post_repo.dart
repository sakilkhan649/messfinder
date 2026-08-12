import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../models/post_model.dart';

class PostRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream all mess posts for Bachelor Feed (Only approved & published)
  Stream<List<PostModel>> getAllPostsStream({int limit = 20}) {
    return _firestore
        .collection(ApiConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
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
              })
              .toList();
          // Sort in memory by createdAt descending
          posts.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
          return posts;
        });
  }

  // Future-based paginated posts for Bachelor Feed
  Future<Map<String, dynamic>> getPaginatedPosts({
    int limit = 10,
    DocumentSnapshot? startAfter,
    String? division,
    String? district,
  }) async {
    try {
      Query query = _firestore
          .collection(ApiConstants.postsCollection)
          .where('isPublished', isEqualTo: true)
          .where('isAvailable', isEqualTo: true);
          
      if (division != null) {
        query = query.where('division', isEqualTo: division);
      }
      if (district != null) {
        query = query.where('district', isEqualTo: district);
      }
          
      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((post) {
            if (post.isAvailable == false) return false;
            final status = post.paymentStatus.trim().toLowerCase();
            return status == 'approved' ||
                status == 'paid' ||
                status == 'success';
          })
          .toList();

      return {
        'posts': posts,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      };
    } catch (e) {
      AppLogger.e('Failed to fetch paginated posts: $e', e, null, 'POST_REPO');
      return {'posts': <PostModel>[], 'lastDocument': null};
    }
  }

  Future<void> togglePostAvailability(String postId, bool isAvailable) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({'isAvailable': isAvailable});
      AppLogger.s(
        'Post availability status updated ($postId): isAvailable=$isAvailable',
        tag: 'POST_REPO',
      );
    } catch (e) {
      throw 'Failed to update post availability status: $e';
    }
  }

  // Stream pending posts for Admin Dashboard
  Stream<List<PostModel>> getPendingPostsStream() {
    return _firestore.collection(ApiConstants.postsCollection).snapshots().map((
      snapshot,
    ) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .where((post) => post.paymentStatus.trim().toLowerCase() == 'pending')
          .toList();
      posts.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return posts;
    });
  }

  // Stream ALL mess posts for Admin Dashboard (Pending, Approved, Rejected)
  Stream<List<PostModel>> getAdminAllPostsStream() {
    return _firestore.collection(ApiConstants.postsCollection).snapshots().map((
      snapshot,
    ) {
      final posts = snapshot.docs
          .map((doc) => PostModel.fromMap(doc.data(), doc.id))
          .toList();
      posts.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
      return posts;
    });
  }

  // Approve a post by Admin
  Future<void> approvePost(String postId) async {
    try {
      await _firestore
          .collection(ApiConstants.postsCollection)
          .doc(postId)
          .update({'isPublished': true, 'paymentStatus': 'approved'});
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
          .update({'isPublished': false, 'paymentStatus': 'rejected'});
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
          posts.sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
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


}
