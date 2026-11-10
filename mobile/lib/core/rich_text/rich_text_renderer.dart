// lib/core/rich_text/rich_text_renderer.dart
//
// Centralized interactive rich-text parser & renderer.
// Parses @[type:uuid:label] and #[type:uuid:label] inline tokens into
// tappable spans that open the destination entity via InternalLinkHandler,
// while preserving normal text, Amharic/Unicode, line breaks, and emojis.
// Disposes TapGestureRecognizers cleanly on rebuild and unmount.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/internal_link_handler.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';

/// Parses a content string into structured [RichTextEntity] objects.
List<RichTextEntity> parseEntities(String content) {
  final entities = <RichTextEntity>[];
  for (final match in richTextTokenRegex.allMatches(content)) {
    final trigger = match.group(1)!;
    final typeStr = match.group(2)!;
    final id = match.group(3)!;
    final label = match.group(4)!;
    final type = MentionEntityTypeX.fromPrefix(typeStr);
    if (type == null) continue;

    // `@` is valid for mentionable entities (user, group, channel);
    // `#` is valid for ALL Global Search content references (including user/group/channel refs).
    if (trigger == '@' &&
        type != MentionEntityType.user &&
        type != MentionEntityType.group &&
        type != MentionEntityType.channel) {
      continue;
    }

    entities.add(RichTextEntity(
      start: match.start,
      end: match.end,
      triggerChar: trigger,
      type: type,
      id: id,
      label: label,
    ));
  }
  return entities;
}

/// Converts inline tokens into clean readable plain text
/// (`@[user:uuid:jj]` -> `@jj`, `#[video:uuid:Test]` -> `#Test`)
/// for reply previews, chat list snippets, clipboard copy, and notifications.
String stripTokens(String content) {
  if (content.isEmpty) return content;
  return content.replaceAllMapped(richTextTokenRegex, (m) {
    final trigger = m.group(1)!;
    final label = m.group(4)!;
    return '$trigger$label';
  });
}

class RichTextRenderer extends StatefulWidget {
  final String content;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;
  final bool selectable;

  const RichTextRenderer({
    super.key,
    required this.content,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.start,
    this.selectable = false,
  });

  @override
  State<RichTextRenderer> createState() => _RichTextRendererState();
}

class _RichTextRendererState extends State<RichTextRenderer> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    if (widget.content.isEmpty) return const SizedBox.shrink();

    // Fast path: plain text without tokens
    if (!richTextTokenRegex.hasMatch(widget.content)) {
      if (widget.selectable) {
        return SelectableText(
          widget.content,
          style: widget.style,
          maxLines: widget.maxLines,
          textAlign: widget.textAlign,
        );
      }
      return Text(
        widget.content,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    final theme = Theme.of(context);
    final baseStyle = widget.style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final defaultLinkColor = theme.brightness == Brightness.dark
        ? const Color(0xFF38BDF8)
        : theme.colorScheme.primary;
    final effectiveLinkStyle = widget.linkStyle ??
        baseStyle.copyWith(
          color: defaultLinkColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: defaultLinkColor.withValues(alpha: 0.6),
        );

    final spans = _buildSpans(
      widget.content,
      baseStyle,
      effectiveLinkStyle,
      context,
    );

    if (widget.selectable) {
      return SelectableText.rich(
        TextSpan(children: spans),
        maxLines: widget.maxLines,
        textAlign: widget.textAlign,
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }

  List<InlineSpan> _buildSpans(
    String content,
    TextStyle base,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    final spans = <InlineSpan>[];
    final entities = parseEntities(content);
    int cursor = 0;

    for (final entity in entities) {
      if (entity.start > cursor) {
        spans.add(TextSpan(
          text: content.substring(cursor, entity.start),
          style: base,
        ));
      }

      final recognizer = TapGestureRecognizer()
        ..onTap = () => InternalLinkHandler.navigate(context, entity);
      _recognizers.add(recognizer);

      spans.add(TextSpan(
        text: entity.displayText,
        style: linkStyle,
        recognizer: recognizer,
      ));

      cursor = entity.end;
    }

    if (cursor < content.length) {
      spans.add(TextSpan(
        text: content.substring(cursor),
        style: base,
      ));
    }

    return spans;
  }
}
