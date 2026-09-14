// lib/features/settings/presentation/cache_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class CacheSettingsScreen extends ConsumerStatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  ConsumerState<CacheSettingsScreen> createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends ConsumerState<CacheSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isClearing = false;
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _spinAnimation =
        Tween<double>(begin: 0, end: 1).animate(_spinController);
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _clearCache() async {
    final tr = ref.read(trProvider);
    setState(() => _isClearing = true);
    _spinController.repeat();
    await ref.read(socialSettingsProvider.notifier).clearAppCache();
    await Future.delayed(const Duration(seconds: 2));
    _spinController.stop();
    setState(() => _isClearing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B)),
              const SizedBox(width: 8),
              Text(tr('settings.cache.cleared_success')),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.cache')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cache Breakdown Donut ──────────────────────────────────────────
          _CacheSummaryCard(state: s, isDark: isDark, tr: tr),
          const SizedBox(height: 16),

          // ── Cache Breakdown Tiles ──────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.cache.breakdown'),
            children: [
              SettingsInfoTile(
                icon: Icons.video_file_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.cache.video'),
                trailing: _fmtMB(s.videoCacheMB),
              ),
              SettingsInfoTile(
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.cache.image'),
                trailing: _fmtMB(s.imageCacheMB),
              ),
              SettingsInfoTile(
                icon: Icons.audio_file_outlined,
                iconColor: const Color(0xFFFF9F43),
                title: tr('settings.cache.audio'),
                trailing: _fmtMB(s.audioCacheMB),
              ),
              SettingsInfoTile(
                icon: Icons.storage_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.cache.database'),
                trailing: _fmtMB(s.databaseMB),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Auto-Clear Settings ────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.cache.auto_clear_policy'),
            children: [
              SettingsDropdownTile(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFFFF6584),
                title: tr('settings.cache.keep_media'),
                value: s.keepMediaDuration,
                options: const ['3 Days', '1 Week', '2 Weeks', '1 Month', '3 Months', 'Forever'],
                optionLabels: {
                  '3 Days': tr('settings.cache.duration_3_days'),
                  '1 Week': tr('settings.cache.duration_1_week'),
                  '2 Weeks': tr('settings.cache.duration_2_weeks'),
                  '1 Month': tr('settings.cache.duration_1_month'),
                  '3 Months': tr('settings.cache.duration_3_months'),
                  'Forever': tr('settings.cache.duration_forever'),
                },
                onChanged: n.setKeepMediaDuration,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Clear Cache Button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isClearing
                  ? RotationTransition(
                      turns: _spinAnimation,
                      child: const Icon(Icons.cached_rounded, color: Colors.black),
                    )
                  : const Icon(Icons.delete_sweep_rounded, color: Colors.black),
              label: Text(
                _isClearing
                    ? tr('settings.cache.clearing')
                    : tr('settings.cache.clear_all', {'size': _fmtMB(s.totalCacheMB)}),
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C6FF),
                disabledBackgroundColor: const Color(0xFF00C6FF).withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _isClearing ? null : _clearCache,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              tr('settings.cache.clear_hint'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmtMB(double mb) {
    if (mb == 0) return '0 B';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }
}

// ── Cache Summary Card ───────────────────────────────────────────────────────
class _CacheSummaryCard extends StatelessWidget {
  final SocialSettingsState state;
  final bool isDark;
  final String Function(String, [Map<String, dynamic>?]) tr;

  const _CacheSummaryCard({
    required this.state,
    required this.isDark,
    required this.tr,
  });

  String _fmtMB(double mb) {
    if (mb == 0) return '0 B';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final total = state.totalCacheMB;
    final segments = [
      (state.videoCacheMB, const Color(0xFF00C6FF), tr('settings.cache.seg_video')),
      (state.imageCacheMB, const Color(0xFF43E97B), tr('settings.cache.seg_images')),
      (state.audioCacheMB, const Color(0xFFFF9F43), tr('settings.cache.seg_audio')),
      (state.databaseMB, const Color(0xFF6C63FF), tr('settings.cache.seg_data')),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                )
              ],
      ),
      child: Column(
        children: [
          Text(
            tr('settings.cache.total'),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            _fmtMB(total),
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00C6FF)),
          ),
          const SizedBox(height: 16),
          // Progress bar segments
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: total == 0
                    ? [
                        Expanded(
                          child: Container(color: Colors.grey.withValues(alpha: 0.2)),
                        )
                      ]
                    : segments
                        .where((e) => e.$1 > 0)
                        .map((e) => Flexible(
                              flex: (e.$1 / total * 100).round().clamp(1, 100),
                              child: Container(color: e.$2),
                            ))
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: segments.map((e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: e.$2, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text('${e.$3}: ${_fmtMB(e.$1)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}
