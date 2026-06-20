import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_feed/MODEL/post.dart';
import 'package:infinite_feed/PAGES/post_detail_screen.dart';
import 'package:infinite_feed/PROVIDER/feed_provider.dart';




class PostCard extends ConsumerWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    // Decoded image footprint in RAM should match the on-screen size, not
    // the source resolution — this is what prevents OOM on long feeds.
    final cacheWidthPx = (width * MediaQuery.of(context).devicePixelRatio)
        .round();

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PostDetailScreen(post: post),
                    ),
                  );
                },
                child: Hero(
                  tag: post.id,
                  child: Image.network(
                    post.thumbnailUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidthPx,
                  ),
                  
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : null,
                      ),
                      // Every tap goes straight to the notifier — UI flips
                      // instantly, debounce/throttle is handled internally.
                      onPressed: () => ref
                          .read(feedProvider.notifier)
                          .toggleLikeOptimistic(post.id),
                    ),
                    Text('${post.likeCount}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
