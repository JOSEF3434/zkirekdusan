// lib/core/rich_text/rich_text_composer.dart
//
// A self-contained composer widget that wraps a TextField (or any child) with:
//   • @ mention autocomplete panel (floats above the field)
//   • # content search sheet (opens as bottom sheet)
//
// Usage — replace a plain TextField block with:
//
//   RichTextComposer(
//     controller: _mentionController,       // MentionTextController
//     focusNode: widget.focusNode,
//     child: TextField(controller: _mentionController, ...),
//     onMentionSelected: (s) => _mentionController.insertMention(s),
//     onContentRefSelected: (c) => _mentionController.insertContentRef(c),
//   )
//
// The widget manages the suggestion panel visibility internally.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/content_search_sheet.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/providers/mention_suggestions_provider.dart';
import 'package:mobile/core/rich_text/suggestion_overlay.dart';

class RichTextComposer extends ConsumerStatefulWidget {
  /// Must be a [MentionTextController].
  final MentionTextController controller;

  final FocusNode? focusNode;

  /// The actual TextField widget — built by the caller.
  final Widget child;

  /// Called when a mention suggestion is selected (@ flow).
  final void Function(MentionSuggestion)? onMentionSelected;

  /// Called when a content reference is selected (# flow).
  final void Function(ContentSearchItem)? onContentRefSelected;

  const RichTextComposer({
    super.key,
    required this.controller,
    required this.child,
    this.focusNode,
    this.onMentionSelected,
    this.onContentRefSelected,
  });

  @override
  ConsumerState<RichTextComposer> createState() => _RichTextComposerState();
}

class _RichTextComposerState extends ConsumerState<RichTextComposer> {
  MentionTrigger _currentTrigger = MentionTrigger.none;
  bool _sheetOpen = false;
  /// Temporarily suppresses the # trigger after the sheet is dismissed
  /// to prevent an immediate re-open caused by residual trigger state.
  bool _suppressHashTrigger = false;

  @override
  void initState() {
    super.initState();
    widget.controller.onTriggerChanged = _onTriggerChanged;
  }

  @override
  void didUpdateWidget(RichTextComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.onTriggerChanged = null;
      widget.controller.onTriggerChanged = _onTriggerChanged;
    }
  }

  @override
  void dispose() {
    widget.controller.onTriggerChanged = null;
    super.dispose();
  }

  void _onTriggerChanged(MentionTrigger trigger, String query) {
    if (!mounted) return;

    if (trigger == MentionTrigger.atMention) {
      setState(() => _currentTrigger = trigger);
      ref.read(mentionSuggestionsProvider.notifier).search(query);
    } else if (trigger == MentionTrigger.hashContent && !_sheetOpen && !_suppressHashTrigger) {
      setState(() {
        _currentTrigger = MentionTrigger.none;
        _sheetOpen = true;
      });
      _openContentSheet(query);
    } else if (trigger == MentionTrigger.none) {
      setState(() => _currentTrigger = MentionTrigger.none);
      ref.read(mentionSuggestionsProvider.notifier).clear();
    }
  }

  Future<void> _openContentSheet(String initialQuery) async {
    // Unfocus to avoid keyboard fighting the sheet
    widget.focusNode?.unfocus();
    FocusScope.of(context).unfocus();

    final selected = await showContentSearchSheet(
      context,
      initialQuery: initialQuery,
    );

    _sheetOpen = false;

    if (selected != null && mounted) {
      widget.controller.insertContentRef(selected);
      widget.onContentRefSelected?.call(selected);
    } else if (mounted) {
      // User dismissed — remove the # trigger text so it doesn't re-open.
      // Also suppress the hash trigger briefly so the text change caused by
      // dismissTrigger() doesn't immediately re-open the sheet.
      _suppressHashTrigger = true;
      widget.controller.dismissTrigger();
      // Allow # to trigger again after the text-change settles
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _suppressHashTrigger = false;
      });
    }

    // Re-focus the text field after sheet closes
    if (mounted) widget.focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsState = ref.watch(mentionSuggestionsProvider);
    final showPanel = _currentTrigger == MentionTrigger.atMention;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // @ suggestion panel (above the composer)
        if (showPanel)
          MentionSuggestionPanel(
            suggestions: suggestionsState.suggestions,
            isLoading: suggestionsState.isLoading,
            onSelect: (suggestion) {
              widget.controller.insertMention(suggestion);
              widget.onMentionSelected?.call(suggestion);
              setState(() => _currentTrigger = MentionTrigger.none);
              ref.read(mentionSuggestionsProvider.notifier).clear();
            },
          ),
        // The actual text input widget (passed by caller)
        widget.child,
      ],
    );
  }
}
