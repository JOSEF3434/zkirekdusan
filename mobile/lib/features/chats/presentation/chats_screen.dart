// lib/features/chats/presentation/chats_screen.dart
import 'package:flutter/material.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(icon: const Icon(Icons.video_call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(label: 'All', isSelected: true),
                const SizedBox(width: 8),
                _FilterChip(label: 'Primary', badgeCount: 3),
                const SizedBox(width: 8),
                _FilterChip(label: 'Groups'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Language'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Requests'),
              ],
            ),
          ),
          
          // Chat List Placeholder
          Expanded(
            child: ListView(
              children: [
                _ChatTile(
                  name: 'Emma Johnson',
                  message: 'Typing...',
                  time: '9:41 PM',
                  unreadCount: 2,
                  isVerified: true,
                  isOnline: true,
                  languages: ['EN', 'ES'],
                ),
                _ChatTile(
                  name: 'Liam Garcia',
                  message: 'That sounds amazing! 😍',
                  time: '9:30 PM',
                  unreadCount: 1,
                  isVerified: true,
                  isOnline: true,
                  languages: ['EN', 'FR'],
                ),
                _ChatTile(
                  name: 'Language Buddies',
                  message: 'Sofia: Can someone help me with this?',
                  time: '8:15 PM',
                  unreadCount: 5,
                  isGroup: true,
                  isMuted: true,
                ),
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'Real-time messaging coming in F5',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badgeCount;

  const _FilterChip({required this.label, this.isSelected = false, this.badgeCount});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (badgeCount != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
      selected: isSelected,
      onSelected: (_) {},
      showCheckmark: false,
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final bool isVerified;
  final bool isOnline;
  final bool isGroup;
  final bool isMuted;
  final List<String> languages;

  const _ChatTile({
    required this.name,
    required this.message,
    required this.time,
    this.unreadCount = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.isGroup = false,
    this.isMuted = false,
    this.languages = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Icon(isGroup ? Icons.group : Icons.person, size: 32, color: Colors.grey),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blue),
          ]
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: unreadCount > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (languages.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: languages.map((l) => Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(l, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
              )).toList(),
            ),
          ]
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          else if (isMuted)
            const Icon(Icons.volume_off, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
