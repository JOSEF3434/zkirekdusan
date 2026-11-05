// lib/features/books/presentation/screens/manage_dictionary_languages_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import '../../data/models/dictionary_model.dart';
import '../providers/book_permissions_provider.dart';
import '../providers/dictionary_providers.dart';

class ManageDictionaryLanguagesScreen extends ConsumerStatefulWidget {
  const ManageDictionaryLanguagesScreen({super.key});

  @override
  ConsumerState<ManageDictionaryLanguagesScreen> createState() =>
      _ManageDictionaryLanguagesScreenState();
}

class _ManageDictionaryLanguagesScreenState
    extends ConsumerState<ManageDictionaryLanguagesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showLanguageDialog({DictionaryLanguageModel? language}) {
    final isEditing = language != null;
    final codeCtrl = TextEditingController(text: language?.code ?? '');
    final nameCtrl = TextEditingController(text: language?.name ?? '');
    final nativeNameCtrl = TextEditingController(text: language?.nativeName ?? '');
    final sortCtrl =
        TextEditingController(text: (language?.sortOrder ?? 0).toString());
    String direction = language?.direction ?? 'ltr';
    bool isEnabled = language?.isEnabled ?? true;
    bool isSaving = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final tr = ref.watch(trProvider);

          return AlertDialog(
            title: Text(isEditing
                ? tr('books.edit_language')
                : tr('books.add_language')),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: codeCtrl,
                      enabled: !isEditing,
                      decoration: InputDecoration(
                        labelText: '${tr('books.language_code')} *',
                        hintText: 'e.g. en, am, gez, ti, om, ar, fr',
                        border: const OutlineInputBorder(),
                        helperText: isEditing
                            ? 'Language code cannot be modified once created'
                            : 'Stable 2-3 letter ISO language code',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: '${tr('books.language_name')} *',
                        hintText: 'e.g. English, Amharic',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nativeNameCtrl,
                      decoration: InputDecoration(
                        labelText: '${tr('books.language_native_name')} *',
                        hintText: 'e.g. English, አማርኛ, ግዕዝ',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: direction,
                            decoration: InputDecoration(
                              labelText: tr('books.language_direction'),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'ltr',
                                child: Text(tr('books.ltr')),
                              ),
                              DropdownMenuItem(
                                value: 'rtl',
                                child: Text(tr('books.rtl')),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => direction = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr('books.language_enabled')),
                      subtitle: const Text(
                          'Allow this language to be selected for dictionaries'),
                      value: isEnabled,
                      onChanged: (v) => setDialogState(() => isEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                child: Text(tr('common.cancel')),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final code = codeCtrl.text.trim().toLowerCase();
                        final name = nameCtrl.text.trim();
                        final native = nativeNameCtrl.text.trim();
                        final sort = int.tryParse(sortCtrl.text.trim()) ?? 0;

                        if (code.isEmpty || name.isEmpty || native.isEmpty) {
                          setDialogState(() {
                            dialogError = 'Please fill in all required fields.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          dialogError = null;
                        });

                        try {
                          final notifier =
                              ref.read(adminLanguagesProvider.notifier);
                          if (isEditing) {
                            await notifier.updateLanguage(language.id, {
                              'name': name,
                              'nativeName': native,
                              'direction': direction,
                              'sortOrder': sort,
                              'isEnabled': isEnabled,
                            });
                          } else {
                            await notifier.createLanguage({
                              'code': code,
                              'name': name,
                              'nativeName': native,
                              'direction': direction,
                              'sortOrder': sort,
                              'isEnabled': isEnabled,
                            });
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            dialogError =
                                e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(DictionaryLanguageModel lang) async {
    final tr = ref.read(trProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('books.delete_language')),
        content: Text(
          'Are you sure you want to remove "${lang.name} (${lang.nativeName})"?\n\n'
          'Languages can only be removed if no uploaded dictionaries depend on them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(tr('common.remove')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(adminLanguagesProvider.notifier)
            .deleteLanguage(lang.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language "${lang.name}" removed successfully'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot Delete Language'),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);
    final bookPerms = ref.watch(bookPermissionsProvider);
    final languagesAsync = ref.watch(adminLanguagesProvider);

    // Backend RBAC check mirrored in UI: Non-admin users cannot access this screen
    if (!bookPerms.canManageLanguages) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('books.manage_languages'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Access Denied',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Only Super Admins and authorized Administrators can manage dictionary languages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('books.manage_languages')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(adminLanguagesProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLanguageDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(tr('books.add_language')),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by language code, English, or native name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            ),
          ),

          // Languages list
          Expanded(
            child: languagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(err.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(adminLanguagesProvider.notifier).refresh(),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              ),
              data: (languages) {
                final filtered = languages.where((l) {
                  if (_searchQuery.isEmpty) return true;
                  return l.code.contains(_searchQuery) ||
                      l.name.toLowerCase().contains(_searchQuery) ||
                      l.nativeName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No dictionary languages registered yet.'
                          : 'No languages match your search.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final lang = filtered[idx];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: lang.isEnabled
                                ? theme.colorScheme.primaryContainer
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lang.code.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: lang.isEnabled
                                  ? theme.colorScheme.onPrimaryContainer
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              lang.nativeName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${lang.name})',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  lang.direction.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.isEnabled ? 'Enabled' : 'Disabled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: lang.isEnabled
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order: ${lang.sortOrder}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              tooltip: tr('books.edit_language'),
                              onPressed: () =>
                                  _showLanguageDialog(language: lang),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              tooltip: tr('books.delete_language'),
                              onPressed: () => _confirmDelete(lang),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
