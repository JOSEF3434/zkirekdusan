// lib/features/admin/presentation/screens/admin_content_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_search_bar.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_status_badge.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_confirmation_dialog.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminContentScreen extends ConsumerStatefulWidget {
  const AdminContentScreen({super.key});

  @override
  ConsumerState<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends ConsumerState<AdminContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<dynamic> _posts = [];
  final List<dynamic> _videos = [];
  bool _isLoading = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final postsRes = await repo.getPosts(search: _search);
      final videosRes = await repo.getVideos(search: _search);

      setState(() {
        _posts.clear();
        _posts.addAll((postsRes['items'] as List?) ?? []);
        _videos.clear();
        _videos.addAll((videosRes['items'] as List?) ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDeletePost(String id, String preview) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Post',
      message: 'Permanently remove post "$preview"?',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null) {
      final ok = await ref.read(adminRepositoryProvider).deletePost(id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
        _loadContent();
      }
    }
  }

  Future<void> _handleDeleteVideo(String id, String title) async {
    final reason = await AdminConfirmationDialog.show(
      context,
      title: 'Delete Video',
      message: 'Permanently remove video "$title"?',
      confirmColor: Colors.red,
      requireReason: true,
    );
    if (reason != null) {
      final ok = await ref.read(adminRepositoryProvider).deleteVideo(id, reason: reason);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted')),
        );
        _loadContent();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.content')),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article_outlined), text: 'Posts'),
            Tab(icon: Icon(Icons.video_collection_outlined), text: 'Videos'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContent,
          ),
        ],
      ),
      body: AdminResponsiveLayout(
        child: Column(
          children: [
            AdminSearchBar(
              hintText: 'Search content text, tags, or titles...',
              onSearch: (val) {
                _search = val;
                _loadContent();
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(),
                        _buildVideosTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    final tr = ref.watch(trProvider);
    if (_posts.isEmpty) {
      return Center(child: Text(tr('admin.no_records')));
    }
    return ListView.separated(
      itemCount: _posts.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = _posts[index];
        final author = safeMap(p['author']);
        final content = p['content'] as String? ?? 'No text content';
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.article)),
          title: Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            'By @${author?['username'] ?? 'unknown'} • ${p['status'] ?? 'PUBLISHED'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _handleDeletePost(
              p['id'],
              content.length > 30 ? '${content.substring(0, 30)}...' : content,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideosTab() {
    final tr = ref.watch(trProvider);
    if (_videos.isEmpty) {
      return Center(child: Text(tr('admin.no_records')));
    }
    return ListView.separated(
      itemCount: _videos.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final v = _videos[index];
        final uploader = safeMap(v['uploadedBy']);
        final title = v['title'] as String? ?? 'Untitled Video';
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.video_library)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('Uploaded by @${uploader?['username'] ?? 'user'}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminStatusBadge(status: v['status'] ?? 'PUBLISHED'),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _handleDeleteVideo(v['id'], title),
              ),
            ],
          ),
        );
      },
    );
  }
}
