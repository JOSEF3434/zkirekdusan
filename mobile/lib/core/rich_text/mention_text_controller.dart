// lib/core/rich_text/mention_text_controller.dart
//
// A TextEditingController that tracks the current trigger state:
//   - '@' followed by a query  → user/group/channel autocomplete
//   - '#' followed by anything → content search sheet
//
// It also handles inserting mention tokens and content-reference tokens into
// the text at the correct cursor position.

import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

enum MentionTrigger { none, atMention, hashContent }

class MentionTextController extends TextEditingController {
  MentionTrigger _activeTrigger = MentionTrigger.none;
  String _triggerQuery = '';

  /// Current trigger (`@` or `#`), or [MentionTrigger.none].
  MentionTrigger get activeTrigger => _activeTrigger;

  /// The partial text typed after the trigger character.
  String get triggerQuery => _triggerQuery;

  /// Callback fired when trigger state changes (drives overlay visibility).
  /// Mutable so [RichTextComposer] can attach/detach without recreating the controller.
  void Function(MentionTrigger trigger, String query)? onTriggerChanged;

  MentionTextController({this.onTriggerChanged, String? text})
      : super(text: text ?? '');

  @override
  set value(TextEditingValue newValue) {
    super.value = newValue;
    _detectTrigger(newValue);
  }

  void _detectTrigger(TextEditingValue v) {
    final cursor = v.selection.baseOffset;
    if (cursor < 0 || !v.selection.isCollapsed) {
      _setTrigger(MentionTrigger.none, '');
      return;
    }

    final textBefore = v.text.substring(0, cursor);

    // Look backwards from cursor for the last unescaped @ or #
    final atIdx = _lastTriggerIndex(textBefore, '@');
    final hashIdx = _lastTriggerIndex(textBefore, '#');

    final lastAt = atIdx;
    final lastHash = hashIdx;

    if (lastAt > lastHash) {
      final query = textBefore.substring(lastAt + 1);
      // Don't trigger inside email addresses or if there's a space
      if (!query.contains(' ') && !query.contains('\n')) {
        _setTrigger(MentionTrigger.atMention, query);
        return;
      }
    } else if (lastHash > lastAt) {
      final query = textBefore.substring(lastHash + 1);
      if (!query.contains(' ') && !query.contains('\n')) {
        _setTrigger(MentionTrigger.hashContent, query);
        return;
      }
    }

    _setTrigger(MentionTrigger.none, '');
  }

  /// Finds the last occurrence of [triggerChar] in [text] that is preceded
  /// by a word boundary (space, newline, or start of string).
  int _lastTriggerIndex(String text, String triggerChar) {
    for (int i = text.length - 1; i >= 0; i--) {
      if (text[i] == triggerChar) {
        // Must be at start OR preceded by whitespace / punctuation
        if (i == 0 || _isWordBoundary(text[i - 1])) {
          return i;
        }
      }
      // A space means no trigger before cursor
      if (text[i] == ' ' || text[i] == '\n') return -1;
    }
    return -1;
  }

  bool _isWordBoundary(String char) {
    return char == ' ' || char == '\n' || char == '\t' || char == '\r';
  }

  void _setTrigger(MentionTrigger trigger, String query) {
    if (_activeTrigger == trigger && _triggerQuery == query) return;
    _activeTrigger = trigger;
    _triggerQuery = query;
    onTriggerChanged?.call(trigger, query);
  }

  // ── Insert helpers ──────────────────────────────────────────────────────────

  /// Replace the current `@query` trigger with the selected mention token.
  void insertMention(MentionSuggestion suggestion) {
    final cursor = selection.baseOffset;
    if (cursor < 0) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    // Find start of the trigger word
    final atIdx = _lastTriggerIndex(before, '@');
    if (atIdx < 0) return;

    final tokenText = suggestion.toToken();
    final newBefore = before.substring(0, atIdx) + tokenText;
    final newText = '$newBefore $after';
    final newCursor = newBefore.length + 1; // after the space

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Replace the current `#query` trigger with the selected content token.
  void insertContentRef(ContentSearchItem item) {
    final cursor = selection.baseOffset;
    if (cursor < 0) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final hashIdx = _lastTriggerIndex(before, '#');
    if (hashIdx < 0) return;

    final tokenText = item.toToken();
    final newBefore = before.substring(0, hashIdx) + tokenText;
    final newText = '$newBefore $after';
    final newCursor = newBefore.length + 1;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Dismiss any active trigger without changing text.
  void dismissTrigger() {
    _setTrigger(MentionTrigger.none, '');
  }

  /// Return the plain-text version (tokens stripped to @label / #label).
  /// Used for display preview and copy-to-clipboard.
  String get plainText {
    final tokenRegex = RegExp(
      r'([@#])\[([a-z]+):([0-9a-f-]{36}):([^\]]+)\]',
      unicode: true,
    );
    return text.replaceAllMapped(tokenRegex, (m) => '${m.group(1)}${m.group(4)}');
  }

  /// Extract all mentioned user IDs from the current text.
  /// Used to populate `mentionedUserIds` in the send-message request.
  List<String> extractMentionedUserIds() {
    final regex = RegExp(r'@\[user:([0-9a-f-]{36}):[^\]]+\]');
    return regex.allMatches(text).map((m) => m.group(1)!).toList();
  }
}
