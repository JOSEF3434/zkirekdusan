import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/groups/presentation/providers/channel_subscribe_provider.dart';
import 'package:mobile/features/social/data/follow_repository.dart';
import 'package:mobile/features/social/data/social_repository.dart';
import 'package:mobile/features/social/domain/follow_model.dart';
import 'package:mobile/features/social/domain/owned_channel_model.dart';
import 'package:mobile/features/social/presentation/providers/follow_provider.dart';

final followersProvider =
    FutureProvider.family<PaginatedResponse<FollowerDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(followRepositoryProvider);
      return repo.getFollowers(userId);
    });

final followingProvider =
    FutureProvider.family<PaginatedResponse<FollowerDto>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(followRepositoryProvider);
      return repo.getFollowing(userId);
    });

/// Fetches suggested/popular video channels from GET /video-channels.
final suggestedChannelsProvider =
    FutureProvider<List<SuggestedChannelDto>>((ref) async {
      final repo = ref.read(followRepositoryProvider);
      try {
        return await repo.getSuggestedChannels(limit: 30);
      } catch (e) {
        debugPrint('[SuggestedChannels] Error fetching channels: $e');
        return [];
      }
    });

/// Fetches the list of video channels the current user is subscribed to.
/// Uses GET /video-subscriptions (returns channels list).
final mySubscribedChannelsProvider =
    FutureProvider<List<SuggestedChannelDto>>((ref) async {
      final repo = ref.read(followRepositoryProvider);
      try {
        return await repo.getMySubscribedChannels();
      } catch (e) {
        debugPrint('[MySubscribedChannels] Error: $e');
        return [];
      }
    });

final myOwnedChannelsProvider =
    FutureProvider<List<OwnedChannelModel>>((ref) async {
      final repo = ref.read(followRepositoryProvider);
      try {
        return await repo.getMyOwnedChannels();
      } catch (e) {
        debugPrint('[MyOwnedChannels] Error fetching owned channels: $e');
        return [];
      }
    });

class FollowersScreen extends ConsumerWidget {
  /// The user whose subscriptions/following list to show in the Subscriptions tab.
  /// If empty or null, falls back to the currently authenticated user's ID.
  final String profileId;
  final int initialTabIndex;

