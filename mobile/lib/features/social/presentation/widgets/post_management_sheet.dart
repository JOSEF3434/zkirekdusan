// lib/features/social/presentation/widgets/post_management_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/rich_text_composer.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/utils/app_link_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/home/domain/post_model.dart';
import 'package:mobile/features/profile/presentation/providers/profile_posts_provider.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';
import 'package:mobile/features/social/presentation/widgets/share_button.dart';

class PostManagementSheet extends ConsumerWidget {
  final PostResponseDto post;
  final VoidCallback? onPostDeleted;
  final VoidCallback? onPostUpdated;

  const PostManagementSheet({
    super.key,
    required this.post,
    this.onPostDeleted,
    this.onPostUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required PostResponseDto post,
    VoidCallback? onPostDeleted,
    VoidCallback? onPostUpdated,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PostManagementSheet(
        post: post,
        onPostDeleted: onPostDeleted,
        onPostUpdated: onPostUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthor = authState.user?.id == post.author.id;
    final saveStateMap = ref.watch(saveProvider);
    final isSaved = saveStateMap[post.id] ?? (post.isSaved ?? false);
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: post.author.avatarUrl != null
                        ? NetworkImage(post.author.avatarUrl!)
                        : null,
                    child: post.author.avatarUrl == null
                        ? Text(
                            (post.author.displayName?.isNotEmpty == true
                                    ? post.author.displayName![0]
                                    : post.author.username?.isNotEmpty == true
                                    ? post.author.username![0]
                                    : '?')
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author.displayName ??
                              post.author.username ??
                              tr('common.post'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          tr('social.post_manage'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // ── Author Management Options ───────────────────────────────────
            if (isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(tr('social.edit_post')),
                subtitle: Text(tr('social.edit_post_subtitle')),
                onTap: () {
                  Navigator.pop(context);
                  _showEditPostDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined),
                title: Text(tr('social.pin_post')),
                subtitle: Text(tr('social.pin_post_subtitle')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('social.post_pinned'))),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  post.allowDownloads ? Icons.cloud_download_outlined : Icons.cloud_off_outlined,
                  color: post.allowDownloads ? Colors.green : Colors.grey,
                ),
                title: Text(
                  post.allowDownloads
                      ? 'Media Downloads: Allowed'
                      : 'Media Downloads: Disabled',
                ),
                subtitle: Text(
                  post.allowDownloads
                      ? 'Others can download media with your attribution'
                      : 'Others cannot download media from this post',
                ),
                trailing: Switch(
                  value: post.allowDownloads,
                  onChanged: (val) async {
                    Navigator.pop(context);
                    try {
                      final dio = ref.read(apiClientProvider);
                      await dio.patch(
                        '/posts/${post.id}',
                        data: {'allowDownloads': val},
                      );
                      ref.invalidate(profilePostsProvider(post.author.id));
                      onPostUpdated?.call();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(val
                                ? 'Downloads enabled for this post'
                                : 'Downloads disabled for this post'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update download setting: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  tr('social.delete_post'),
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: Text(tr('social.delete_post_subtitle')),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, ref);
                },
              ),
              const Divider(height: 16),
            ],

            // ── General Options ─────────────────────────────────────────────
            if (post.media.isNotEmpty)
              ListTile(
                leading: Icon(
                  Icons.download_rounded,
                  color: post.allowDownloads ? theme.colorScheme.primary : Colors.grey,
                ),
                title: Text(
                  post.allowDownloads
                      ? 'Download Media (with Watermark)'
                      : 'Download Disabled',
                ),
                subtitle: Text(
                  post.allowDownloads
                      ? 'Save with Zikire Kdusan logo & @${post.author.username ?? "user"}'
                      : 'The publisher has disabled downloads.',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  if (!post.allowDownloads) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('The publisher has disabled downloads.'),
                      ),
                    );
                    return;
                  }
                  await ref
                      .read(downloadServiceProvider.notifier)
                      .downloadPostMedia(post: post, context: context);
                },
              ),
            ListTile(
              leading: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? Colors.amber : null,
              ),
              title: Text(isSaved ? tr('social.unsave') : tr('social.save')),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(saveProvider.notifier).toggleSave(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSaved ? tr('social.unsaved') : tr('social.saved'),
                      ),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: Text(tr('social.share_post')),
              onTap: () {
                Navigator.pop(context);
                ShareButton(postId: post.id, title: post.content);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(tr('social.copy_link')),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                  ClipboardData(
                    text: AppLinkService.postLink(post.id),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('social.link_copied'))),
                );
              },
            ),
            if (!isAuthor) ...[
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.orange),
                title: Text(tr('social.report_post')),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('social.post_reported'))),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(
                  tr('social.mute_user', {'0': post.author.username ?? 'user'}),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        tr('social.muted_user', {
                          '0': post.author.username ?? 'user',
                        }),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditPostDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    final textController = MentionTextController(text: post.content ?? '');
    bool allowDownloads = post.allowDownloads;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('social.edit_post')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichTextComposer(
                  controller: textController,
                  child: TextField(
                    controller: textController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: tr('social.edit_post_hint'),
                      border: const OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow Downloads', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Others can download media with your attribution', style: TextStyle(fontSize: 12)),
                  value: allowDownloads,
                  onChanged: (val) {
                    setDialogState(() {
                      allowDownloads = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final newContent = textController.text.trim();
                Navigator.pop(dialogCtx);
                try {
                  final dio = ref.read(apiClientProvider);
                  await dio.patch(
                    '/posts/${post.id}',
                    data: {
                      'content': newContent,
                      'allowDownloads': allowDownloads,
                    },
                  );
                  ref.invalidate(profilePostsProvider(post.author.id));
                  onPostUpdated?.call();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('social.post_updated'))),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(tr('social.post_update_failed'))),
                    );
                  }
                }
              },
              child: Text(tr('common.save')),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('social.delete_post_confirm')),
        content: Text(tr('social.delete_post_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final dio = ref.read(apiClientProvider);
                await dio.delete('/posts/${post.id}');
                ref.invalidate(profilePostsProvider(post.author.id));
                onPostDeleted?.call();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('social.post_deleted'))),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr('social.post_delete_failed'))),
                  );
                }
              }
            },
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }
}
