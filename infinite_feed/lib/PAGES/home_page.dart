import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_feed/PROVIDER/feed_provider.dart';
import 'package:infinite_feed/WIDGET/post_card.dart'; 
 

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});
 
  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}
 
class _FeedScreenState extends ConsumerState<FeedScreen> {
  final ScrollController _scrollController = ScrollController();
 
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
 
    
    ref.read(feedProvider.notifier).errors.listen((message) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }
 
  void _onScroll() {
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }
 
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
 
    final feedState = ref.watch(feedProvider);
 
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: _buildBody(feedState),
    );
  }
 
  Widget _buildBody(FeedState feedState) {
    if (feedState.isLoading && feedState.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
 
    if (feedState.error != null && feedState.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load feed:\n${feedState.error}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(feedProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
 
    if (feedState.posts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    }
 
    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
       
        physics: const AlwaysScrollableScrollPhysics(),
        // +1 slot for the bottom loading indicator.
        itemCount: feedState.posts.length + 1,
        itemBuilder: (context, index) {
          if (index == feedState.posts.length) {
            return _buildFooter(feedState);
          }
          return PostCard(post: feedState.posts[index]);
        },
      ),
    );
  }
 
  Widget _buildFooter(FeedState feedState) {
    if (feedState.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!feedState.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text("You're all caught up")),
      );
    }
    return const SizedBox(height: 1);
  }
}