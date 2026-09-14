// lib/features/calendar/presentation/widgets/media_picker_sheet.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class MediaPickerSheet extends StatelessWidget {
  const MediaPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () =>
                  Navigator.of(context).pop(_pickImage(ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose Photos'),
              onTap: () => Navigator.of(context).pop(_pickMultipleImages()),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () =>
                  Navigator.of(context).pop(_pickVideo(ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Choose Video'),
              onTap: () =>
                  Navigator.of(context).pop(_pickVideo(ImageSource.gallery)),
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack),
              title: const Text('Choose Audio'),
              onTap: () => Navigator.of(context).pop(_pickAudio()),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Choose File'),
              onTap: () => Navigator.of(context).pop(_pickFile()),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.of(context).pop(),
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
