import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:infinite_feed/MODEL/post.dart';
import 'package:infinite_feed/SERVICES/dio_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // false when thumbnail
  bool _mobileImageLoaded = false;

  bool _isDownloading = false;
  String? _downloadError;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final width = MediaQuery.of(context).size.width;
    final cacheWidthPx =
        (width * MediaQuery.of(context).devicePixelRatio).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: post.id,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  
                  Image.network(
                    post.thumbnailUrl,
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidthPx,
                  ),
                  
                  AnimatedOpacity(
                    opacity: _mobileImageLoaded ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeIn,
                    child: Image.network(
                      post.mobileUrl,
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidthPx,
                      frameBuilder: (context, child, frame, wasSyncLoaded) {
                        // frame != null means at least one frame has been
                        // decoded and is ready to paint.
                        if (frame != null && !_mobileImageLoaded) {
                          // Don't call setState synchronously inside
                          // frameBuilder — it runs mid-build. Defer to
                          // right after this frame is done.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => _mobileImageLoaded = true);
                            }
                          });
                        }
                        return child;
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadHighRes,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        _isDownloading
                            ? 'Downloading...'
                            : 'Download High-Res',
                      ),
                    ),
                  ),
                  if (_downloadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _downloadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadHighRes() async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });

    try {
      final bool? success =
          await GallerySaver.saveImage(widget.post.rawUrl);

      if (!mounted) return;

      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery'),
          ),
        );
      } else {
        setState(() {
          _downloadError = 'Failed to save image to gallery';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _downloadError = 'Download failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}