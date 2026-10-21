// lib/features/books/presentation/screens/category_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/book_category_model.dart';
import '../providers/book_admin_providers.dart';
import '../providers/book_permissions_provider.dart';
import '../providers/books_providers.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  // ── Create or Edit Category Modal ───────────────────────────────────────

  void _showCategoryDialog({BookCategoryModel? category, String? defaultParentId}) {
    final isEditing = category != null;
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final nameAmCtrl = TextEditingController(text: category?.nameAm ?? '');
    final nameGezCtrl = TextEditingController(text: category?.nameGez ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final slugCtrl = TextEditingController(text: category?.slug ?? '');
    final sortCtrl =
        TextEditingController(text: (category?.sortOrder ?? 0).toString());
    bool isVisible = category?.isVisible ?? true;
    String? parentId = category?.parentId ?? defaultParentId;

    // Auto-generate slug from name if creating
    if (!isEditing) {
      nameCtrl.addListener(() {
        if (slugCtrl.text.isEmpty ||
            slugCtrl.text == _slugify(nameCtrl.text.substring(0, nameCtrl.text.length > 1 ? nameCtrl.text.length - 1 : 0))) {
          slugCtrl.text = _slugify(nameCtrl.text);
        }
      });
    }

    final categories = ref.read(adminCategoriesProvider).valueOrNull ?? [];
    // Collect non-descendant categories to prevent circular hierarchy
    final invalidParentIds = <String>{};
    if (isEditing) {
      invalidParentIds.add(category.id);
      _collectDescendantIds(category, invalidParentIds);
    }

    final availableParents = _flattenCategories(categories)
        .where((c) => !invalidParentIds.contains(c.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text(isEditing ? 'Edit Category' : 'Create Category'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Name (English / Primary) *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameAmCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name (Amharic)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: nameGezCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name (Ge\'ez)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: slugCtrl,
                      decoration: const InputDecoration(
                        labelText: 'URL Slug *',
                        hintText: 'e.g. patristics, liturgy',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Parent Category Selector
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: parentId,
                      decoration: const InputDecoration(
                        labelText: 'Parent Category (Hierarchy)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None (Root Category)'),
                        ),
                        ...availableParents.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              c.prefix + c.category.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => parentId = v),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: sortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              hintText: '0',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: isVisible,
                              onChanged: (v) =>
                                  setDialogState(() => isVisible = v ?? true),
                            ),
                            const Text('Visible'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final slug = slugCtrl.text.trim();
                  if (name.isEmpty || slug.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Name and slug are required'),
                      ),
                    );
                    return;
                  }

                  final data = <String, dynamic>{
                    'name': name,
                    if (nameAmCtrl.text.trim().isNotEmpty)
                      'nameAm': nameAmCtrl.text.trim(),
                    if (nameGezCtrl.text.trim().isNotEmpty)
                      'nameGez': nameGezCtrl.text.trim(),
                    if (descCtrl.text.trim().isNotEmpty)
                      'description': descCtrl.text.trim(),
                    'slug': slug,
                    'parentId': parentId,
                    'sortOrder': int.tryParse(sortCtrl.text.trim()) ?? 0,
                    'isVisible': isVisible,
                  };

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  try {
                    final repo = ref.read(booksRepositoryProvider);
                    if (isEditing) {
                      await repo.updateCategory(category.id, data);
                    } else {
                      await repo.createCategory(data);
                    }

                    ref.invalidate(adminCategoriesProvider);
                    ref.invalidate(bookCategoriesProvider);
                    ref.read(libraryProvider.notifier).refresh();

                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Category updated'
                              : 'Category created',
                        ),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString().replaceAll('Exception: ', '')}',
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Safe Delete Category Dialog ─────────────────────────────────────────

  void _showDeleteCategoryDialog(BookCategoryModel category) {
    final allCats = ref.read(adminCategoriesProvider).valueOrNull ?? [];
    final invalidTargetIds = <String>{category.id};
    _collectDescendantIds(category, invalidTargetIds);

    final availableTargets = _flattenCategories(allCats)
        .where((c) => !invalidTargetIds.contains(c.id))
        .toList();

    String? selectedReassignId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          return AlertDialog(
            title: Text('Delete "${category.name}"'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This category contains ${category.booksCount} published books and ${category.children.length} subcategories.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reassign existing books and subcategories to:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: selectedReassignId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Detach (Set to None / Top-level)'),
                      ),
                      ...availableTargets.map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.prefix + c.category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => selectedReassignId = v),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Note: The category will be safely archived. Books will not be deleted.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(ctx);

                  try {
                    final repo = ref.read(booksRepositoryProvider);
                    await repo.deleteCategory(
                      category.id,
                      reassignCategoryId: selectedReassignId,
                    );

                    ref.invalidate(adminCategoriesProvider);
                    ref.invalidate(bookCategoriesProvider);
                    ref.read(libraryProvider.notifier).refresh();

                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Category deleted safely'),
                      ),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error: ${e.toString().replaceAll('Exception: ', '')}',
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
                child: const Text('Delete Category'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perms = ref.watch(bookPermissionsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Manage Categories',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (perms.canManageCategories)
            FilledButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Category'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories created yet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Category'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminCategoriesProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryNode(theme, categories[index], 0, perms);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading categories: $err'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(adminCategoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryNode(
    ThemeData theme,
    BookCategoryModel category,
    int depth,
    BookPermissions perms,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 20.0, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: depth == 0
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                depth == 0 ? Icons.folder_outlined : Icons.subdirectory_arrow_right,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (category.nameAm != null &&
                            category.nameAm!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '(${category.nameAm})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                        if (!category.isVisible) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Hidden',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Slug: ${category.slug} • Order: ${category.sortOrder} • ${category.booksCount} books',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (perms.canManageCategories) ...[
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  tooltip: 'Add Subcategory',
                  onPressed: () => _showCategoryDialog(defaultParentId: category.id),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit',
                  onPressed: () => _showCategoryDialog(category: category),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: theme.colorScheme.error),
                  tooltip: 'Delete',
                  onPressed: () => _showDeleteCategoryDialog(category),
                ),
              ],
            ],
          ),
        ),
        // Render child categories
        for (final child in category.children)
          _buildCategoryNode(theme, child, depth + 1, perms),
      ],
    );
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  void _collectDescendantIds(BookCategoryModel cat, Set<String> ids) {
    for (final child in cat.children) {
      ids.add(child.id);
      _collectDescendantIds(child, ids);
    }
  }

  List<_FlatCategoryItem> _flattenCategories(List<BookCategoryModel> cats) {
    final list = <_FlatCategoryItem>[];
    void addRec(BookCategoryModel c, String prefix) {
      list.add(_FlatCategoryItem(category: c, prefix: prefix));
      for (final child in c.children) {
        addRec(child, '$prefix— ');
      }
    }

    for (final c in cats) {
      addRec(c, '');
    }
    return list;
  }
}

class _FlatCategoryItem {
  final BookCategoryModel category;
  final String prefix;
  final String id;

  _FlatCategoryItem({required this.category, required this.prefix})
      : id = category.id;
}
