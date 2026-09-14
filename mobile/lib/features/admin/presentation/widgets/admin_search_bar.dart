// lib/features/admin/presentation/widgets/admin_search_bar.dart

import 'package:flutter/material.dart';

class AdminSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;

  const AdminSearchBar({
    super.key,
    this.hintText = 'Search...',
    required this.onSearch,
    this.onClear,
  });

  @override
  State<AdminSearchBar> createState() => _AdminSearchBarState();
}

class _AdminSearchBarState extends State<AdminSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                  widget.onClear?.call();
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) {
        setState(() {});
        widget.onSearch(val.trim());
      },
    );
  }
}
