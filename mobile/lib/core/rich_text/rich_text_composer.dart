// lib/core/rich_text/rich_text_composer.dart
//
// Shared composer wrapper adding:
//   • @ mention autocomplete panel (Users, Groups, Channels) with keyboard nav
//   • # Global Content Search sheet (powered by SearchRepository)
//
// Preserves existing TextField behavior when no trigger panel is active.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/rich_text/content_search_sheet.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/providers/mention_suggestions_provider.dart';
import 'package:mobile/core/rich_text/suggestion_overlay.dart';

class RichTextComposer extends ConsumerStatefulWidget {
  final MentionTextController controller;
  final FocusNode? focusNode;
  final Widget child;
  final void Function(MentionSuggestion)? onMentionSelected;
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
    } else if (trigger == MentionTrigger.hashContent &&
        !_sheetOpen &&
        !_suppressHashTrigger) {
      setState(() {
        _currentTrigger = MentionTrigger.none;
        _sheetOpen = true;
      });
      _openContentSheet(query);
    } else if (trigger == MentionTrigger.none) {
      if (_currentTrigger != MentionTrigger.none) {
        setState(() => _currentTrigger = MentionTrigger.none);
      }
      ref.read(mentionSuggestionsProvider.notifier).clear();
    }
  }

  Future<void> _openContentSheet(String initialQuery) async {
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
      _suppressHashTrigger = true;
      widget.controller.dismissTrigger(removeHashText: true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _suppressHashTrigger = false;
      });
    }

    if (mounted) widget.focusNode?.requestFocus();
  }

  void _selectMention(MentionSuggestion suggestion) {
    widget.controller.insertMention(suggestion);
    widget.onMentionSelected?.call(suggestion);
    setState(() => _currentTrigger = MentionTrigger.none);
    ref.read(mentionSuggestionsProvider.notifier).clear();
    widget.focusNode?.requestFocus();
  }

  void _dismissAtPanel() {
    setState(() => _currentTrigger = MentionTrigger.none);
    widget.controller.dismissTrigger(removeHashText: false);
    ref.read(mentionSuggestionsProvider.notifier).clear();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (_currentTrigger != MentionTrigger.atMention) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final notifier = ref.read(mentionSuggestionsProvider.notifier);
    final suggState = ref.read(mentionSuggestionsProvider);

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _dismissAtPanel();
      return KeyEventResult.handled;
    }

    if (suggState.suggestions.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        notifier.moveHighlight(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        notifier.moveHighlight(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        final chosen = notifier.highlightedSuggestion;
        if (chosen != null) {
          _selectMention(chosen);
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsState = ref.watch(mentionSuggestionsProvider);
    final showPanel = _currentTrigger == MentionTrigger.atMention;

    return Focus(
      skipTraversal: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPanel)
            MentionSuggestionPanel(
              query: suggestionsState.query,
              suggestions: suggestionsState.suggestions,
              isLoading: suggestionsState.isLoading,
              hasSearched: suggestionsState.hasSearched,
              error: suggestionsState.error,
              highlightedIndex: suggestionsState.highlightedIndex,
              onSelect: _selectMention,
              onRetry: () => ref.read(mentionSuggestionsProvider.notifier).retry(),
              onDismiss: _dismissAtPanel,
            ),
          widget.child,
        ],
      ),
    );
  }
}
