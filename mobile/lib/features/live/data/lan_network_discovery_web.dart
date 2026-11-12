// lib/features/live/data/lan_network_discovery_web.dart
//
// Web-safe stub for LAN network discovery & raw socket probing.

class DiscoveredDlnaDevice {
  final String udn;
  final String friendlyName;
  final String? modelName;
  final String locationUrl;
  final String? avTransportControlUrl;
  final String? hostIp;

  const DiscoveredDlnaDevice({
    required this.udn,
    required this.friendlyName,
    this.modelName,
    required this.locationUrl,
    this.avTransportControlUrl,
    this.hostIp,
  });
}

class NetworkProbeResult {
  final bool reachable;
  final int? latencyMs;
  final String summary;
  final bool requiresAuth;

  const NetworkProbeResult({
    required this.reachable,
    this.latencyMs,
    required this.summary,
    this.requiresAuth = false,
  });
}

class LanNetworkDiscoveryService {
  Future<List<DiscoveredDlnaDevice>> discoverDlnaRenderers({
    Duration timeout = const Duration(seconds: 3),
  }) async => const [];

  Future<void> castDlnaMedia({
    required String controlUrl,
    required String mediaUrl,
    required String title,
  }) async {
    throw UnsupportedError(
      'Direct DLNA/UPnP SOAP casting requires native mobile or desktop.',
    );
  }

  Future<void> stopDlnaMedia({required String controlUrl}) async {}

  Future<NetworkProbeResult> probeRtspEndpoint(String rtspUrl) async {
    return const NetworkProbeResult(
      reachable: false,
      summary:
          'Browsers cannot open raw RTSP TCP/UDP sockets directly. '
          'Verify the camera on mobile/desktop or relay it via MediaMTX.',
    );
  }

  Future<NetworkProbeResult> probeTcpEndpoint(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    return const NetworkProbeResult(
      reachable: false,
      summary:
          'Direct TCP socket probing is unavailable in Flutter Web sandboxes.',
    );
  }
}
