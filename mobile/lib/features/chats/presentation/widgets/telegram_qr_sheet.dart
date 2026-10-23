// lib/features/chats/presentation/widgets/telegram_qr_sheet.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/utils/app_link_service.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class TelegramQrSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final String qrData;
  final AppLinkEntityType entityType;
  final IconData? fallbackIcon;

  const TelegramQrSheet({
    super.key,
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    required this.qrData,
    this.entityType = AppLinkEntityType.user,
    this.fallbackIcon,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? avatarUrl,
    required String qrData,
    AppLinkEntityType entityType = AppLinkEntityType.user,
    IconData? fallbackIcon,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TelegramQrSheet(
        title: title,
        subtitle: subtitle,
        avatarUrl: avatarUrl,
        qrData: qrData,
        entityType: entityType,
        fallbackIcon: fallbackIcon,
      ),
    );
  }

  String _typeLabel() {
    switch (entityType) {
      case AppLinkEntityType.group:
      case AppLinkEntityType.groupInvite:
        return 'Group QR Code';
      case AppLinkEntityType.channel:
        return 'Channel QR Code';
      case AppLinkEntityType.chat:
        return 'Chat QR Code';
      case AppLinkEntityType.user:
      default:
        return 'Profile QR Code';
    }
  }

  IconData _typeIcon() {
    if (fallbackIcon != null) return fallbackIcon!;
    switch (entityType) {
      case AppLinkEntityType.group:
      case AppLinkEntityType.groupInvite:
        return Icons.group_rounded;
      case AppLinkEntityType.channel:
        return Icons.campaign_rounded;
      case AppLinkEntityType.chat:
        return Icons.chat_bubble_rounded;
      case AppLinkEntityType.user:
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF17212B) : Colors.white;
    final cleanDisplayUrl = AppLinkService.displayLink(qrData);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1621) : Colors.grey[100],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title with Entity Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _typeIcon(),
                  size: 20,
                  color: const Color(0xFF00C6FF),
                ),
                const SizedBox(width: 8),
                Text(
                  _typeLabel(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // QR Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Real Scannable QR Matrix with Center Badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C6FF).withValues(alpha: 0.15),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          padding: EdgeInsets.zero,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          gapless: true,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0072FF),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0E1621),
                          ),
                        ),
                      ),

                      // Center Avatar / Badge overlay
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF00C6FF),
                          backgroundImage:
                              (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
                                  ? CachedNetworkImageProvider(avatarUrl!)
                                  : null,
                          child: (avatarUrl == null || avatarUrl!.trim().isEmpty)
                              ? (title.isNotEmpty
                                  ? Text(
                                      title[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : Icon(
                                      _typeIcon(),
                                      size: 18,
                                      color: Colors.black,
                                    ))
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Name / Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle / handle (e.g. @sara_bi or group slug)
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF00C6FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Clickable Canonical URL chip
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0E1621)
                            : Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.link_rounded,
                            size: 16,
                            color: Color(0xFF00C6FF),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              cleanDisplayUrl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons: Copy Link & Share Link
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: qrData));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('common.copy')),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.white
                          : const Color(0xFF0072FF),
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFF0072FF).withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final shareMessage = '$title\n$qrData';
                      await Share.share(shareMessage, subject: title);
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Consumer(
                      builder: (_, ref, _) =>
                          Text(ref.watch(trProvider)('profile.qr_and_share')),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00C6FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scan QR Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/qr-scan');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF232E3C)
                      : Colors.grey.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0xFF00C6FF),
                  size: 20,
                ),
                label: Text(
                  'Scan another QR Code',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
