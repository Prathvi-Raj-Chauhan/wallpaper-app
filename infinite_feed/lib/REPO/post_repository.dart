import 'package:infinite_feed/MODEL/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRepository{
  final SupabaseClient _client;
  PostRepository(this._client);

  static const int limit = 10;
  Future<List<Post>> fetchFeed({
    required int offset,
    required String userId
  }) async{
    final postResponse = await _client.from('posts').select().order('created_at', ascending: false).range(offset, offset+limit-1);
    final posts = (postResponse as List).map((e) => Post.fromJson(e)).toList();
    if(posts.isEmpty){
      return posts;
    }
    final postIds = posts.map((p) => p.id).toList();
    final likesResponse = await _client.from('user_likes').select('post_id').eq('user_id', userId).inFilter('post_id', postIds);
    

    final likedIds = (likesResponse as List).map((e) => e['post_id'] as String).toSet();

    return posts
        .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
        .toList();
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async{
    await _client.rpc('toggle_like', params: {
      'p_post_id' : postId,
      'p_user_id' : userId
    });
  }
}