// lib/features/library/presentation/continue_watching_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/media_experience/presentation/providers/continue_watching_provider.dart';
import 'package:mobile/features/media_experience/presentation/widgets/continue_watching_card.dart';

class ContinueWatchingScreen extends ConsumerWidget {
  const ContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(continueWatchingProvider);
    final tr = ref.watch(trProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('continue_watching.title'))),
      body: state.items.isEmpty
          ? Center(child: Text(tr('continue_watching.empty')))
          : ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final progress = state.items[index];
                return ContinueWatchingCard(progress: progress);
              },
            ),
    );
  }
}
