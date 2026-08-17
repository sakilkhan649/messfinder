import '../../../core/utils/app_logger.dart';
import '../../../core/services/api_service.dart';
import '../models/post_model.dart';

class PostRepository {
  final ApiService _apiService = ApiService();

  // Future-based ALL posts
  Future<List<PostModel>> getAllPosts() async {
    try {
      final response = await _apiService.dio.get('/posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PostModel.fromMap(json, json['post_id'].toString())).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Failed to fetch posts: $e', e, null, 'POST_REPO');
      return [];
    }
  }

  // Future-based paginated posts for Bachelor Feed
  Future<Map<String, dynamic>> getPaginatedPosts({
    int limit = 10,
    String? startAfter, // Changed from DocumentSnapshot to String ID or just ignore for simple REST API
    String? division,
    String? district,
    String? bachelorType,
  }) async {
    try {
      final response = await _apiService.dio.get('/posts', queryParameters: {
        if (district != null && district != 'All' && district.isNotEmpty) 'district': district,
        if (division != null && division != 'All' && division.isNotEmpty) 'division': division,
        if (bachelorType != null && bachelorType != 'all' && bachelorType.isNotEmpty) 'bachelorType': bachelorType,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final posts = data.map((json) => PostModel.fromMap(json, json['post_id'].toString())).toList();
        return {
          'posts': posts,
          'lastDocument': posts.isNotEmpty ? posts.last.postId : null,
        };
      }
      return {'posts': <PostModel>[], 'lastDocument': null};
    } catch (e) {
      AppLogger.e('Failed to fetch paginated posts: $e', e, null, 'POST_REPO');
      return {'posts': <PostModel>[], 'lastDocument': null};
    }
  }

  // Fetch Landlord's posts
  Future<List<PostModel>> getLandlordPosts() async {
    try {
      final response = await _apiService.dio.get('/posts/user/my-posts');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => PostModel.fromMap(json, json['post_id'].toString())).toList();
      }
      return [];
    } catch (e) {
      AppLogger.e('Failed to fetch landlord posts: $e', e, null, 'POST_REPO');
      return [];
    }
  }

  // Add a new mess post
  Future<String> addPost(PostModel post) async {
    try {
      final response = await _apiService.dio.post('/posts', data: post.toMap());
      if (response.statusCode == 201) {
        AppLogger.s('Mess post saved successfully', tag: 'POST_REPO');
        return response.data['post_id'].toString();
      }
      throw 'Failed to add post';
    } catch (e) {
      AppLogger.e('Error saving mess post: $e', e, null, 'POST_REPO');
      throw 'Failed to save mess post: $e';
    }
  }

  // Delete a mess post
  Future<void> deletePost(String postId) async {
    try {
      await _apiService.dio.delete('/posts/$postId');
      AppLogger.s('Post deleted successfully: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to delete post: $e';
    }
  }

  // Update an existing mess post
  Future<void> updatePost(PostModel post) async {
    try {
      await _apiService.dio.put('/posts/${post.postId}', data: post.toMap());
      AppLogger.s('Mess post updated successfully', tag: 'POST_REPO');
    } catch (e) {
      AppLogger.e('Error updating mess post: $e', e, null, 'POST_REPO');
      throw 'Failed to update mess post: $e';
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String postId, bool currentStatus) async {
    try {
      await _apiService.dio.put('/posts/$postId/availability', data: {'isAvailable': !currentStatus});
    } catch (e) {
      throw 'Failed to update status: $e';
    }
  }

  // Admin: Approve a post
  Future<void> approvePost(String postId) async {
    try {
      // Temporary REST logic for Admin Approval
      await _apiService.dio.put('/posts/$postId', data: {'isPublished': true, 'paymentStatus': 'approved'});
      AppLogger.s('Post approved successfully: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to approve post: $e';
    }
  }

  // Admin: Reject a post
  Future<void> rejectPost(String postId) async {
    try {
      // Temporary REST logic for Admin Rejection
      await _apiService.dio.put('/posts/$postId', data: {'isPublished': false, 'paymentStatus': 'rejected'});
      AppLogger.s('Post rejected: $postId', tag: 'POST_REPO');
    } catch (e) {
      throw 'Failed to reject post: $e';
    }
  }
}
