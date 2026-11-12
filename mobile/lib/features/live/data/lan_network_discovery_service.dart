// lib/features/live/data/lan_network_discovery_service.dart
//
// Platform-conditional LAN network discovery & protocol probe service:
//  - Non-Web: real UDP SSDP multicast discovery, UPnP XML inspection,
//             DLNA SOAP SetAVTransportURI/Play/Stop, RTSP OPTIONS probe,
//             and TCP port reachability probe.
//  - Web:     graceful unsupported/web-safe responses without dart:io.

export 'lan_network_discovery_web.dart'
    if (dart.library.io) 'lan_network_discovery_io.dart';
