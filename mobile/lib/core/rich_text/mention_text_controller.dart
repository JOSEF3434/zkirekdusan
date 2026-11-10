// lib/core/rich_text/mention_text_controller.dart
//
// A TextEditingController that detects active triggers at cursor:
//   - '@' followed by query → user/group/channel autocomplete
//   - '#' followed by query → Global Search content picker
//
// Protects against triggering inside:
//   - already-inserted tokens (@[type:uuid:label] or #[type:uuid:label])
//   - email addresses (user@domain.com)
//   - URLs (https://example.com#section or http://...)

import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

enum MentionTrigger { none, atMention, hashContent }

final RegExp richTextTokenRegex = RegExp(
  r'([@#])\[([a-z]+):([0-9a-f-]{36}):([^\]]+)\]',
  unicode: true,
);

class MentionTextController extends TextEditingController {
  MentionTrigger _activeTrigger = MentionTrigger.none;
  String _triggerQuery = '';

  MentionTrigger get activeTrigger => _activeTrigger;
  String get triggerQuery => _triggerQuery;

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
    if (cursor < 0 || cursor > v.text.length || !v.selection.isCollapsed) {
      _setTrigger(MentionTrigger.none, '');
      return;
    }

    // Never re-trigger when cursor is inside an already-inserted token
    for (final m in richTextTokenRegex.allMatches(v.text)) {
      if (cursor > m.start && cursor <= m.end) {
        _setTrigger(MentionTrigger.none, '');
        return;
      }
    }

    final textBefore = v.text.substring(0, cursor);
    final atIdx = _findActiveTriggerIndex(textBefore, '@');
    final hashIdx = _findActiveTriggerIndex(textBefore, '#');

    if (atIdx > hashIdx) {
      final query = textBefore.substring(atIdx + 1);
      if (!query.contains(RegExp(r'\s')) && !_looksLikeUrlOrToken(query)) {
        _setTrigger(MentionTrigger.atMention, query);
        return;
      }
    } else if (hashIdx > atIdx) {
      final query = textBefore.substring(hashIdx + 1);
      if (!query.contains(RegExp(r'\s')) && !_looksLikeUrlOrToken(query)) {
        _setTrigger(MentionTrigger.hashContent, query);
        return;
      }
    }

    _setTrigger(MentionTrigger.none, '');
  }

  bool _looksLikeUrlOrToken(String fragment) {
    return fragment.startsWith('[') || fragment.contains('://');
  }

  /// Scans backwards from the end of the current word only (stops at first
  /// whitespace run). Guarantees we only match a trigger in the active token
  /// under the cursor and never inside an email address or URL.
  int _findActiveTriggerIndex(String textBeforeCursor, String triggerChar) {
    for (int i = textBeforeCursor.length - 1; i >= 0; i--) {
      final c = textBeforeCursor[i];
      if (c == triggerChar) {
        if (i == 0) return 0;
        final prev = textBeforeCursor[i - 1];
        if (!_isWordBoundary(prev)) return -1; // e.g. foo@bar, example.com#top
        // Also avoid triggering immediately after URL schemes/paths on the same word
        return i;
      }
      if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
        return -1;
      }
    }
    return -1;
  }

  bool _isWordBoundary(String char) {
    return char == ' ' ||
        char == '\n' ||
        char == '\t' ||
        char == '\r' ||
        char == '(' ||
        char == '[' ||
        char == ',';
  }

  void _setTrigger(MentionTrigger trigger, String query) {
    if (_activeTrigger == trigger && _triggerQuery == query) return;
    _activeTrigger = trigger;
    _triggerQuery = query;
    onTriggerChanged?.call(trigger, query);
  }

  // ── Insert helpers ──────────────────────────────────────────────────────────

  void insertMention(MentionSuggestion suggestion) {
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final atIdx = _findActiveTriggerIndex(before, '@');
    if (atIdx < 0) return;

    final tokenText = suggestion.toToken();
    final newBefore = before.substring(0, atIdx) + tokenText;
    final spacer = (after.isEmpty || !after.startsWith(' ')) ? ' ' : '';
    final newText = '$newBefore$spacer$after';
    final newCursor = newBefore.length + spacer.length;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  void insertContentRef(ContentSearchItem item) {
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final hashIdx = _findActiveTriggerIndex(before, '#');
    if (hashIdx < 0) return;

    final tokenText = item.toToken();
    final newBefore = before.substring(0, hashIdx) + tokenText;
    final spacer = (after.isEmpty || !after.startsWith(' ')) ? ' ' : '';
    final newText = '$newBefore$spacer$after';
    final newCursor = newBefore.length + spacer.length;

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  /// Dismisses active trigger; if `#` was active, removes the `#query` text so
  /// the content sheet does not reopen when focus returns.
  void dismissTrigger({bool removeHashText = true}) {
    if (_activeTrigger == MentionTrigger.hashContent && removeHashText) {
      _removeActiveTriggerText('#');
    }
    _setTrigger(MentionTrigger.none, '');
  }

  void _removeActiveTriggerText(String triggerChar) {
    final cursor = selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    final before = text.substring(0, cursor);
    final after = text.substring(cursor);

    final trigIdx = _findActiveTriggerIndex(before, triggerChar);
    if (trigIdx < 0) return;

    final newText = before.substring(0, trigIdx) + after;
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: trigIdx),
    );
  }

  /// Plain readable text without token syntax.
  String get plainText => text.replaceAllMapped(
    richTextTokenRegex,
    (m) => '${m.group(1)}${m.group(4)}',
  );

  /// Extracts ONLY explicit `@[user:uuid:...]` mention IDs (ignores `#[user:...]`).
  List<String> extractMentionedUserIds() {
    final regex = RegExp(r'@\[user:([0-9a-f-]{36}):[^\]]+\]');
    return regex.allMatches(text).map((m) => m.group(1)!).toSet().toList();
  }
}
