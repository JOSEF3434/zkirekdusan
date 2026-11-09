// lib/core/rich_text/rich_text_renderer.dart
//
// Parses rich-text content strings containing @[type:id:label] and
// #[type:id:label] tokens and renders them as tappable InlineSpans.
//
// Falls back gracefully to plain Text for legacy content without tokens.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/internal_link_handler.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

// Token regex: matches @[type:uuid:label] or #[type:uuid:label]
// Supports labels with spaces, Amharic, Unicode, and punctuation.
final _tokenRegex = RegExp(
  r'([@#])\[([a-z]+):([0-9a-f-]{36}):([^\]]+)\]',
  unicode: true,
);

/// Parses a content string into a list of [RichTextEntity].
List<RichTextEntity> parseEntities(String content) {
  final entities = <RichTextEntity>[];
  for (final match in _tokenRegex.allMatches(content)) {
    final trigger = match.group(1)!;
    final typeStr = match.group(2)!;
    final id = match.group(3)!;
    final label = match.group(4)!;
    final type = MentionEntityTypeX.fromPrefix(typeStr);
    if (type == null) continue;

    // Validate trigger aligns with entity type
    final expectedTrigger = (type == MentionEntityType.user ||
            type == MentionEntityType.group ||
            type == MentionEntityType.channel)
        ? '@'
        : '#';
    if (trigger != expectedTrigger) continue;

    entities.add(RichTextEntity(
      start: match.start,
      end: match.end,
      type: type,
      id: id,
      label: label,
    ));
  }
  return entities;
}

/// Returns the plain-text representation of a rich-text string
/// (strips tokens, shows @username or #Title).
String stripTokens(String content) {
  return content.replaceAllMapped(_tokenRegex, (m) {
    final trigger = m.group(1)!;
    final label = m.group(4)!;
    return '$trigger$label';
  });
}

/// Reusable rich-text display widget.
///
/// Usage:
/// ```dart
/// RichTextRenderer(
///   content: message.content ?? '',
///   style: Theme.of(context).textTheme.bodyMedium,
/// )
/// ```
class RichTextRenderer extends StatelessWidget {
  final String content;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  const RichTextRenderer({
    super.key,
    required this.content,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    // Fast path: no tokens present — just render plain text
    if (!_tokenRegex.hasMatch(content)) {
      return Text(
        content,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final theme = Theme.of(context);
    final baseStyle = style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final effectiveLinkStyle = linkStyle ??
        baseStyle.copyWith(
          color: const Color(0xFF00C6FF),
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        );

    final spans = _buildSpans(content, baseStyle, effectiveLinkStyle, context);

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  List<InlineSpan> _buildSpans(
    String content,
    TextStyle base,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in _tokenRegex.allMatches(content)) {
      // Plain text before the token
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: content.substring(cursor, match.start),
          style: base,
        ));
      }

      final trigger = match.group(1)!;
      final typeStr = match.group(2)!;
      final id = match.group(3)!;
      final label = match.group(4)!;
      final type = MentionEntityTypeX.fromPrefix(typeStr);

      if (type != null) {
        final entity = RichTextEntity(
          start: match.start,
          end: match.end,
          type: type,
          id: id,
          label: label,
        );

        spans.add(TextSpan(
          text: '$trigger$label',
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => InternalLinkHandler.navigate(context, entity),
        ));
      } else {
        // Unknown type — render raw
        spans.add(TextSpan(text: match.group(0), style: base));
      }

      cursor = match.end;
    }

    // Remaining plain text after last token
    if (cursor < content.length) {
      spans.add(TextSpan(
        text: content.substring(cursor),
        style: base,
      ));
    }

    return spans;
  }
}
