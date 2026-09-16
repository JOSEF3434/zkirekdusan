// lib/features/chats/presentation/widgets/message_composer.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
import 'package:mobile/features/chats/data/models/message_model.dart';
import 'package:mobile/features/chats/data/repositories/chat_repository_impl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class MessageComposer extends ConsumerStatefulWidget {
  final String conversationId;
  final FocusNode focusNode;
  final String? replyToMessageId;
  final VoidCallback? onCancelReply;
  final VoidCallback? onMessageSent;

  const MessageComposer({
    super.key,
    required this.conversationId,
    required this.focusNode,
    this.replyToMessageId,
    this.onCancelReply,
    this.onMessageSent,
  });

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _showEmojiPicker = false;
  bool _isSending = false;
  Timer? _typingTimer;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText) {
      _sendTypingIndicator();
    } else {
      _stopTypingIndicator();
    }
    setState(() {});
  }

  void _sendTypingIndicator() {
    _typingTimer?.cancel();
    ref.read(typingIndicatorProvider(widget.conversationId).notifier).startTyping();

    _typingTimer = Timer(const Duration(seconds: 3), () {
      _stopTypingIndicator();
    });
  }

  void _stopTypingIndicator() {
    _typingTimer?.cancel();
    ref.read(typingIndicatorProvider(widget.conversationId).notifier).stopTyping();
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F141C) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply Preview Banner
            if (widget.replyToMessageId != null) _buildReplyPreview(isDark),

            // Main Composer Row (Pill Bar matching Screenshot 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _isRecording ? _buildRecordingUI(isDark) : _buildInputUI(isDark),
            ),

            // Emoji Picker
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _controller.text += emoji.emoji;
                  },
                  config: Config(
                    height: 250,
                    checkPlatformCompatibility: true,
                    skinToneConfig: const SkinToneConfig(),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: isDark ? const Color(0xFF131822) : Colors.grey[100]!,
                      iconColor: Colors.grey,
                      iconColorSelected: const Color(0xFF00C6FF),
                    ),
                    bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181F2E) : Colors.grey[100],
        border: Border(
          left: const BorderSide(color: Color(0xFF00C6FF), width: 3.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 18, color: Color(0xFF00C6FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C6FF),
                  ),
                ),
                Text(
                  'Quoted message content',
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
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildInputUI(bool isDark) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      children: [
        // Camera / Attachment Button (matching Screenshot 2 camera/plus icon)
        GestureDetector(
          onTap: _showAttachmentOptions,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2230) : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 20,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text Input Pill (matching Screenshot 2 dark rounded field with "Respond...")
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2230) : Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Respond...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() => _showEmojiPicker = false);
                      }
                    },
                  ),
                ),

                // Emoji Button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard_rounded
                        : Icons.sentiment_satisfied_alt_rounded,
                    size: 22,
                    color: _showEmojiPicker
                        ? const Color(0xFF00C6FF)
                        : Colors.grey[500],
                  ),
                  onPressed: () {
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                    if (!_showEmojiPicker) {
                      widget.focusNode.requestFocus();
                    } else {
                      widget.focusNode.unfocus();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send or Voice Mic Button — tap to send text; tap mic to toggle recording
        GestureDetector(
          onTap: hasText
              ? _sendTextMessage
              : (_isRecording ? _stopRecording : _startRecording),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: (hasText || _isRecording)
                  ? LinearGradient(
                      colors: _isRecording
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF2DD4BF), const Color(0xFF06B6D4)],
                    )
                  : null,
              color: (!hasText && !_isRecording)
                  ? (isDark ? const Color(0xFF1B2230) : Colors.grey[200])
                  : null,
              shape: BoxShape.circle,
              boxShadow: (hasText || _isRecording)
                  ? [
                      BoxShadow(
                        color: (_isRecording
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF06B6D4))
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(11),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    hasText
                        ? Icons.send_rounded
                        : (_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                    color: (hasText || _isRecording)
                        ? Colors.white
                        : (isDark ? Colors.grey[300] : Colors.grey[700]),
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2230) : Colors.grey[200],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Flashing red dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          // Duration
          Text(
            _formatDuration(_recordingDuration),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),

          // Waveform bars simulation
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                16,
                (index) => Container(
                  width: 2.5,
                  height: ((index * 7) % 18 + 6).toDouble(),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C6FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Cancel
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
            onPressed: _cancelRecording,
          ),

          // Send Voice
          GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2DD4BF), Color(0xFF06B6D4)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black87,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();
    _stopTypingIndicator();

    try {
      await ref.read(chatMessagesProvider(widget.conversationId).notifier).sendMessage(
            content: text,
            replyToId: widget.replyToMessageId,
          );

      widget.onCancelReply?.call();
      widget.onMessageSent?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161C28)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AttachmentOption(
                icon: Icons.photo_library_rounded,
                color: const Color(0xFF00C6FF),
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              _AttachmentOption(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF10B981),
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _AttachmentOption(
                icon: Icons.insert_drive_file_rounded,
                color: const Color(0xFFF59E0B),
                label: 'Document',
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        await _uploadAndSendMedia(image.path, image.name, 'image/jpeg');
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        await _uploadAndSendMedia(
          file.path!,
          file.name,
          file.extension ?? 'application/octet-stream',
        );
      }
    } catch (e) {
      _showError('Failed to pick document: $e');
    }
  }

  Future<void> _uploadAndSendMedia(
      String filePath, String fileName, String mimeType, {int? durationSeconds}) async {
    setState(() => _isSending = true);

    try {
      final repository = ref.read(chatRepositoryProvider);
      final uploadResult = await repository.uploadChatMedia(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        conversationId: widget.conversationId,
      );

      final fileId = uploadResult['id'] as String;
      final serverUrl = (uploadResult['url'] as String?) ?? filePath;
      final isAudio = mimeType.startsWith('audio/');

      final initialAttachments = [
        MessageAttachmentModel(
          fileId: fileId,
          url: serverUrl.isNotEmpty ? serverUrl : filePath,
          fileType: _getMessageType(mimeType),
          mimeType: mimeType,
          originalName: fileName,
          duration: durationSeconds?.toDouble(),
        ),
      ];

      final voiceNote = isAudio
          ? MessageVoiceNoteModel(
              fileId: fileId,
              url: serverUrl.isNotEmpty ? serverUrl : filePath,
              duration: durationSeconds ?? 0,
            )
          : null;

      await ref
          .read(chatMessagesProvider(widget.conversationId).notifier)
          .sendMessage(
            attachmentIds: [fileId],
            type: _getMessageType(mimeType),
            initialAttachments: initialAttachments,
            voiceNote: voiceNote,
          );

      widget.onMessageSent?.call();
    } catch (e) {
      _showError('Failed to send media: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _getMessageType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'IMAGE';
    if (mimeType.startsWith('video/')) return 'VIDEO';
    if (mimeType.startsWith('audio/')) return 'AUDIO';
    return 'DOCUMENT';
  }

  Future<void> _startRecording() async {
    final hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      _showError('Microphone permission is required');
      return;
    }

    try {
      // ✅ Fix: must use an absolute path — relative filenames crash on Android/iOS
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
          numChannels: 1,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration = Duration(seconds: timer.tick);
          });
        }
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    final recordedDuration = _recordingDuration;
    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      if (path != null) {
        final durationSec = recordedDuration.inSeconds > 0 ? recordedDuration.inSeconds : 1;
        await _uploadAndSendMedia(
          path,
          'voice_${DateTime.now().millisecondsSinceEpoch}.m4a',
          'audio/m4a',
          durationSeconds: durationSec,
        );
      }
    } catch (e) {
      _showError('Failed to send voice: $e');
    } finally {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });
    }
  }

  void _cancelRecording() async {
    await _audioRecorder.stop();
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[300]
                    : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
