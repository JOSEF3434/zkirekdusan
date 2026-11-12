// lib/features/live/data/lan_network_discovery_io.dart
//
// Real SSDP/UPnP/DLNA discovery and RTSP/TCP endpoint probing using dart:io.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  static const _ssdpAddress = '239.255.255.250';
  static const _ssdpPort = 1900;

  /// Sends UDP M-SEARCH for DLNA MediaRenderer and DIAL devices on the LAN,
  /// fetches their UPnP device description XML, and returns real renderers.
  Future<List<DiscoveredDlnaDevice>> discoverDlnaRenderers({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    RawDatagramSocket? socket;
    final locations = <String, String>{}; // locationUrl -> hostIp

    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.multicastLoopback = false;

      final searchTargets = [
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'urn:dial-multiscreen-org:service:dial:1',
      ];

      final completer = Completer<void>();
      final sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket?.receive();
        if (dg == null) return;
        final text = utf8.decode(dg.data, allowMalformed: true);
        final loc = _extractHeader(text, 'LOCATION');
        if (loc != null && loc.startsWith('http')) {
          locations[loc] = dg.address.address;
        }
      });

      final targetAddr = InternetAddress(_ssdpAddress);
      for (final st in searchTargets) {
        final msg =
            'M-SEARCH * HTTP/1.1\r\n'
            'HOST: 239.255.255.250:1900\r\n'
            'MAN: "ssdp:discover"\r\n'
            'MX: 2\r\n'
            'ST: $st\r\n'
            '\r\n';
        socket.send(utf8.encode(msg), targetAddr, _ssdpPort);
      }

      Timer(timeout, () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
      await sub.cancel();
    } catch (_) {
      return const [];
    } finally {
      socket?.close();
    }

    if (locations.isEmpty) return const [];

    final results = <DiscoveredDlnaDevice>[];
    final seenUdns = <String>{};
    await Future.wait(
      locations.entries.map((entry) async {
        final dev = await _fetchDeviceDescription(entry.key, entry.value);
        if (dev != null && seenUdns.add(dev.udn)) {
          results.add(dev);
        }
      }),
    );
    return results;
  }

  Future<DiscoveredDlnaDevice?> _fetchDeviceDescription(
    String locationUrl,
    String hostIp,
  ) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    try {
      final uri = Uri.parse(locationUrl);
      final req = await client.getUrl(uri);
      final resp = await req.close().timeout(const Duration(seconds: 2));
      if (resp.statusCode != 200) return null;
      final xml = await utf8.decodeStream(resp);

      final friendlyName =
          _extractXmlTag(xml, 'friendlyName') ?? 'Smart Display ($hostIp)';
      final modelName = _extractXmlTag(xml, 'modelName');
      final udn = _extractXmlTag(xml, 'UDN') ?? 'dlna-$hostIp';
      final controlPath = _extractAvTransportControlUrl(xml);
      final resolvedControlUrl = controlPath != null
          ? uri.resolve(controlPath).toString()
          : null;

      return DiscoveredDlnaDevice(
        udn: udn,
        friendlyName: friendlyName,
        modelName: modelName,
        locationUrl: locationUrl,
        avTransportControlUrl: resolvedControlUrl,
        hostIp: hostIp,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Sends DLNA UPnP AVTransport SetAVTransportURI + Play SOAP commands.
  Future<void> castDlnaMedia({
    required String controlUrl,
    required String mediaUrl,
    required String title,
  }) async {
    if (controlUrl.isEmpty) {
      throw StateError('DLNA device does not advertise an AVTransport control URL.');
    }
    final escapedUrl = _xmlEscape(mediaUrl);
    final escapedTitle = _xmlEscape(title);

    final setUriBody = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:SetAVTransportURI xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <CurrentURI>$escapedUrl</CurrentURI>
      <CurrentURIMetaData>&lt;DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" xmlns:dc="http://purl.org/dc/elements/1.1/"&gt;&lt;item id="0" parentID="-1" restricted="1"&gt;&lt;dc:title&gt;$escapedTitle&lt;/dc:title&gt;&lt;res protocolInfo="http-get:*:application/x-mpegURL:*"&gt;$escapedUrl&lt;/res&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;</CurrentURIMetaData>
    </u:SetAVTransportURI>
  </s:Body>
</s:Envelope>''';

    await _postSoap(
      controlUrl,
      '"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI"',
      setUriBody,
    );

    const playBody = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
      <Speed>1</Speed>
    </u:Play>
  </s:Body>
</s:Envelope>''';

    await _postSoap(
      controlUrl,
      '"urn:schemas-upnp-org:service:AVTransport:1#Play"',
      playBody,
    );
  }

  Future<void> stopDlnaMedia({required String controlUrl}) async {
    if (controlUrl.isEmpty) return;
    const stopBody = '''<?xml version="1.0" encoding="utf-8"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:Stop xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
      <InstanceID>0</InstanceID>
    </u:Stop>
  </s:Body>
</s:Envelope>''';

    await _postSoap(
      controlUrl,
      '"urn:schemas-upnp-org:service:AVTransport:1#Stop"',
      stopBody,
    );
  }

  Future<void> _postSoap(String url, String soapAction, String body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.set('Content-Type', 'text/xml; charset="utf-8"');
      req.headers.set('SOAPACTION', soapAction);
      req.write(body);
      final resp = await req.close().timeout(const Duration(seconds: 4));
      await resp.drain<void>();
      if (resp.statusCode >= 400) {
        throw HttpException('DLNA SOAP returned HTTP ${resp.statusCode}');
      }
    } finally {
      client.close(force: true);
    }
  }

  /// Performs a real TCP RTSP `OPTIONS` handshake against an IP camera URL.
  Future<NetworkProbeResult> probeRtspEndpoint(String rtspUrl) async {
    final uri = Uri.tryParse(rtspUrl.trim());
    if (uri == null || uri.host.isEmpty) {
      return const NetworkProbeResult(
        reachable: false,
        summary: 'Invalid RTSP URL.',
      );
    }
    final port = uri.hasPort ? uri.port : 554;
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        uri.host,
        port,
        timeout: const Duration(seconds: 3),
      );
      final sanitizedUri = uri.replace(userInfo: '').toString();
      socket.write(
        'OPTIONS $sanitizedUri RTSP/1.0\r\n'
        'CSeq: 1\r\n'
        'User-Agent: ZikreKedusanLiveStudio/1.0\r\n\r\n',
      );
      await socket.flush();

      final responseChunk = await socket
          .timeout(const Duration(seconds: 3))
          .first;
      sw.stop();
      final text = utf8.decode(responseChunk, allowMalformed: true);
      final firstLine = text.split('\r\n').firstOrNull ?? '';

      if (firstLine.contains('RTSP/1.0 200')) {
        return NetworkProbeResult(
          reachable: true,
          latencyMs: sw.elapsedMilliseconds,
          summary: 'RTSP camera responded ($firstLine) in ${sw.elapsedMilliseconds}ms.',
        );
      }
      if (firstLine.contains('401')) {
        return NetworkProbeResult(
          reachable: true,
          requiresAuth: true,
          latencyMs: sw.elapsedMilliseconds,
          summary: 'RTSP endpoint reachable (${sw.elapsedMilliseconds}ms); authentication required.',
        );
      }
      return NetworkProbeResult(
        reachable: firstLine.startsWith('RTSP/'),
        latencyMs: sw.elapsedMilliseconds,
        summary: firstLine.isNotEmpty
            ? 'Camera responded: $firstLine'
            : 'Connected on port $port but received no RTSP header.',
      );
    } on SocketException catch (e) {
      return NetworkProbeResult(
        reachable: false,
        summary: 'Cannot reach ${uri.host}:$port (${e.message}). Check Wi-Fi subnet and port.',
      );
    } on TimeoutException {
      return NetworkProbeResult(
        reachable: false,
        summary: 'Timed out waiting for RTSP response from ${uri.host}:$port.',
      );
    } finally {
      await socket?.close();
    }
  }

  /// Checks TCP reachability to an encoder/server host and port.
  Future<NetworkProbeResult> probeTcpEndpoint(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final sw = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      sw.stop();
      return NetworkProbeResult(
        reachable: true,
        latencyMs: sw.elapsedMilliseconds,
        summary: 'TCP port $port reachable on $host (${sw.elapsedMilliseconds}ms).',
      );
    } on SocketException catch (e) {
      return NetworkProbeResult(
        reachable: false,
        summary: 'Host $host:$port unreachable (${e.message}).',
      );
    } on TimeoutException {
      return NetworkProbeResult(
        reachable: false,
        summary: 'Connection to $host:$port timed out.',
      );
    } finally {
      await socket?.close();
    }
  }

  static String? _extractHeader(String headers, String name) {
    final pattern = RegExp('^$name:\\s*(.+)\$', caseSensitive: false, multiLine: true);
    return pattern.firstMatch(headers)?.group(1)?.trim();
  }

  static String? _extractXmlTag(String xml, String tag) {
    final match = RegExp('<$tag[^>]*>([^<]+)</$tag>', caseSensitive: false)
        .firstMatch(xml);
    return match?.group(1)?.trim();
  }

  static String? _extractAvTransportControlUrl(String xml) {
    final serviceBlock = RegExp(
      r'<service>[\s\S]*?AVTransport:1[\s\S]*?</service>',
      caseSensitive: false,
    ).firstMatch(xml)?.group(0);
    if (serviceBlock == null) return null;
    return _extractXmlTag(serviceBlock, 'controlURL');
  }

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
