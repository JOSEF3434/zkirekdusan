// lib/core/rich_text/suggestion_overlay.dart
//
// Animated mention suggestion panel that appears above the composer when
// the user types @.
//
// Usage: rendered as a Column child above the TextField (not a real Overlay)
// so it scrolls naturally and works on both mobile and web without Z-ordering
// issues.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class MentionSuggestionPanel extends StatelessWidget {
  final List<MentionSuggestion> suggestions;
  final bool isLoading;
  final void Function(MentionSuggestion) onSelect;

  const MentionSuggestionPanel({
    super.key,
    required this.suggestions,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isLoading && suggestions.isEmpty) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: isLoading && suggestions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C6FF),
                      ),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (context, i) =>
                    _SuggestionTile(
                      suggestion: suggestions[i],
                      isDark: isDark,
                      onTap: () => onSelect(suggestions[i]),
                    ),
              ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final MentionSuggestion suggestion;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.isDark,
    required this.onTap,
  });

  IconData get _typeIcon => switch (suggestion.type) {
        MentionEntityType.group => Icons.group_rounded,
        MentionEntityType.channel => Icons.play_circle_outline_rounded,
        _ => Icons.person_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            // Avatar
            SizedBox(
              width: 36,
              height: 36,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  suggestion.type == MentionEntityType.group ? 8 : 18,
                ),
                child: suggestion.avatarUrl != null &&
                        suggestion.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: suggestion.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => _fallbackAvatar(),
                      )
                    : _fallbackAvatar(),
              ),
            ),
            const SizedBox(width: 10),
            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          suggestion.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (suggestion.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF00C6FF),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    '@${suggestion.username}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Type badge
            Icon(
              _typeIcon,
              size: 16,
              color: isDark
                  ? Colors.grey[500]
                  : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initial = suggestion.displayName.isNotEmpty
        ? suggestion.displayName[0].toUpperCase()
        : '?';
    return Container(
      color: const Color(0xFF00C6FF).withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Color(0xFF00C6FF),
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
