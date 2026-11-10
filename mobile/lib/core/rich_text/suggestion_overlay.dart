// lib/core/rich_text/suggestion_overlay.dart
//
// Compact, responsive @ mention suggestion panel anchored above the composer.
// Displays loading, results (Users, Groups, Channels), empty state, or error+retry
// without ever disappearing silently or expanding into an oversized grey box.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';

class MentionSuggestionPanel extends StatelessWidget {
  final String query;
  final List<MentionSuggestion> suggestions;
  final bool isLoading;
  final bool hasSearched;
  final String? error;
  final int highlightedIndex;
  final void Function(MentionSuggestion) onSelect;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const MentionSuggestionPanel({
    super.key,
    required this.query,
    required this.suggestions,
    required this.isLoading,
    this.hasSearched = false,
    this.error,
    this.highlightedIndex = 0,
    required this.onSelect,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 240),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2235) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: _buildBody(context, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (error != null && suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error!,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Retry'),
              ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      );
    }

    if (isLoading && suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              query.isEmpty
                  ? 'Loading mentions…'
                  : 'Searching "@$query"…',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const Spacer(),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      );
    }

    if (!isLoading && hasSearched && suggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.person_search_rounded, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                query.isEmpty
                    ? 'No users, groups, or channels available'
                    : 'No matches for "@$query"',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          const LinearProgressIndicator(
            minHeight: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C6FF)),
          ),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: suggestions.length,
            itemBuilder: (context, i) => _SuggestionTile(
              suggestion: suggestions[i],
              isDark: isDark,
              isHighlighted: i == highlightedIndex,
              onTap: () => onSelect(suggestions[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final MentionSuggestion suggestion;
  final bool isDark;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.suggestion,
    required this.isDark,
    required this.isHighlighted,
    required this.onTap,
  });

  String get _typeLabel => switch (suggestion.type) {
    MentionEntityType.group => 'Group',
    MentionEntityType.channel => 'Channel',
    _ => 'User',
  };

  Color get _typeColor => switch (suggestion.type) {
    MentionEntityType.group => const Color(0xFF8B5CF6),
    MentionEntityType.channel => const Color(0xFF10B981),
    _ => const Color(0xFF00C6FF),
  };

  @override
  Widget build(BuildContext context) {
    final sub = suggestion.subtitle ??
        (suggestion.username.isNotEmpty ? '@${suggestion.username}' : '');

    return Material(
      color: isHighlighted
          ? const Color(0xFF00C6FF).withValues(alpha: isDark ? 0.14 : 0.09)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    suggestion.type == MentionEntityType.group ? 8 : 17,
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
                              fontSize: 13.5,
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
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _typeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _typeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initial = suggestion.displayName.isNotEmpty
        ? suggestion.displayName[0].toUpperCase()
        : '?';
    return Container(
      color: _typeColor.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: _typeColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
