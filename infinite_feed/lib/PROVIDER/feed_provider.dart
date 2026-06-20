import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../REPO/post_repository.dart';
import '../MODEL/post.dart';


 
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
 
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository(ref.watch(supabaseClientProvider));
});
 

final currentUserIdProvider = Provider<String>((ref) => 'test_user');
 
final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    ref.watch(postRepositoryProvider),
    ref.watch(currentUserIdProvider),
  );
});
 

 
class FeedState {
  final List<Post> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int offset;
  final String? error;
 
  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.offset = 0,
    this.error,
  });
 
  FeedState copyWith({
    List<Post>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? offset,
    String? error,
    bool clearError = false,
  }) =>
      FeedState(
        posts: posts ?? this.posts,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        offset: offset ?? this.offset,
        error: clearError ? null : (error ?? this.error),
      );
}
 
 
class FeedNotifier extends StateNotifier<FeedState> {
  final PostRepository _repo;
  final String _userId;
 
  static const int _pageSize = PostRepository.limit;
  static const Duration _debounce = Duration(milliseconds: 600);
 
  // Per-post debounce timers, keyed by post id.
  final Map<String, Timer> _debounceTimers = {};

  // This is what we compare against, and what we revert to on failure.
  final Map<String, bool> _lastSyncedLiked = {};
 
  // Surface transient errorsto the UI as a stream
  // the widget can listen to and turn into a SnackBar.
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  Stream<String> get errors => _errorController.stream;
 
  FeedNotifier(this._repo, this._userId) : super(const FeedState()) {
    loadFirstPage();
  }
 
  Future<void> loadFirstPage() async {
    state = state.copyWith(isLoading: true, clearError: true);
    debugPrint('[FeedNotifier] loadFirstPage: fetching offset=0 userId=$_userId');
    try {
      final posts = await _repo.fetchFeed(offset: 0, userId: _userId);
      debugPrint('[FeedNotifier] loadFirstPage: got ${posts.length} posts');
      for (final p in posts) {
        _lastSyncedLiked[p.id] = p.isLiked;
      }
      state = FeedState(
        posts: posts,
        isLoading: false,
        hasMore: posts.length == _pageSize,
        offset: posts.length,
      );
    } catch (e, st) {
      debugPrint('[FeedNotifier] loadFirstPage FAILED: $e');
      debugPrint('$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
 
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    debugPrint('[FeedNotifier] loadMore: fetching offset=${state.offset}');
    try {
      final newPosts = await _repo.fetchFeed(
        offset: state.offset,
        userId: _userId,
      );
      debugPrint('[FeedNotifier] loadMore: got ${newPosts.length} posts');
      for (final p in newPosts) {
        _lastSyncedLiked[p.id] = p.isLiked;
      }
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMore: newPosts.length == _pageSize,
        offset: state.offset + newPosts.length,
      );
    } catch (e, st) {
      debugPrint('[FeedNotifier] loadMore FAILED: $e');
      debugPrint('$st');
      state = state.copyWith(isLoadingMore: false);
      _errorController.add('Could not load more posts.');
    }
  }
 
  Future<void> refresh() => loadFirstPage();
 
  void toggleLikeOptimistic(String postId) {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
 
    final post = state.posts[index];
    final newLiked = !post.isLiked;
    final newCount = newLiked ? post.likeCount + 1 : post.likeCount - 1;
 
    final updated = [...state.posts];
    updated[index] = post.copyWith(isLiked: newLiked, likeCount: newCount);
    state = state.copyWith(posts: updated);
 

    // reset timer on every tap and after timer is over call _settle to finally send request
    _debounceTimers[postId]?.cancel();
    _debounceTimers[postId] = Timer(_debounce, () => _settle(postId));
  }
 
  Future<void> _settle(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
 
    final currentLiked = state.posts[index].isLiked;
    final lastSynced = _lastSyncedLiked[postId] ?? false;
 
    // Net-zero taps
    if (currentLiked == lastSynced) return;
 
    try {
      await _repo.toggleLike(postId: postId, userId: _userId);
      _lastSyncedLiked[postId] = currentLiked;
    } catch (_) {
      // revert the UI to the last confirmed
      final idx = state.posts.indexWhere((p) => p.id == postId);
      if (idx == -1) return;
      final post = state.posts[idx];
      final revertedCount =
          lastSynced ? post.likeCount + 1 : post.likeCount - 1;
      final reverted = [...state.posts];
      reverted[idx] = post.copyWith(
        isLiked: lastSynced,
        likeCount: revertedCount,
      );
      state = state.copyWith(posts: reverted);
      _errorController.add('Could not update like — check your connection.');
    }
  }
 
  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _errorController.close();
    super.dispose();
  }
}