// lib/features/stories/presentation/screens/story_creation_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/stories/presentation/providers/story_creation_provider.dart';

class StoryCreationScreen extends ConsumerStatefulWidget {
  const StoryCreationScreen({super.key});

  @override
  ConsumerState<StoryCreationScreen> createState() =>
      _StoryCreationScreenState();
}

class _StoryCreationScreenState extends ConsumerState<StoryCreationScreen> {
  final TextEditingController _captionController = TextEditingController();
  Uint8List? _previewBytes;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final notifier = ref.read(storyCreationProvider.notifier);
    await notifier.pickImage(source);
    final file = ref.read(storyCreationProvider).selectedFile;
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _previewBytes = bytes);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final notifier = ref.read(storyCreationProvider.notifier);
    await notifier.pickVideo(source);
    final file = ref.read(storyCreationProvider).selectedFile;
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _previewBytes = bytes);
    }
  }

  Future<void> _handleUpload() async {
    final notifier = ref.read(storyCreationProvider.notifier);
    notifier.setCaption(_captionController.text.trim());

    final success = await notifier.uploadStory();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story published successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyCreationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Create Story',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (state.selectedFile != null)
            TextButton(
              onPressed: state.isUploading ? null : _handleUpload,
              child: state.isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout.maxReadingWidth(
          maxWidth: 600,
          child: Column(
            children: [
              // Error banner
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Upload Progress Bar
              if (state.isUploading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: state.uploadProgress > 0
                            ? state.uploadProgress
                            : null,
                        color: theme.colorScheme.primary,
                        backgroundColor: Colors.white24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Uploading story... ${(state.uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // Media Preview or Media Picker Selector
              Expanded(
                child: state.selectedFile != null && _previewBytes != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          // Preview
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: state.isVideo
                                ? Container(
                                    color: Colors.grey[900],
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.videocam_rounded,
                                            size: 64,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Video Story Selected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Image.memory(
                                    _previewBytes!,
                                    fit: BoxFit.contain,
                                  ),
                          ),

                          // Change media button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.change_circle_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              onPressed: () {
                                ref
                                    .read(storyCreationProvider.notifier)
                                    .clearSelection();
                                setState(() => _previewBytes = null);
                              },
                            ),
                          ),
                        ],
                      )
                    : _buildMediaPicker(theme),
              ),

              // Caption input bar if file is selected
              if (state.selectedFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add a caption...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPicker(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Share a 24-Hour Story',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Photos and videos disappear automatically after 24 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 36),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOptionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery Photo',
                  color: theme.colorScheme.primary,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 16),
                _buildOptionButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera Photo',
                  color: theme.colorScheme.tertiary,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 16),
                _buildOptionButton(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  color: Colors.deepOrange,
                  onTap: () => _pickVideo(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
