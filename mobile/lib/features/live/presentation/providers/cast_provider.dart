// lib/features/live/presentation/providers/cast_provider.dart
//
// Riverpod providers for the Cast feature:
//   • castDevicesProvider  — stream of all discovered cast devices
//   • activeCastSourceProvider — currently selected on-air cast source
//   • tvCastSessionProvider — active TV cast session (Chromecast/AirPlay/DLNA)
//   • remoteCamerasProvider — connected remote phone cameras
//   • screenShareProvider — active screen share stream

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:mobile/features/live/data/cast_service.dart';
import 'package:mobile/features/live/domain/cast_device.dart';

export 'package:mobile/features/live/data/cast_service.dart'
    show castServiceProvider, castDevicesProvider;

// ─── Active on-air cast source ────────────────────────────────────────────────

/// ID of the camera/source that is currently "on-air" in the broadcast mix.
/// null means the broadcaster's built-in camera or external encoder is live.
final activeCastSourceIdProvider = StateProvider<String?>((ref) => null);

// ─── Remote cameras ────────────────────────────────────────────────────────────

/// All connected remote phone cameras (status == connected).
final remoteCamerasProvider = Provider<List<CastDevice>>((ref) {
  final devicesAsync = ref.watch(castDevicesProvider);
  return devicesAsync.when(
    data: (devices) => devices
        .where((d) =>
            d.type == CastDeviceType.remoteCamera &&
            d.status == CastSessionStatus.connected)
        .toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// ─── Screen Share ─────────────────────────────────────────────────────────────

/// Currently active screen-share MediaStream. null when not sharing.
final screenShareStreamProvider = StateProvider<rtc.MediaStream?>((ref) => null);

// ─── Cast session notifier ───────────────────────────────────────────────────

/// Tracks active TV cast session device ID.
final activeTvCastDeviceIdProvider = StateProvider<String?>((ref) => null);

// ─── Cast panel visibility ────────────────────────────────────────────────────

/// Controls whether the cast side-panel is expanded in the Live Studio.
final castPanelVisibleProvider = StateProvider<bool>((ref) => false);

// ─── Multi-camera director mode ───────────────────────────────────────────────

/// When true, the studio shows the multi-camera director grid view.
final directorModeProvider = StateProvider<bool>((ref) => false);

