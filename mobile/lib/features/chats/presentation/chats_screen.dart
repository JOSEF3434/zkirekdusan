// lib/features/chats/presentation/chats_screen.dart
//
// Adaptive wrapper:
//  • Mobile  (< 600px)  → ChatHomeScreen  (unchanged)
//  • Tablet+ (≥ 600px)  → LargeScreenChatLayout  (3-panel Telegram style)

import 'package:flutter/material.dart';
import 'package:mobile/core/presentation/widgets/responsive_layout.dart';
import 'package:mobile/features/chats/presentation/screens/chat_home_screen.dart';
import 'package:mobile/features/chats/presentation/screens/large_screen_chat_layout.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      // Mobile: original single-panel behaviour, zero changes
      return const ChatHomeScreen();
    }
    // Tablet / Desktop: Telegram-style three-panel layout
    return const LargeScreenChatLayout();
  }
}