  const FollowersScreen({
    super.key,
    this.profileId = '',
    this.initialTabIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final myChannelsAsync = ref.watch(myOwnedChannelsProvider);
    final myChannels = myChannelsAsync.asData?.value ?? [];
    final hasOwnedChannels = myChannels.isNotEmpty;

    // Resolve the user ID: use provided profileId, or fall back to current user
    final authUser = ref.watch(authProvider).user;
    final resolvedProfileId =
        profileId.isNotEmpty ? profileId : (authUser?.id ?? '');

    // Tabs: Suggested | Subscriptions | [My Channels if owner]
    final tabCount = hasOwnedChannels ? 4 : 3;
    final safeInitialIndex = initialTabIndex.clamp(0, tabCount - 1);

    return DefaultTabController(
      key: ValueKey('channels_tabs_${hasOwnedChannels}_${resolvedProfileId}_$safeInitialIndex'),
      length: tabCount,
      initialIndex: safeInitialIndex,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('nav.channels', {'fallback': 'Channels'})),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorColor: const Color(0xFF00C6FF),
                      labelColor: const Color(0xFF00C6FF),
                      tabs: [
                        Tab(text: tr('channels.suggested', {'fallback': 'Suggested'})),
                        Tab(text: tr('channels.subscriptions', {'fallback': 'Subscriptions'})),
                        Tab(text: tr('social.tab_following', {'fallback': 'Following'})),
                        if (hasOwnedChannels)
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tr('channels.my_channels', {
                                    'fallback': 'My Channels',
                                  }),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${myChannels.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ResponsiveLayout.maxReadingWidth(
          maxWidth: 1000,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBarView(
            children: [
              // Tab 0: Suggested Channels
              _SuggestedChannelsList(
                provider: suggestedChannelsProvider,
              ),
              // Tab 1: Subscriptions — channels the user has subscribed to
              _SubscribedChannelsList(
                provider: mySubscribedChannelsProvider,
              ),
              // Tab 2: Following — users the current user follows
              _FollowList(
                provider: followingProvider(resolvedProfileId),
                emptyMessageKey: 'social.not_following',
                emptyFallback: 'Not following anyone yet.',
              ),
              if (hasOwnedChannels)
                _MyChannelsList(
                  channels: myChannels,
                  onRefresh: () async => ref.invalidate(myOwnedChannelsProvider),
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedChannelsList extends ConsumerStatefulWidget {
  final ProviderBase<AsyncValue<List<SuggestedChannelDto>>> provider;

  const _SuggestedChannelsList({required this.provider});

  @override
  ConsumerState<_SuggestedChannelsList> createState() =>
      _SuggestedChannelsListState();
}

class _SuggestedChannelsListState
    extends ConsumerState<_SuggestedChannelsList> {
  String _selectedFilter = 'All';
  final _filters = ['All', 'Most Popular', 'Most Subscribers', 'Most Videos', 'Newest'];

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(widget.provider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(widget.provider),
      child: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('Error loading channels'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(widget.provider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (channels) {
          // Client-side sort based on selected filter
          final sorted = List<SuggestedChannelDto>.from(channels);
          if (_selectedFilter == 'Most Popular' ||
              _selectedFilter == 'Most Subscribers') {
            sorted.sort((a, b) =>
                b.subscribersCount.compareTo(a.subscribersCount));
          } else if (_selectedFilter == 'Most Videos') {
            sorted.sort(
                (a, b) => b.videosCount.compareTo(a.videosCount));
          } else if (_selectedFilter == 'Newest') {
            sorted.sort((a, b) => b.id.compareTo(a.id));
          }

          if (sorted.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 48),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 72,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Discover Channels',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'No channels available yet. Check back soon!',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(widget.provider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter chips row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, i) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      final selected = _selectedFilter == f;
                      return FilterChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = f),
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${sorted.length} channel${sorted.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: sorted.length,
                  separatorBuilder: (_, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final ch = sorted[index];
                    return _SuggestedChannelCard(channel: ch);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuggestedChannelCard extends ConsumerStatefulWidget {
  final SuggestedChannelDto channel;

  const _SuggestedChannelCard({required this.channel});

  @override
  ConsumerState<_SuggestedChannelCard> createState() =>
      _SuggestedChannelCardState();
}

class _SuggestedChannelCardState
    extends ConsumerState<_SuggestedChannelCard> {
  late bool _isSubscribed;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.channel.isSubscribed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = widget.channel;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/channel/${ch.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Channel avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: ch.avatarUrl != null &&
                        ch.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(ch.avatarUrl!)
                    : null,
                child: ch.avatarUrl == null || ch.avatarUrl!.isEmpty
                    ? Text(
                        (ch.name ?? 'C').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel name
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ch.name ?? 'Unnamed Channel',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (ch.ownerUsername != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${ch.ownerUsername}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    // Stats row
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 13,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${ch.subscribersCount} subscribers',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (ch.videosCount > 0) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.play_circle_outline,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Text(
                            '${ch.videosCount} videos',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Subscribe / Subscribed button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSubscribed
                    ? OutlinedButton(
                        key: const ValueKey('subscribed'),
                        onPressed: () {
                          setState(() => _isSubscribed = false);
                          // TODO: call unsubscribe API
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          side: BorderSide(
                              color:
                                  theme.colorScheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Subscribed',
                            style: TextStyle(fontSize: 12)),
                      )
                    : FilledButton(
                        key: const ValueKey('subscribe'),
                        onPressed: () {
                          setState(() => _isSubscribed = true);
                          // TODO: call subscribe API
                          context.push('/channel/${ch.id}');
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor:
                              const Color(0xFF00C6FF),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Subscribe',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Subscribed Channels List ───────────────────────────────────────────────────

class _SubscribedChannelsList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<SuggestedChannelDto>>> provider;

  const _SubscribedChannelsList({required this.provider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(provider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      color: const Color(0xFF00C6FF),
      onRefresh: () async => ref.invalidate(provider),
      child: asyncList.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
        ),
        error: (e, _) => _buildErrorState(context, ref, theme, e),
        data: (channels) => channels.isEmpty
            ? _buildEmptyState(context, ref, theme)
            : _buildChannelList(context, ref, theme, channels),
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, ThemeData theme, Object e) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 56,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Could not load subscriptions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString().length > 80
                    ? '${e.toString().substring(0, 80)}…'
                    : e.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.subscriptions_outlined,
                  size: 44,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No subscriptions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Subscribe to channels to see them here.\nDiscover channels in the Suggested tab.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00C6FF)),
                  foregroundColor: const Color(0xFF00C6FF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelList(BuildContext context, WidgetRef ref, ThemeData theme,
      List<SuggestedChannelDto> channels) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Count header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                '${channels.length} subscribed channel${channels.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Channel cards
        Expanded(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: channels.length,
            separatorBuilder: (_, i) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _SubscribedChannelCard(
                channel: channels[index],
                isDark: isDark,
                onUnsubscribed: () => ref.invalidate(provider),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SubscribedChannelCard extends ConsumerStatefulWidget {
  final SuggestedChannelDto channel;
  final bool isDark;
  final VoidCallback? onUnsubscribed;

  const _SubscribedChannelCard({
    required this.channel,
    required this.isDark,
    this.onUnsubscribed,
  });

  @override
  ConsumerState<_SubscribedChannelCard> createState() =>
      _SubscribedChannelCardState();
}

class _SubscribedChannelCardState
    extends ConsumerState<_SubscribedChannelCard> {
  bool _isUnsubscribing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = widget.channel;
    final subscribeAsync = ref.watch(channelSubscribeProvider(ch.id));
    final isSubscribed =
        subscribeAsync.valueOrNull?.isSubscribed ?? true; // assume subscribed
    final isLoading =
        subscribeAsync.valueOrNull?.isLoading ?? _isUnsubscribing;

    return Card(
      elevation: 0,
      color: widget.isDark
          ? const Color(0xFF17212B)
          : theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/channel/${ch.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar ─────────────────────────────────────────────────
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.2),
                    backgroundImage: ch.avatarUrl != null &&
                            ch.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(ch.avatarUrl!)
                        : null,
                    child: ch.avatarUrl == null || ch.avatarUrl!.isEmpty
                        ? Text(
                            (ch.name ?? 'C').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C6FF),
                            ),
                          )
                        : null,
                  ),
                  // Subscribed indicator dot
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isDark
                              ? const Color(0xFF17212B)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // ── Info ───────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel name
                    Text(
                      ch.name ?? 'Unnamed Channel',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ch.ownerUsername != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${ch.ownerUsername}',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Stats chips
                    Wrap(
                      spacing: 10,
                      children: [
                        _StatPill(
                          icon: Icons.people_outline,
                          label:
                              '${_fmt(ch.subscribersCount)} subscribers',
                          isDark: widget.isDark,
                        ),
                        if (ch.videosCount > 0)
                          _StatPill(
                            icon: Icons.play_circle_outline,
                            label: '${_fmt(ch.videosCount)} videos',
                            isDark: widget.isDark,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // ── Action buttons ─────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Open channel
                  IconButton(
                    onPressed: () => context.push('/channel/${ch.id}'),
                    icon: const Icon(
                        Icons.arrow_forward_ios_rounded, size: 16),
                    tooltip: 'View channel',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFF00C6FF),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Unsubscribe button
                  if (isSubscribed)
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                setState(() => _isUnsubscribing = true);
                                await ref
                                    .read(channelSubscribeProvider(ch.id)
                                        .notifier)
                                    .unsubscribe();
                                setState(() => _isUnsubscribing = false);
                                widget.onUnsubscribed?.call();
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 0),
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.6),
                          ),
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.redAccent,
                                ),
                              )
                            : const Text('Unsubscribe',
                                style: TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _MyChannelsList extends ConsumerWidget {
  final List<OwnedChannelModel> channels;
  final Future<void> Function() onRefresh;

  const _MyChannelsList({
    required this.channels,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    if (channels.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv_off_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('channels.no_owned_channels', {
                    'fallback': 'You have not created any channels yet.',
                  }),
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: channels.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final ch = channels[index];
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (ch.groupId.isNotEmpty) {
                  context.push('/groups/${ch.groupId}');
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: ch.avatarUrl != null
                          ? CachedNetworkImageProvider(ch.avatarUrl!)
                          : null,
                      child: ch.avatarUrl == null
                          ? Text(
                              ch.name.isNotEmpty ? ch.name[0].toUpperCase() : 'C',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ch.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ch.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ch.isOwner ? 'Owner' : 'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.handle.startsWith('@') ? ch.handle : '@${ch.handle}',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${ch.subscribersCount} subscribers · ${ch.videosCount} videos',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        if (ch.groupId.isNotEmpty) {
                          context.push('/groups/${ch.groupId}');
                        }
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('View'),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FollowList extends ConsumerWidget {
  final ProviderBase<AsyncValue<PaginatedResponse<FollowerDto>>> provider;
  final String emptyMessageKey;
  final String? emptyFallback;

  const _FollowList({
    required this.provider,
    required this.emptyMessageKey,
    this.emptyFallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(provider);
    final theme = Theme.of(context);
    final tr = ref.watch(trProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(provider),
      child: asyncList.when(
        data: (response) {
          final users = response.data;
          if (users.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr(
                          emptyMessageKey,
                          {'fallback': emptyFallback ?? 'No users found.'},
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                onTap: () {
                  if (user.username != null && user.username!.isNotEmpty) {
                    context.push('/@${user.username}');
                  } else {
                    context.push('/profile/user/${user.id}');
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.displayName?[0].toUpperCase() ??
                              user.username?[0].toUpperCase() ??
                              '?',
                        )
                      : null,
                ),
                title: Text(
                  user.displayName ?? user.username ?? tr('common.user'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: user.username != null
                    ? Text('@${user.username}')
                    : null,
                trailing: _FollowButton(user: user),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('social.error', {'error': e.toString()})),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(provider),
                icon: const Icon(Icons.refresh),
                label: Text(tr('common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final FollowerDto user;
  const _FollowButton({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followStateAsync = ref.watch(followProvider(user.id));
    final tr = ref.watch(trProvider);
    final theme = Theme.of(context);

    final isFollowing =
        followStateAsync.valueOrNull?.isFollowing ?? user.isFollowing;
    final isLoading = followStateAsync.valueOrNull?.isLoading ?? false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isFollowing
          ? OutlinedButton(
              key: const ValueKey('following'),
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ref.read(followProvider(user.id).notifier).unfollow();
                    },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      tr('follow.following'),
                      style: const TextStyle(fontSize: 13),
                    ),
            )
          : FilledButton(
              key: const ValueKey('follow'),
              onPressed: isLoading
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      ref.read(followProvider(user.id).notifier).follow();
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      tr('follow.follow'),
                      style: const TextStyle(fontSize: 13),
                    ),
            ),
    );
  }
}
