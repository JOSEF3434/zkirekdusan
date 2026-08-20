// lib/features/stories/presentation/widgets/story_comment_input.dart
import 'package:flutter/material.dart';

class StoryCommentInput extends StatefulWidget {
  final String? myReaction;
  final void Function(String text) onSendComment;
  final void Function(String reaction) onSendReaction;
  final void Function(bool isFocused) onFocusChanged;

  const StoryCommentInput({
    super.key,
    this.myReaction,
    required this.onSendComment,
    required this.onSendReaction,
    required this.onFocusChanged,
  });

  @override
  State<StoryCommentInput> createState() => _StoryCommentInputState();
}

class _StoryCommentInputState extends State<StoryCommentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      widget.onFocusChanged(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    widget.onSendComment(text);
    _controller.clear();
    _focusNode.unfocus();
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.myReaction != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text Input Field
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: 'Send message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button / Quick Like Button
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _handleSend,
              )
            else ...[
              // Heart Like Button
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                  color: isLiked ? Colors.redAccent : Colors.white,
                  size: 28,
                ),
                tooltip: 'Like story',
                onPressed: () {
                  widget.onSendReaction(isLiked ? 'UNLIKE' : 'LIKE');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
