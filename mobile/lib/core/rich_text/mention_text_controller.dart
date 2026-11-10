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
  /// Only searches within the last "word" before cursor — stops at the second
  /// whitespace boundary so we don't scan the entire document.
  int _lastTriggerIndex(String text, String triggerChar) {
    // We only care about trigger chars that appear after the most-recent
    // word boundary. Walk backwards from the end until we either find
    // the trigger at a valid position, or cross TWO whitespace runs
    // (meaning we've left the current word and the previous one).
    int whitespaceRuns = 0;
    for (int i = text.length - 1; i >= 0; i--) {
      final c = text[i];
      if (c == triggerChar) {
        // Must be at start OR preceded by whitespace / punctuation
        if (i == 0 || _isWordBoundary(text[i - 1])) {
          return i;
        }
        // Trigger character embedded in a word (e.g. email) — not a trigger
        return -1;
      }
      if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
        whitespaceRuns++;
        // After two whitespace boundaries we've gone too far back
        if (whitespaceRuns >= 2) return -1;
      }
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

  /// Dismiss the active trigger.
  /// If a # trigger was active, also removes the `#query` text from the
  /// input so the sheet doesn't immediately re-open when focus returns.
  void dismissTrigger() {
    if (_activeTrigger == MentionTrigger.hashContent) {
      _removeActiveTriggerText('#');
    } else if (_activeTrigger == MentionTrigger.atMention) {
      // Don't remove @ text — user may want to continue typing
    }
    _setTrigger(MentionTrigger.none, '');
  }

  /// Removes the trigger character and any partial query that follows it
  /// from the current cursor position.
  void _removeActiveTriggerText(String triggerChar) {
    final cursor = selection.baseOffset;
    if (cursor < 0) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final trigIdx = _lastTriggerIndex(before, triggerChar);
    if (trigIdx < 0) return;

    // Remove from trigger position to cursor
    final newText = before.substring(0, trigIdx) + after;
    final newCursor = trigIdx;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
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
