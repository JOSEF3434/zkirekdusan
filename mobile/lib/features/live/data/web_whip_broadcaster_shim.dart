// lib/features/live/data/web_whip_broadcaster_shim.dart
//
// Conditional import: routes to the real web implementation on Flutter Web,
// and to the no-op stub on native platforms (Android, iOS, Windows, …).

export 'web_whip_broadcaster_stub.dart'
    if (dart.library.js_interop) 'web_whip_broadcaster.dart';
