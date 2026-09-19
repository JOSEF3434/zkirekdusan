// lib/features/calendar/presentation/widgets/media_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/core/utils/localization_service.dart';

class MediaPickerSheet extends StatelessWidget {
  const MediaPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('story.camera_photo')),
                      ),
                      onTap: () async {
                        final paths = await _pickImage(ImageSource.camera);
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('story.gallery_photo')),
                      ),
                      subtitle: const Text(
                        'Select multiple photos or videos',
                        style: TextStyle(fontSize: 11),
                      ),
                      onTap: () async {
                        final paths = await _pickMultipleImages();
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam_outlined),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('story.video_option')),
                      ),
                      onTap: () async {
                        final paths = await _pickVideo(ImageSource.camera);
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.video_collection_outlined),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('common.video')),
                      ),
                      onTap: () async {
                        final paths = await _pickVideo(ImageSource.gallery);
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.audiotrack_outlined),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('chat.attach.audio')),
                      ),
                      onTap: () async {
                        final paths = await _pickAudio();
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.attach_file_rounded),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('chat.attach.files')),
                      ),
                      onTap: () async {
                        final paths = await _pickFile();
                        if (context.mounted) {
                          Navigator.of(context).pop(paths);
                        }
                      },
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                    ListTile(
                      leading: const Icon(Icons.close),
                      title: Consumer(
                        builder: (_, ref, _) =>
                            Text(ref.watch(trProvider)('common.cancel')),
                      ),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image != null) {
      return [image.path];
    }
    return [];
  }

  Future<List<String>> _pickMultipleImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultipleMedia();
    return images.map((xFile) => xFile.path).toList();
  }

  Future<List<String>> _pickVideo(ImageSource source) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: source);
    if (video != null) {
      return [video.path];
    }
    return [];
  }

  Future<List<String>> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = <String>[];
      for (final f in result.files) {
        if (f.path != null) {
          paths.add(f.path!);
        } else if (f.bytes != null) {
          final xFile = XFile.fromData(f.bytes!, name: f.name);
          paths.add(xFile.path);
        }
      }
      return paths;
    }
    return [];
  }

  Future<List<String>> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: true,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final paths = <String>[];
      for (final f in result.files) {
        if (f.path != null) {
          paths.add(f.path!);
        } else if (f.bytes != null) {
          final xFile = XFile.fromData(f.bytes!, name: f.name);
          paths.add(xFile.path);
        }
      }
      return paths;
    }
    return [];
  }
}
