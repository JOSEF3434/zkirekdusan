import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/app/env/env.dart';

class ShareButton extends StatelessWidget {
  final String postId;
  final String? title;
  final double iconSize;
  final Color? defaultColor;

  const ShareButton({
    super.key,
    required this.postId,
    this.title,
    this.iconSize = 28.0,
    this.defaultColor,
  });

  void _handleShare(BuildContext context) {
    final link = '${Env.apiBaseUrl.replaceAll('/api', '')}/share/$postId';
    final shareText = title != null
        ? 'Check out this video on ዝክረ ክዱሳን: $title\n\n$link'
        : 'Check out this video on ዝክረ ክዱሳን!\n\n$link';

    Share.share(shareText, subject: title ?? 'Shared Video');
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).iconTheme.color ?? Colors.black;
    return GestureDetector(
      onTap: () => _handleShare(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.share, color: defaultColor ?? themeColor, size: iconSize),
          const SizedBox(height: 4),
          Text(
            'Share',
            style: TextStyle(
              color: defaultColor ?? themeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
