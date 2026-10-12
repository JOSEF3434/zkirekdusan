// lib/features/security/presentation/providers/media_activity_provider.dart
//
// Centralized media-activity registry for the App Lock inactivity policy.
//
// PURPOSE
// -------
// Tracks whether the user is actively watching a foreground media session
// (prerecorded video or live stream).  While any session is active the
// inactivity countdown in [AppLockNotifier] is suspended; the full configured
// countdown restarts the moment all active sessions end.
//
// DESIGN RULES
// ------------
// * A session is "active" only while genuine media is being consumed in the
//   foreground.  Stale flags, failed players, and terminated streams must never
//   hold the timer suspended.
// * Only [LiveStreamPhase.live] and [LiveStreamPhase.starting] count as
//   "active" for the live-viewer role.
// * For the broadcaster role the stream is active while its backend status is
//   [LiveStreamStatus.live] (timer started, stream not yet ended).
// * For prerecorded video: active while playing; paused video removes the
//   exemption (normal countdown resumes while paused, exemption restores on
//   play).
// * When the last active session ends, the notifier calls
//   [AppLockNotifier.onMediaSessionEnded] which starts a fresh countdown.
// * No timer resets on every video frame, stream event, or periodic callback.

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Media session kinds
// ---------------------------------------------------------------------------

enum MediaSessionKind {
  /// Prerecorded video playing in the full-screen player.
  videoPlayback,

  /// Live stream being viewed in LiveRoomScreen.
  liveViewer,

  /// Live stream being broadcast from LiveStudioScreen.
  liveBroadcaster,
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Immutable snapshot of all currently active foreground media sessions.
class MediaActivityState {
  /// Session IDs -> kind. Empty = no active media.
  final Map<String, MediaSessionKind> sessions;

  const MediaActivityState({this.sessions = const {}});

  const MediaActivityState.empty() : sessions = const {};

  /// True when at least one eligible foreground media session is active.
  bool get hasActiveSession => sessions.isNotEmpty;

  /// Returns the kind for a session, or null if it is not registered.
  MediaSessionKind? kindOf(String sessionId) => sessions[sessionId];

  bool get hasVideoPlayback =>
      sessions.values.contains(MediaSessionKind.videoPlayback);
  bool get hasLiveViewer =>
      sessions.values.contains(MediaSessionKind.liveViewer);
  bool get hasLiveBroadcaster =>
      sessions.values.contains(MediaSessionKind.liveBroadcaster);

  MediaActivityState add(String id, MediaSessionKind kind) {
    final next = Map<String, MediaSessionKind>.from(sessions);
    next[id] = kind;
    return MediaActivityState(sessions: next);
  }

  MediaActivityState remove(String id) {
    final next = Map<String, MediaSessionKind>.from(sessions);
    next.remove(id);
    return MediaActivityState(sessions: next);
  }

  MediaActivityState clearKind(MediaSessionKind kind) {
    final next = Map<String, MediaSessionKind>.from(sessions)
      ..removeWhere((_, v) => v == kind);
    return MediaActivityState(sessions: next);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaActivityState &&
          runtimeType == other.runtimeType &&
          _sessionsEqual(other.sessions));

  bool _sessionsEqual(Map<String, MediaSessionKind> other) {
    if (sessions.length != other.length) return false;
    for (final e in sessions.entries) {
      if (other[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(
        sessions.entries.map((e) => Object.hash(e.key, e.value)),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class MediaActivityNotifier extends StateNotifier<MediaActivityState> {
  MediaActivityNotifier() : super(const MediaActivityState.empty());

  // ── Registration API (called by media screens) ──────────────────────────

  /// Register a foreground media session.
  /// Idempotent — safe to call repeatedly with the same [sessionId]+[kind].
  void startSession(String sessionId, MediaSessionKind kind) {
    if (state.sessions[sessionId] == kind) return; // already registered
    state = state.add(sessionId, kind);
  }

  /// Unregister a foreground media session (playback ended, paused,
  /// screen exited, stream ended/failed).
  void endSession(String sessionId) {
    if (!state.sessions.containsKey(sessionId)) return;
    state = state.remove(sessionId);
  }

  /// Remove all sessions of a given kind (e.g., clear all video sessions on
  /// forced security lock so no stale exemptions survive).
  void clearSessionsOfKind(MediaSessionKind kind) {
    state = state.clearKind(kind);
  }

  /// Clear all active sessions — used on logout, account switch, or
  /// forced security lock.
  void clearAll() {
    if (state.sessions.isEmpty) return;
    state = const MediaActivityState.empty();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Global singleton; must never be auto-disposed so that media screens can
/// share a single registry regardless of their own lifecycle.
final mediaActivityProvider =
    StateNotifierProvider<MediaActivityNotifier, MediaActivityState>(
  (_) => MediaActivityNotifier(),
);
