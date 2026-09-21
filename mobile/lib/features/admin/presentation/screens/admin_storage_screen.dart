// lib/features/admin/presentation/screens/admin_storage_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:video_player/video_player.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/core/utils/media_save_helper.dart';
import 'package:mobile/core/utils/media_url_resolver.dart';
import 'package:mobile/features/admin/data/admin_repository.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_stat_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:mobile/features/admin/presentation/widgets/admin_responsive_layout.dart';

class AdminStorageScreen extends ConsumerStatefulWidget {
  const AdminStorageScreen({super.key});

  @override
  ConsumerState<AdminStorageScreen> createState() => _AdminStorageScreenState();
}

class _AdminStorageScreenState extends ConsumerState<AdminStorageScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final res = await ref.read(adminRepositoryProvider).getStorageStats();
      setState(() {
        _stats = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatBytes(num bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Future<void> _openFiles(String fileType) async {
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _StorageFilesDialog(fileType: fileType, formatBytes: _formatBytes),
    );
    if (mounted) _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('admin.storage')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: AdminResponsiveLayout(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats
                    Row(
                      children: [
                        Expanded(
                          child: AdminStatCard(
                            title: 'Total Files',
                            value: '${_stats?['totalFiles'] ?? 0}',
                            icon: Icons.insert_drive_file_rounded,
                            color: Colors.cyan,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AdminStatCard(
                            title: 'Total Space Used',
                            value: _formatBytes(_stats?['totalSizeBytes'] ?? 0),
                            icon: Icons.storage_rounded,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Storage by Media Type
                    AdminSectionCard(
                      title: 'Storage Breakdown by Type',
                      subtitle: 'Media assets categorized by format',
                      child: Column(
                        children: ((_stats?['byType'] as List?) ?? []).map((t) {
                          return ListTile(
                            leading: const Icon(Icons.perm_media_outlined),
                            title: Text('${t['type']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${t['count']} files | ${_formatBytes(t['sizeBytes'] ?? 0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => _openFiles('${t['type']}'),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Storage by Provider
                    AdminSectionCard(
                      title: 'Storage Providers',
                      subtitle: 'Underlying cloud storage buckets',
                      child: Column(
                        children: ((_stats?['byProvider'] as List?) ?? []).map((
                          p,
                        ) {
                          return ListTile(
                            leading: const Icon(Icons.cloud_outlined),
                            title: Text('${p['provider']}'),
                            trailing: Text(
                              '${p['count']} files • ${_formatBytes(p['sizeBytes'] ?? 0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StorageFilesDialog extends ConsumerStatefulWidget {
  final String fileType;
  final String Function(num) formatBytes;

  const _StorageFilesDialog({
    required this.fileType,
    required this.formatBytes,
  });

  @override
  ConsumerState<_StorageFilesDialog> createState() =>
      _StorageFilesDialogState();
}

class _StorageFilesDialogState extends ConsumerState<_StorageFilesDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _files = [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(adminRepositoryProvider)
          .getStorageFiles(
            page: page,
            fileType: widget.fileType,
            search: _searchController.text,
          );
      final rawItems = result['items'] as List? ?? const [];
      if (!mounted) return;
      setState(() {
        _files = rawItems
            .whereType<Map>()
            .map((item) => item.cast<String, dynamic>())
            .toList();
        _page = (result['page'] as num?)?.toInt() ?? page;
        _total = (result['total'] as num?)?.toInt() ?? _files.length;
        _totalPages = (result['totalPages'] as num?)?.toInt() ?? 1;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load files. Please try again.';
      });
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final name = file['originalName'] ?? file['fileName'] ?? 'this file';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('This permanently removes "$name" from storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteStorageFile(file['id'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully.')),
        );
        await _loadFiles(page: _page);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete the file.')),
      );
    }
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    final url = MediaUrlResolver.resolve(file['url'] as String?);
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This file has no accessible URL.')),
        );
      }
      return;
    }

    final mimeType = (file['mimeType'] as String? ?? '').toLowerCase();
    if (mimeType.startsWith('image/') ||
        mimeType.startsWith('video/') ||
        mimeType.startsWith('audio/')) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => _AdminMediaViewer(file: file)));
      return;
    }

    try {
      final cached = await DefaultCacheManager().getSingleFile(url);
      await OpenFilex.open(cached.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this file.')),
      );
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> file) async {
    final url = MediaUrlResolver.resolve(file['url'] as String?);
    if (url == null || url.isEmpty) return;
    try {
      final cached = await DefaultCacheManager().getSingleFile(url);
      final name = (file['originalName'] as String?)?.trim();
      await MediaSaveHelper.saveFile(
        bytes: await cached.readAsBytes(),
        fileName: name == null || name.isEmpty ? 'downloaded_file' : name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${name ?? 'file'} successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download failed.')));
    }
  }

  void _showDetails(Map<String, dynamic> file) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${file['originalName'] ?? file['fileName'] ?? 'File'}'),
        content: SingleChildScrollView(
          child: SelectableText(
            [
              'Type: ${file['mimeType'] ?? 'Unknown'}',
              'Size: ${widget.formatBytes((file['size'] as num?) ?? 0)}',
              'Provider: ${file['provider'] ?? 'Unknown'}',
              'Status: ${file['status'] ?? 'Unknown'}',
              'Storage key: ${file['storageKey'] ?? 'Unknown'}',
              'URL: ${file['url'] ?? 'Unavailable'}',
            ].join('\n'),
          ),
        ),
        actions: [
          if (file['url'] is String && (file['url'] as String).isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: file['url'] as String),
                );
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('File URL copied.')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy URL'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.fileType} files ($_total)'),
      content: SizedBox(
        width: 720,
        height: 520,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadFiles(),
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadFiles();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _files.isEmpty
                  ? const Center(child: Text('No files found.'))
                  : ListView.separated(
                      itemCount: _files.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        final name =
                            file['originalName'] ??
                            file['fileName'] ??
                            'Unnamed file';
                        return ListTile(
                          leading: _fileIcon(file['mimeType'] as String?),
                          title: Text(
                            '$name',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${file['mimeType'] ?? 'Unknown'} | ${widget.formatBytes((file['size'] as num?) ?? 0)} | ${file['provider'] ?? 'Unknown'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _openFile(file),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'File details',
                                icon: const Icon(Icons.info_outline),
                                onPressed: () => _showDetails(file),
                              ),
                              IconButton(
                                tooltip: 'Download file',
                                icon: const Icon(Icons.download_outlined),
                                onPressed: () => _downloadFile(file),
                              ),
                              IconButton(
                                tooltip: 'Delete file',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteFile(file),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Page $_page of $_totalPages'),
                  IconButton(
                    onPressed: _page > 1
                        ? () => _loadFiles(page: _page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: _page < _totalPages
                        ? () => _loadFiles(page: _page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Icon _fileIcon(String? mimeType) {
    if (mimeType?.startsWith('video/') == true) {
      return const Icon(Icons.video_file_outlined, color: Colors.blue);
    }
    if (mimeType?.startsWith('audio/') == true) {
      return const Icon(Icons.audio_file_outlined, color: Colors.orange);
    }
    if (mimeType?.startsWith('image/') == true) {
      return const Icon(Icons.image_outlined, color: Colors.green);
    }
    return const Icon(Icons.insert_drive_file_outlined);
  }
}

class _AdminMediaViewer extends StatefulWidget {
  final Map<String, dynamic> file;

  const _AdminMediaViewer({required this.file});

  @override
  State<_AdminMediaViewer> createState() => _AdminMediaViewerState();
}

class _AdminMediaViewerState extends State<_AdminMediaViewer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  String? _error;

  String get _url =>
      MediaUrlResolver.resolve(widget.file['url'] as String?) ?? '';
  String get _mimeType =>
      (widget.file['mimeType'] as String? ?? '').toLowerCase();
  bool get _isVideo => _mimeType.startsWith('video/');
  bool get _isAudio => _mimeType.startsWith('audio/');

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  Future<void> _initializeMedia() async {
    try {
      if (_isVideo) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(_url));
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        setState(() {
          _videoController = controller;
          _isLoading = false;
        });
      } else if (_isAudio) {
        final player = AudioPlayer();
        await player.setUrl(_url);
        if (!mounted) {
          await player.dispose();
          return;
        }
        setState(() {
          _audioPlayer = player;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Could not load this media.';
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    try {
      final cached = await DefaultCacheManager().getSingleFile(_url);
      final name = (widget.file['originalName'] as String?)?.trim();
      await MediaSaveHelper.saveFile(
        bytes: await cached.readAsBytes(),
        fileName: name == null || name.isEmpty ? 'downloaded_file' : name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloaded ${name ?? 'file'} successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.file['originalName'] ?? widget.file['fileName'] ?? 'Media';
    return Scaffold(
      appBar: AppBar(
        title: Text('$name', maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: _download,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      backgroundColor: _isVideo || _isImage ? Colors.black : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _isImage
          ? Center(child: InteractiveViewer(child: Image.network(_url)))
          : _isVideo
          ? _buildVideo()
          : _buildAudio(),
    );
  }

  bool get _isImage => _mimeType.startsWith('image/');

  Widget _buildVideo() {
    final controller = _videoController!;
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton.filled(
              iconSize: 42,
              onPressed: () => setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              }),
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudio() {
    final player = _audioPlayer!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audio_file_outlined, size: 96),
          const SizedBox(height: 20),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return IconButton.filled(
                iconSize: 42,
                onPressed: playing ? player.pause : player.play,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) => Text(
              '${_formatDuration(snapshot.data ?? Duration.zero)} / ${_formatDuration(player.duration ?? Duration.zero)}',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }
}
