// lib/features/chats/presentation/providers/chat_socket_lifecycle_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:mobile/features/chats/data/datasources/messaging_socket_service.dart';

/// Manages the connection lifecycle of MessagingSocketService based on authentication state.
final chatSocketLifecycleProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final socketService = ref.watch(messagingSocketServiceProvider);

  if (auth.status == AuthStatus.authenticated) {
    socketService.connect();
  } else {
    socketService.disconnect();
  }
});

