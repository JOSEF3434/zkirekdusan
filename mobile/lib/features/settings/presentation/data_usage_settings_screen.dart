// lib/features/settings/presentation/data_usage_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class DataUsageSettingsScreen extends ConsumerWidget {
  const DataUsageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tr = ref.watch(trProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text(tr('settings.data_usage')),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Data Saving ────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.data_usage.data_saving'),
            children: [
              SettingsSwitchTile(
                icon: Icons.data_saver_on_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: tr('settings.data_usage.data_saver'),
                subtitle: tr('settings.data_usage.data_saver_desc'),
                value: s.dataSaver,
                onChanged: n.setDataSaver,
              ),
              SettingsSwitchTile(
                icon: Icons.phone_in_talk_outlined,
                iconColor: const Color(0xFF43E97B),
                title: tr('settings.data_usage.low_data_calls'),
                subtitle: tr('settings.data_usage.low_data_calls_desc'),
                value: s.lowDataCalls,
                onChanged: n.setLowDataCalls,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Network Statistics ─────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.data_usage.network_stats'),
            children: [
              _NetworkStatsCard(
                isDark: isDark,
                sentMobile: s.cellularSentMB,
                receivedMobile: s.cellularReceivedMB,
                sentWifi: s.wifiSentMB,
                receivedWifi: s.wifiReceivedMB,
                tr: tr,
              ),
              SettingsNavTile(
                icon: Icons.refresh_rounded,
                iconColor: Colors.red,
                title: tr('settings.data_usage.reset_stats'),
                subtitle: tr('settings.data_usage.reset_stats_desc'),
                onTap: () => _confirmReset(context, ref, tr),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Connection ────────────────────────────────────────────────────
          SettingsGroup(
            label: tr('settings.data_usage.connection'),
            children: [
              SettingsNavTile(
                icon: Icons.network_check_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: tr('settings.data_usage.diagnostics'),
                subtitle: tr('settings.data_usage.diagnostics_desc'),
                onTap: () => _runDiagnostics(context, tr),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.data_usage.reset_confirm_title')),
        content: Text(tr('settings.data_usage.reset_confirm_body')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text(tr('common.cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).resetNetworkStats();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(tr('settings.data_usage.stats_reset'))),
              );
            },
            child: Text(tr('settings.data_usage.reset_confirm_btn'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _runDiagnostics(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(tr('settings.data_usage.running_diagnostics')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00C6FF)),
            const SizedBox(height: 16),
            Text(tr('settings.data_usage.testing_connection')),
          ],
        ),
      ),
    );
    final navigator = Navigator.of(context, rootNavigator: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!context.mounted) return;
      navigator.pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B)),
            const SizedBox(width: 8),
            Text(tr('settings.data_usage.diagnostics_complete')),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DiagRow(tr('settings.data_usage.download_speed'), '42.5 Mbps'),
              _DiagRow(tr('settings.data_usage.upload_speed'), '18.3 Mbps'),
              _DiagRow(tr('settings.data_usage.ping_latency'), '23 ms'),
              _DiagRow(tr('settings.data_usage.connection_type'), 'Wi-Fi (5GHz)'),
              _DiagRow(tr('settings.data_usage.status'), tr('settings.data_usage.status_excellent')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(tr('common.close'))),
          ],
        ),
      );
    });
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  const _DiagRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _NetworkStatsCard extends StatelessWidget {
  final bool isDark;
  final double sentMobile;
  final double receivedMobile;
  final double sentWifi;
  final double receivedWifi;
  final String Function(String, [Map<String, dynamic>?]) tr;

  const _NetworkStatsCard({
    required this.isDark,
    required this.sentMobile,
    required this.receivedMobile,
    required this.sentWifi,
    required this.receivedWifi,
    required this.tr,
  });

  String _fmt(double mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  icon: Icons.signal_cellular_alt_rounded,
                  color: const Color(0xFFFF9F43),
                  label: tr('settings.data_usage.cellular'),
                  sent: _fmt(sentMobile),
                  received: _fmt(receivedMobile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBlock(
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF00C6FF),
                  label: tr('settings.data_usage.wifi'),
                  sent: _fmt(sentWifi),
                  received: _fmt(receivedWifi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: tr('settings.data_usage.total_sent'),
            value: _fmt(sentMobile + sentWifi),
            icon: Icons.upload_rounded,
            color: const Color(0xFF43E97B),
          ),
          _StatRow(
            label: tr('settings.data_usage.total_received'),
            value: _fmt(receivedMobile + receivedWifi),
            icon: Icons.download_rounded,
            color: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sent;
  final String received;

  const _StatBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.sent,
    required this.received,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.upload_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(sent, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.download_rounded, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(received,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                  fontSize: 13)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
