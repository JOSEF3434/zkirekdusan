// lib/features/admin/presentation/widgets/admin_confirmation_dialog.dart

import 'package:flutter/material.dart';

class AdminConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final bool requireReason;

  const AdminConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.confirmColor = Colors.red,
    this.requireReason = false,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    Color confirmColor = Colors.red,
    bool requireReason = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AdminConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        confirmColor: confirmColor,
        requireReason: requireReason,
      ),
    );
  }

  @override
  State<AdminConfirmationDialog> createState() => _AdminConfirmationDialogState();
}

class _AdminConfirmationDialogState extends State<AdminConfirmationDialog> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: widget.requireReason ? 'Reason *' : 'Reason (optional)',
                hintText: 'Provide reason for this administrative action...',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              validator: (v) {
                if (widget.requireReason && (v == null || v.trim().isEmpty)) {
                  return 'A reason is required for this action.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: widget.confirmColor),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? true) {
              Navigator.of(context).pop(_reasonController.text.trim());
            }
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
