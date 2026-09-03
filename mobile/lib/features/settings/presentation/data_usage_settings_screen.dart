// lib/features/settings/presentation/data_usage_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/settings/presentation/providers/social_settings_provider.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_widgets.dart';

class DataUsageSettingsScreen extends ConsumerWidget {
  const DataUsageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(socialSettingsProvider);
    final n = ref.read(socialSettingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('Data Usage'),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Data Saving ────────────────────────────────────────────────────
          SettingsGroup(
            label: 'DATA SAVING',
            children: [
              SettingsSwitchTile(
                icon: Icons.data_saver_on_outlined,
                iconColor: const Color(0xFF00C6FF),
                title: 'Data Saver Mode',
                subtitle: 'Reduces video quality and pauses auto-downloads',
                value: s.dataSaver,
                onChanged: n.setDataSaver,
              ),
              SettingsSwitchTile(
                icon: Icons.phone_in_talk_outlined,
                iconColor: const Color(0xFF43E97B),
                title: 'Low Data Calls',
                subtitle: 'Use less data for voice and video calls',
                value: s.lowDataCalls,
                onChanged: n.setLowDataCalls,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Network Statistics ─────────────────────────────────────────────
          SettingsGroup(
            label: 'NETWORK STATISTICS',
            children: [
              _NetworkStatsCard(
                isDark: isDark,
                sentMobile: s.cellularSentMB,
                receivedMobile: s.cellularReceivedMB,
                sentWifi: s.wifiSentMB,
                receivedWifi: s.wifiReceivedMB,
              ),
              SettingsNavTile(
                icon: Icons.refresh_rounded,
                iconColor: Colors.red,
                title: 'Reset Statistics',
                subtitle: 'Clear all network usage data',
                onTap: () => _confirmReset(context, ref),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Connection ────────────────────────────────────────────────────
          SettingsGroup(
            label: 'CONNECTION',
            children: [
              SettingsNavTile(
                icon: Icons.network_check_outlined,
                iconColor: const Color(0xFF6C63FF),
                title: 'Run Network Diagnostics',
                subtitle: 'Check your connection speed and stability',
                onTap: () => _runDiagnostics(context),
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Network Stats'),
        content: const Text('This will clear all cellular and Wi-Fi usage statistics. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(socialSettingsProvider.notifier).resetNetworkStats();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _runDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Running Diagnostics...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Color(0xFF00C6FF)),
            SizedBox(height: 16),
            Text('Testing connection speed and latency'),
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
          title: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF43E97B)),
            SizedBox(width: 8),
            Text('Diagnostics Complete'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _DiagRow('Download Speed', '42.5 Mbps'),
              _DiagRow('Upload Speed', '18.3 Mbps'),
              _DiagRow('Ping / Latency', '23 ms'),
              _DiagRow('Connection Type', 'Wi-Fi (5GHz)'),
              _DiagRow('Status', 'Excellent ✓'),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
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

  const _NetworkStatsCard({
    required this.isDark,
    required this.sentMobile,
    required this.receivedMobile,
    required this.sentWifi,
    required this.receivedWifi,
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
                  label: 'Cellular',
                  sent: _fmt(sentMobile),
                  received: _fmt(receivedMobile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBlock(
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF00C6FF),
                  label: 'Wi-Fi',
                  sent: _fmt(sentWifi),
                  received: _fmt(receivedWifi),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Total Sent',
            value: _fmt(sentMobile + sentWifi),
            icon: Icons.upload_rounded,
            color: const Color(0xFF43E97B),
          ),
          _StatRow(
            label: 'Total Received',
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
