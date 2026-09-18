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
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('story.camera_photo')),
                ),
                onTap: () =>
                    Navigator.of(context).pop(_pickImage(ImageSource.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('story.gallery_photo')),
                ),
                onTap: () => Navigator.of(context).pop(_pickMultipleImages()),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('story.video_option')),
                ),
                onTap: () =>
                    Navigator.of(context).pop(_pickVideo(ImageSource.camera)),
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('common.video')),
                ),
                onTap: () =>
                    Navigator.of(context).pop(_pickVideo(ImageSource.gallery)),
              ),
              ListTile(
                leading: const Icon(Icons.audiotrack),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('chat.attach.audio')),
                ),
                onTap: () => Navigator.of(context).pop(_pickAudio()),
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('chat.attach.files')),
                ),
                onTap: () => Navigator.of(context).pop(_pickFile()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: Consumer(
                  builder: (_, ref, _) =>
                      Text(ref.watch(trProvider)('common.cancel')),
                ),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
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
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        return [file.path!];
      }
    }
    return [];
  }

  Future<List<String>> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        return [file.path!];
      }
    }
    return [];
  }
}
