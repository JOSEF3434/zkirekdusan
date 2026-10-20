// lib/features/books/presentation/widgets/book_download_settings_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/book_download_settings_provider.dart';

/// Shows the Admin Book Download Destination Settings modal dialog
Future<void> showBookDownloadSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const BookDownloadSettingsDialog(),
  );
}

class BookDownloadSettingsDialog extends ConsumerStatefulWidget {
  const BookDownloadSettingsDialog({super.key});

  @override
  ConsumerState<BookDownloadSettingsDialog> createState() =>
      _BookDownloadSettingsDialogState();
}

class _BookDownloadSettingsDialogState
    extends ConsumerState<BookDownloadSettingsDialog> {
  late BookDownloadDestination _selectedDestination;
  final TextEditingController _noteController = TextEditingController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(bookDownloadSettingsProvider).setting;
    _selectedDestination = current.destination;
    _noteController.text = current.description ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await ref
        .read(bookDownloadSettingsProvider.notifier)
        .updateDestination(
          _selectedDestination,
          description: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Book download destination set to: ${_selectedDestination.label}',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(bookDownloadSettingsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Failed to update download destination setting'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(bookDownloadSettingsProvider);

    // Sync if loaded in background and not yet customized
    if (!_initialized) {
      _selectedDestination = state.setting.destination;
      _noteController.text = state.setting.description ?? '';
      _initialized = true;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(isDark ? 50 : 25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.folder_special_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Download Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure where downloaded books are saved across user devices.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Destination Cards
              _buildDestinationOption(
                destination: BookDownloadDestination.inApp,
                title: 'In-App Downloads (Default)',
                description:
                    'Books are securely cached in the app offline sandbox. Ideal for protected reading without exposing raw files.',
                icon: Icons.app_shortcut_rounded,
                isRecommended: true,
              ),
              const SizedBox(height: 12),
              _buildDestinationOption(
                destination: BookDownloadDestination.deviceFileManager,
                title: 'Device File Manager',
                description:
                    'Books are saved directly to the device Downloads directory (or browser download on Web) for external file management.',
                icon: Icons.save_alt_rounded,
              ),
              const SizedBox(height: 12),
              _buildDestinationOption(
                destination: BookDownloadDestination.both,
                title: 'Both In-App & Device File Manager',
                description:
                    'Books are retained in the app offline library AND exported to the user Downloads folder for maximum accessibility.',
                icon: Icons.devices_other_rounded,
              ),
              const SizedBox(height: 20),

              // Platform behavior info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : Colors.blueGrey.shade50.withAlpha(150),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.blueGrey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Platform Storage Locations',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPlatformDetail('Android', 'Downloads/ZikreBooks'),
                    _buildPlatformDetail('Desktop (Windows/Mac/Linux)', 'User Downloads/ZikreBooks'),
                    _buildPlatformDetail('Web', 'HTML5 Browser Download Save Prompt'),
                    _buildPlatformDetail('iOS', 'App Documents with Files App sharing'),
                    const SizedBox(height: 6),
                    Text(
                      '• Independent Deletion: Removing a book in the app will never delete external device files.\n• Existing downloads are preserved when switching options.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Optional Admin Notes
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Admin Note / Description (Optional)',
                  hintText: 'e.g. Set to Both for high-fidelity offline reading and backup',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: state.isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: state.isSaving ? null : _handleSave,
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(state.isSaving ? 'Saving...' : 'Apply Setting'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformDetail(String platform, String path) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $platform: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Expanded(
            child: Text(
              path,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationOption({
    required BookDownloadDestination destination,
    required String title,
    required String description,
    required IconData icon,
    bool isRecommended = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedDestination == destination;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDestination = destination;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withAlpha(isDark ? 40 : 20)
              : (isDark ? Colors.grey.shade900 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ignore: deprecated_member_use
            Radio<BookDownloadDestination>(
              value: destination,
              // ignore: deprecated_member_use
              groupValue: _selectedDestination,
              // ignore: deprecated_member_use
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDestination = val;
                  });
                }
              },
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withAlpha(35)
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.teal.shade400),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
