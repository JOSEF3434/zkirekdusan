// lib/features/live/presentation/widgets/web_hls_player_shim.dart
export 'web_hls_player_stub.dart'
    if (dart.library.js_interop) 'web_hls_player_web.dart';
