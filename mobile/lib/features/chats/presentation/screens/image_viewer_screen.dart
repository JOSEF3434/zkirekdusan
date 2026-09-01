// lib/features/chats/presentation/screens/image_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<MessageAttachmentModel> images;
  final int initialIndex;
  final Function(MessageAttachmentModel image, int index)? onDelete;
  final Function(MessageAttachmentModel image, bool isStarred)? onStar;
  final Function(MessageAttachmentModel image)? onShare;
  final Function(MessageAttachmentModel image)? onDownload;
  final Function(MessageAttachmentModel image)? onForward;

  const ImageViewerScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.onDelete,
    this.onStar,
    this.onShare,
    this.onDownload,
    this.onForward,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final Set<String> _starredImageIds = {};
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _shareImage() async {
    HapticFeedback.lightImpact();
    if (widget.images.isEmpty) return;
    final image = widget.images[_currentIndex];
    widget.onShare?.call(image);

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Preparing image for sharing...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      final file = await DefaultCacheManager().getSingleFile(image.url);
      await Share.shareXFiles(
        [XFile(file.path, name: image.originalName, mimeType: image.mimeType)],
        text: image.originalName,
      );
    } catch (_) {
      await Share.share(image.url, subject: image.originalName);
    }
  }

  Future<void> _downloadImage() async {
    if (_isDownloading || widget.images.isEmpty) return;
    HapticFeedback.mediumImpact();
    final image = widget.images[_currentIndex];
    widget.onDownload?.call(image);

    setState(() => _isDownloading = true);
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading image...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final sanitizedName = image.originalName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final savePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final file = await DefaultCacheManager().getSingleFile(image.url);
      final savedFile = await file.copy(savePath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${image.originalName}'),
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.amberAccent,
            onPressed: () {
              OpenFilex.open(savedFile.path);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    HapticFeedback.selectionClick();
    if (widget.images.isEmpty) return;
    final image = widget.images[_currentIndex];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete Image', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this image? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onDelete?.call(image, _currentIndex);
      Navigator.pop(context, {'action': 'delete', 'image': image, 'index': _currentIndex});
    }
  }

  void _forwardImage() {
    HapticFeedback.lightImpact();
    if (widget.images.isEmpty) return;
    final image = widget.images[_currentIndex];
    widget.onForward?.call(image);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Forward Image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.blueAccent),
                ),
                title: const Text('Share to other apps', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Send via WhatsApp, Telegram, etc.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link, color: Colors.greenAccent),
                ),
                title: const Text('Copy Image Link', style: TextStyle(color: Colors.white)),
                subtitle: Text(image.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: image.url));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleStar() {
    HapticFeedback.mediumImpact();
    if (widget.images.isEmpty) return;
    final image = widget.images[_currentIndex];
    final isStarred = _starredImageIds.contains(image.fileId);

    setState(() {
      if (isStarred) {
        _starredImageIds.remove(image.fileId);
      } else {
        _starredImageIds.add(image.fileId);
      }
    });

    widget.onStar?.call(image, !isStarred);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(!isStarred ? 'Image starred' : 'Image removed from starred'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black),
        body: const Center(
          child: Text('No image to display', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final currentImage = widget.images[_currentIndex];
    final isStarred = _starredImageIds.contains(currentImage.fileId);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image gallery
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              final image = widget.images[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(image.url),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: 'message-image-${image.fileId}'),
              );
            },
            itemCount: widget.images.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
          ),

          // Top bar
          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    if (widget.images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isStarred ? Icons.star : Icons.star_outline,
                        color: isStarred ? Colors.amberAccent : Colors.white,
                      ),
                      onPressed: _toggleStar,
                      tooltip: isStarred ? 'Unstar' : 'Star',
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showOptionsMenu(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom action toolbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 32,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: _shareImage,
                  ),
                  _ActionButton(
                    icon: Icons.download_outlined,
                    label: 'Download',
                    onTap: _downloadImage,
                  ),
                  _ActionButton(
                    icon: Icons.forward_outlined,
                    label: 'Forward',
                    onTap: _forwardImage,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onTap: _confirmDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    final isStarred =
        _starredImageIds.contains(widget.images[_currentIndex].fileId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text(
                  'View Info',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showImageInfo();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.forward_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  'Forward',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _forwardImage();
                },
              ),
              ListTile(
                leading: Icon(
                  isStarred ? Icons.star : Icons.star_outline,
                  color: isStarred ? Colors.amberAccent : Colors.white,
                ),
                title: Text(
                  isStarred ? 'Remove from Starred' : 'Star Image',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleStar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageInfo() {
    final image = widget.images[_currentIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Image Info', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'File name', value: image.originalName),
            if (image.width != null && image.height != null)
              _InfoRow(
                label: 'Dimensions',
                value: '${image.width} × ${image.height}',
              ),
            if (image.size != null)
              _InfoRow(label: 'Size', value: _formatFileSize(image.size!)),
            _InfoRow(label: 'Type', value: image.mimeType),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
