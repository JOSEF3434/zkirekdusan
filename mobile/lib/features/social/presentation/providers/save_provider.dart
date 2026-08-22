import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/social/data/social_repository.dart';

final saveProvider = NotifierProvider<SaveNotifier, Map<String, bool>>(() {
  return SaveNotifier();
});

class SaveNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {};
  }

  void seed(String postId, bool isSaved) {
    if (!state.containsKey(postId)) {
      Future.microtask(() {
        state = {...state, postId: isSaved};
      });
    }
  }

  Future<void> toggleSave(String postId, {bool isVideo = false}) async {
    final wasSaved = state[postId] ?? false;

    // Optimistic update
    state = {...state, postId: !wasSaved};

    try {
      final repo = ref.read(socialRepositoryProvider);
      if (isVideo) {
        await repo.toggleVideoBookmark(postId, saved: !wasSaved);
      } else {
        await repo.toggleSavePost(postId);
      }
    } catch (e) {
      // Revert on error
      state = {...state, postId: wasSaved};
    }
  }
}
