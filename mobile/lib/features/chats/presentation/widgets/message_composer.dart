// lib/features/chats/presentation/widgets/message_composer.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:mobile/features/chats/presentation/providers/chat_messages_provider.dart';
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
    // Send typing indicator
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText) {
      _sendTypingIndicator();
    } else {
      _stopTypingIndicator();
    }
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

    return Column(
      children: [
        // Reply preview
        if (widget.replyToMessageId != null) _buildReplyPreview(),

        // Emoji picker
        if (_showEmojiPicker)
          SizedBox(
            height: 250,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _controller.text += emoji.emoji;
              },
              config: const Config(
                checkPlatformCompatibility: true,
              ),
            ),
          ),

        // Main composer
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 8 + MediaQuery.of(context).padding.bottom,
          ),
          child: _isRecording ? _buildRecordingUI() : _buildInputUI(theme),
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Message preview', // TODO: Get actual message
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onCancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildInputUI(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      children: [
        // Emoji button
        IconButton(
          icon: Icon(
            _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
            color: _showEmojiPicker ? theme.colorScheme.primary : Colors.grey[600],
          ),
          onPressed: () {
            setState(() => _showEmojiPicker = !_showEmojiPicker);
            if (!_showEmojiPicker) {
              widget.focusNode.requestFocus();
            }
          },
        ),

        // Text input
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Send Message',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onTap: () {
                      if (_showEmojiPicker) {
                        setState(() => _showEmojiPicker = false);
                      }
                    },
                  ),
                ),
                // Attachment button
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: Colors.grey[600],
                  ),
                  onPressed: _showAttachmentOptions,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send or Voice button
        GestureDetector(
          onTap: hasText ? _sendTextMessage : null,
          onLongPressStart: !hasText ? (_) => _startRecording() : null,
          onLongPressEnd: !hasText ? (_) => _stopRecording() : null,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasText || _isSending
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    hasText ? Icons.send : Icons.mic,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Recording indicator
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        
        // Waveform animation (simulated)
        Expanded(
          child: Row(
            children: List.generate(
              20,
              (index) => Container(
                width: 2,
                height: (index % 3 + 1) * 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),

        // Recording duration
        Text(
          _formatDuration(_recordingDuration),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(width: 16),

        // Cancel button
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: _cancelRecording,
        ),

        // Stop button
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
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
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
          ],
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

  Future<void> _uploadAndSendMedia(String filePath, String fileName, String mimeType) async {
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
      
      await ref.read(chatMessagesProvider(widget.conversationId).notifier).sendMessage(
            attachmentIds: [fileId],
            type: _getMessageType(mimeType),
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
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      if (path != null) {
        await _uploadAndSendMedia(path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a', 'audio/m4a');
      }
    } catch (e) {
      _showError('Failed to send voice message: $e');
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
