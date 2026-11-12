// lib/features/live/presentation/providers/external_device_provider.dart
//
// Riverpod providers for the unified ExternalDeviceManager.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/live/data/cast_service.dart';
import 'package:mobile/features/live/data/external_device_manager.dart';
import 'package:mobile/features/live/data/live_streaming_repository.dart';

final externalDeviceManagerProvider =
    StateNotifierProvider<ExternalDeviceManager, ExternalDeviceManagerState>((
      ref,
    ) {
      final castService = ref.watch(castServiceProvider);
      final liveRepo = ref.watch(liveStreamingRepositoryProvider);
      return ExternalDeviceManager(
        castService: castService,
        liveRepo: liveRepo,
      );
    });
