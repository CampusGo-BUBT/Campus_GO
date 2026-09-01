import 'dart:io';
import '../models/feed_post.dart';
import 'api_client.dart';

class PostService {
  static final _api = ApiClient.instance;

  Stream<List<FeedPost>> postsStream() => pollStream(() => _fetch(''));

  Stream<List<FeedPost>> postsStreamByType(String type) =>
      pollStream(() => _fetchByType(type));

  Stream<List<FeedPost>> savedPostsStream() => pollStream(() => _fetch('/saved/'));

  Future<void> createPost({
    required String caption,
    required String type,
    File? imageFile,
  }) async {
    final body = <String, dynamic>{'caption': caption, 'type': type};
    if (imageFile != null) {
      await _api.postMultipart('/posts/', fields: body, files: {'image': imageFile});
    } else {
      await _api.post('/posts/', body: body);
    }
  }

  Future<void> toggleLike(String postId, bool currentlyLiked) async {
    await _api.post('/posts/$postId/like/',
        body: {'currentlyLiked': currentlyLiked});
  }

  Future<void> toggleSave(String postId, bool currentlySaved) async {
    await _api.post('/posts/$postId/save/',
        body: {'currentlySaved': currentlySaved});
  }

  Future<List<FeedPost>> _fetch(String suffix) async {
    final data = await _api.get('/posts/$suffix');
    return _parse(data);
  }

  Future<List<FeedPost>> _fetchByType(String type) async {
    final data = await _api.get('/posts/?type=$type');
    return _parse(data);
  }

  List<FeedPost> _parse(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => FeedPost.fromMap(
            Map<String, dynamic>.from(e as Map), e['id'].toString()))
        .toList();
  }
}
