// lib/features/calendar/alephat/presentation/widgets/alephat_dynamic_media_section.dart
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/calendar/alephat/presentation/widgets/alephat_media_popup.dart';

class AlephatDynamicMediaSection extends ConsumerStatefulWidget {
  final List<TextEditingController> controllers;
  final VoidCallback onControllersChanged;
  final String title;
  final String helperText;

  const AlephatDynamicMediaSection({
    super.key,
    required this.controllers,
    required this.onControllersChanged,
    this.title = 'የተያያዙ ሚዲያዎች (Media - ድምጽ፣ ቪዲዮ፣ ምስል)',
    this.helperText =
        'የማንኛውም አይነት ሚዲያ ማስፈንጠሪያ (URL) ያስገቡ ወይም ፋይል ይስቀሉ',
  });

  @override
  ConsumerState<AlephatDynamicMediaSection> createState() =>
      _AlephatDynamicMediaSectionState();
}

class _AlephatDynamicMediaSectionState
    extends ConsumerState<AlephatDynamicMediaSection> {
  final Map<int, bool> _uploadingIndex = {};

  void _handleFieldChanged(int index, String value) {
    final controllers = widget.controllers;

    // If the last field now has text, dynamically append the next empty field
    if (index == controllers.length - 1 && value.trim().isNotEmpty) {
      controllers.add(TextEditingController(text: ''));
      widget.onControllersChanged();
    } else if (value.trim().isEmpty) {
      // If trailing empty fields exceed 1, collapse them
      while (controllers.length > 1 &&
          controllers.last.text.trim().isEmpty &&
          controllers[controllers.length - 2].text.trim().isEmpty) {
        final removed = controllers.removeLast();
        removed.dispose();
        widget.onControllersChanged();
      }
    }

    setState(() {});
  }

  Future<void> _pickAndUpload(int index) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      if (pickedFile.bytes == null && pickedFile.path == null) return;

      setState(() => _uploadingIndex[index] = true);

      final dio = ref.read(apiClientProvider);
      final filename =
          pickedFile.name.isNotEmpty ? pickedFile.name : 'media_upload';

      final formData = FormData.fromMap({
        'file': pickedFile.bytes != null
            ? MultipartFile.fromBytes(pickedFile.bytes!, filename: filename)
            : await MultipartFile.fromFile(pickedFile.path!, filename: filename),
      });

      final response = await dio.post(
        '/uploads/media',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );

      final resData = response.data;
      String? returnedUrl;
      if (resData is Map) {
        final dataMap = resData['data'] is Map ? resData['data'] : resData;
        returnedUrl = (dataMap['url'] ?? resData['url'])?.toString();
      }

      if (returnedUrl != null && returnedUrl.isNotEmpty) {
        widget.controllers[index].text = returnedUrl;
        _handleFieldChanged(index, returnedUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ፋይሉ በተሳካ ሁኔታ ተሰቅሏል')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ፋይሉን መጫን አልተቻለም፡ $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingIndex[index] = false);
      }
    }
  }

  void _removeField(int index) {
    final controllers = widget.controllers;
    if (controllers.length > 1) {
      final removed = controllers.removeAt(index);
      removed.dispose();
      if (controllers.isEmpty || controllers.last.text.trim().isNotEmpty) {
        controllers.add(TextEditingController(text: ''));
      }
      widget.onControllersChanged();
    } else {
      controllers[index].clear();
      widget.onControllersChanged();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controllers = widget.controllers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBadge(theme, Icons.audiotrack_rounded, 'ድምጽ', Colors.green),
                const SizedBox(width: 4),
                _buildBadge(theme, Icons.videocam_rounded, 'ቪዲዮ', Colors.orange),
                const SizedBox(width: 4),
                _buildBadge(theme, Icons.image_rounded, 'ምስል', Colors.purple),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.helperText,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final ctrl = controllers[index];
            final text = ctrl.text.trim();
            final isUploading = _uploadingIndex[index] ?? false;
            final detectedType = text.isNotEmpty
                ? detectMediaType(text)
                : AlephatMediaType.other;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    key: Key('dynamic_media_field_$index'),
                    controller: ctrl,
                    decoration: InputDecoration(
                      labelText: 'የሚዲያ ማስፈንጠሪያ ${index + 1} (Audio, Video, Image...)',
                      hintText: 'https://.../file.mp3 ወይም ፋይል ይስቀሉ',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        text.isNotEmpty
                            ? getMediaTypeIcon(detectedType)
                            : Icons.perm_media_outlined,
                        color: text.isNotEmpty
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        size: 20,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUploading)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.file_upload_outlined, size: 20),
                              tooltip: 'ፋይል ይስቀሉ (Upload file)',
                              onPressed: () => _pickAndUpload(index),
                            ),
                          if (text.isNotEmpty || controllers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'አጽዳ/አስወግድ (Remove)',
                              onPressed: () => _removeField(index),
                            ),
                        ],
                      ),
                    ),
                    onChanged: (val) => _handleFieldChanged(index, val),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBadge(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
