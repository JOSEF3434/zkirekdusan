import 'package:flutter/material.dart';
import 'package:mobile/features/home/domain/post_model.dart';

class PostMediaGrid extends StatelessWidget {
  final List<PostMediaItemDto> media;

  const PostMediaGrid({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();

    // Display first media item as a preview placeholder, especially for VIDEO/LIVE
    final firstMedia = media.first;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            firstMedia.url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
          ),
          if (firstMedia.fileType == 'VIDEO' || firstMedia.fileType == 'LIVE' || firstMedia.fileType == 'REEL')
            const Center(
              child: Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
            ),
          if (media.length > 1)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '1/${media.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
