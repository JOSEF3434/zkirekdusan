import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/presentation/providers/save_provider.dart';

class SaveButton extends ConsumerStatefulWidget {
  final String postId;
  final bool initialIsSaved;
  final double iconSize;
  final Color? defaultColor;
  final Color activeColor;

  const SaveButton({
    super.key,
    required this.postId,
    required this.initialIsSaved,
    this.iconSize = 28.0,
    this.defaultColor,
    this.activeColor = Colors.yellow,
  });

  @override
  ConsumerState<SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<SaveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(saveProvider.notifier)
          .seed(widget.postId, widget.initialIsSaved);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    ref.read(saveProvider.notifier).toggleSave(widget.postId);
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final saveStateMap = ref.watch(saveProvider);
    final isSaved = saveStateMap[widget.postId] ?? widget.initialIsSaved;
    final themeColor = Theme.of(context).iconTheme.color ?? Colors.black;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved
                  ? widget.activeColor
                  : (widget.defaultColor ?? themeColor),
              size: widget.iconSize,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Save',
            style: TextStyle(
              color: widget.defaultColor ?? themeColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
