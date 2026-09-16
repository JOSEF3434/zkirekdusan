import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/presentation/screens/image_viewer_screen.dart';

class SharedMediaTabsView extends ConsumerStatefulWidget {
  final String conversationId;
  final bool isDark;
  final Function(String messageId)? onJumpToMessage;

  const SharedMediaTabsView({
    super.key,
    required this.conversationId,
    required this.isDark,
    this.onJumpToMessage,
  });

  @override
  ConsumerState<SharedMediaTabsView> createState() => _SharedMediaTabsViewState();
}

class _SharedMediaTabsViewState extends ConsumerState<SharedMediaTabsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversationId));
    final isDark = widget.isDark;

    return messagesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
          ),
        ),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Could not load shared media',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      ),
      data: (messages) {
        // Extract Media, Files, Voice, Links
        final mediaList = <_MediaItem>[];
        final fileList = <_FileItem>[];
        final voiceList = <_VoiceItem>[];
        final linkList = <_LinkItem>[];

        final urlRegex = RegExp(
          r'(https?:\/\/[^\s<>]+)',
          caseSensitive: false,
        );

        for (final msg in messages) {
          // 1. Attachments
          for (final att in msg.attachments) {
            final typeUpper = att.fileType.toUpperCase();
            final mimeLower = att.mimeType.toLowerCase();

            if (typeUpper == 'IMAGE' || mimeLower.contains('image')) {
              mediaList.add(_MediaItem(
                messageId: msg.id,
                attachment: att,
                isVideo: false,
                createdAt: msg.createdAt,
              ));
            } else if (typeUpper == 'VIDEO' || mimeLower.contains('video')) {
              mediaList.add(_MediaItem(
                messageId: msg.id,
                attachment: att,
                isVideo: true,
                createdAt: msg.createdAt,
              ));
            } else if (typeUpper == 'VOICE' || mimeLower.contains('audio')) {
              voiceList.add(_VoiceItem(
                messageId: msg.id,
                url: att.url,
                duration: att.duration?.toInt() ?? 0,
                createdAt: msg.createdAt,
              ));
            } else {
              fileList.add(_FileItem(
                messageId: msg.id,
                attachment: att,
                createdAt: msg.createdAt,
              ));
            }
          }

          // 2. Voice Note model
          if (msg.voiceNote != null) {
            voiceList.add(_VoiceItem(
              messageId: msg.id,
              url: msg.voiceNote!.url,
              duration: msg.voiceNote!.duration,
              createdAt: msg.createdAt,
            ));
          }

          // 3. Links inside message text
          if (msg.content != null && msg.content!.isNotEmpty) {
            final matches = urlRegex.allMatches(msg.content!);
            for (final match in matches) {
              final url = match.group(0);
              if (url != null && url.isNotEmpty) {
                linkList.add(_LinkItem(
                  messageId: msg.id,
                  url: url,
                  contentSnippet: msg.content!,
                  createdAt: msg.createdAt,
                ));
              }
            }
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF00C6FF),
                unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                indicatorColor: const Color(0xFF00C6FF),
                indicatorWeight: 2.5,
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
                tabs: [
                  Tab(text: 'Media (${mediaList.length})'),
                  Tab(text: 'Files (${fileList.length})'),
                  Tab(text: 'Voice (${voiceList.length})'),
                  Tab(text: 'Links (${linkList.length})'),
                ],
              ),
            ),

            // Tab Views container
            SizedBox(
              height: 280,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. Media Tab
                  _buildMediaGrid(mediaList, isDark),
                  // 2. Files Tab
                  _buildFilesList(fileList, isDark),
                  // 3. Voice Tab
                  _buildVoiceList(voiceList, isDark),
                  // 4. Links Tab
                  _buildLinksList(linkList, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaGrid(List<_MediaItem> items, bool isDark) {
    if (items.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.photo_library_outlined,
        title: 'No media shared',
        subtitle: 'Photos and videos will appear here',
        isDark: isDark,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final rawUrl = item.attachment.thumbnailUrl?.isNotEmpty == true
            ? item.attachment.thumbnailUrl!
            : item.attachment.url;
        final resolvedUrl = MediaUrlResolver.resolve(rawUrl) ?? rawUrl;

        return GestureDetector(
          onTap: () {
            if (!item.isVideo) {
              final allImages = items
                  .where((m) => !m.isVideo)
                  .map((m) => m.attachment)
                  .toList();
              final imgIndex = allImages.indexOf(item.attachment);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageViewerScreen(
                    images: allImages,
                    initialIndex: imgIndex >= 0 ? imgIndex : 0,
                  ),
                ),
              );
            } else {
              widget.onJumpToMessage?.call(item.messageId);
            }
          },
          onLongPress: () => widget.onJumpToMessage?.call(item.messageId),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: resolvedUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: isDark ? const Color(0xFF1E2638) : Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? const Color(0xFF1E2638) : Colors.grey[200],
                    child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                  ),
                ),
                if (item.isVideo)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesList(List<_FileItem> items, bool isDark) {
    if (items.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.insert_drive_file_outlined,
        title: 'No files shared',
        subtitle: 'Documents and files will appear here',
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final sizeStr = item.attachment.size != null
            ? _formatFileSize(item.attachment.size!)
            : 'File';
        final ext = item.attachment.originalName.contains('.')
            ? item.attachment.originalName.split('.').last.toUpperCase()
            : 'DOC';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                ext.length > 4 ? ext.substring(0, 4) : ext,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C6FF),
                ),
              ),
            ),
          ),
          title: Text(
            item.attachment.originalName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            '$sizeStr • ${DateFormat('MMM d').format(item.createdAt)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            color: const Color(0xFF00C6FF),
            tooltip: 'Jump to message',
            onPressed: () => widget.onJumpToMessage?.call(item.messageId),
          ),
          onTap: () => widget.onJumpToMessage?.call(item.messageId),
        );
      },
    );
  }

  Widget _buildVoiceList(List<_VoiceItem> items, bool isDark) {
    if (items.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.mic_none_rounded,
        title: 'No voice messages',
        subtitle: 'Audio and voice notes will appear here',
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final durStr = item.duration > 0
            ? '${item.duration ~/ 60}:${(item.duration % 60).toString().padLeft(2, '0')}'
            : 'Voice note';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.audiotrack_rounded, color: Color(0xFF00C6FF), size: 20),
          ),
          title: Text(
            'Voice Message ($durStr)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Text(
            DateFormat('MMM d, h:mm a').format(item.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            color: const Color(0xFF00C6FF),
            tooltip: 'Jump to message',
            onPressed: () => widget.onJumpToMessage?.call(item.messageId),
          ),
          onTap: () => widget.onJumpToMessage?.call(item.messageId),
        );
      },
    );
  }

  Widget _buildLinksList(List<_LinkItem> items, bool isDark) {
    if (items.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.link_rounded,
        title: 'No links shared',
        subtitle: 'Shared web links will appear here',
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
            ),
            child: const Icon(Icons.link_rounded, color: Color(0xFF00C6FF), size: 20),
          ),
          title: Text(
            item.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF00C6FF),
            ),
          ),
          subtitle: Text(
            DateFormat('MMM d, yyyy').format(item.createdAt),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 17),
                color: Colors.grey[400],
                tooltip: 'Copy Link',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: item.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                color: const Color(0xFF00C6FF),
                tooltip: 'Jump to message',
                onPressed: () => widget.onJumpToMessage?.call(item.messageId),
              ),
            ],
          ),
          onTap: () => widget.onJumpToMessage?.call(item.messageId),
        );
      },
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.grey[500]),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _MediaItem {
  final String messageId;
  final MessageAttachmentModel attachment;
  final bool isVideo;
  final DateTime createdAt;

  _MediaItem({
    required this.messageId,
    required this.attachment,
    required this.isVideo,
    required this.createdAt,
  });
}

class _FileItem {
  final String messageId;
  final MessageAttachmentModel attachment;
  final DateTime createdAt;

  _FileItem({
    required this.messageId,
    required this.attachment,
    required this.createdAt,
  });
}

class _VoiceItem {
  final String messageId;
  final String url;
  final int duration;
  final DateTime createdAt;

  _VoiceItem({
    required this.messageId,
    required this.url,
    required this.duration,
    required this.createdAt,
  });
}

class _LinkItem {
  final String messageId;
  final String url;
  final String contentSnippet;
  final DateTime createdAt;

  _LinkItem({
    required this.messageId,
    required this.url,
    required this.contentSnippet,
    required this.createdAt,
  });
}
