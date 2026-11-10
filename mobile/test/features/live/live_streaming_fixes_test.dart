import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/live/data/sdp_codec_helper.dart';
import 'package:mobile/features/live/domain/live_stream_model.dart';
import 'package:mobile/features/live/presentation/widgets/web_hls_player_shim.dart';

void main() {
  group('LiveStreamDto nullable groupId deserialization', () {
    test('parses JSON when groupId is null or omitted', () {
      final base = <String, dynamic>{
        'id': 'stream-1',
        'videoChannelId': 'ch-1',
        'createdById': 'usr-1',
        'title': 'Sunday Liturgy',
        'slug': 'sunday-liturgy',
        'status': 'LIVE',
        'visibility': 'PUBLIC',
        'protocol': 'RTMP',
        'createdAt': '2026-11-10T10:00:00.000Z',
        'updatedAt': '2026-11-10T10:05:00.000Z',
      };

      final omitted = LiveStreamDto.fromJson(base);
      expect(omitted.groupId, isNull);
      expect(omitted.status, LiveStreamStatus.live);

      final explicitNull = LiveStreamDto.fromJson({...base, 'groupId': null});
      expect(explicitNull.groupId, isNull);
    });
  });

  group('preferH264InSdp', () {
    test('moves H264 and its RTX payload types to the front of m=video', () {
      final sampleSdp = [
        'v=0',
        'o=- 123 2 IN IP4 127.0.0.1',
        'm=audio 9 UDP/TLS/RTP/SAVPF 111',
        'a=rtpmap:111 opus/48000/2',
        'm=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 102 103',
        'a=rtpmap:96 VP8/90000',
        'a=rtpmap:97 rtx/90000',
        'a=fmtp:97 apt=96',
        'a=rtpmap:98 VP9/90000',
        'a=rtpmap:99 H264/90000',
        'a=fmtp:99 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=64001f',
        'a=rtpmap:102 H264/90000',
        'a=fmtp:102 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f',
        'a=rtpmap:103 rtx/90000',
        'a=fmtp:103 apt=102',
      ].join('\r\n');

      final munged = preferH264InSdp(sampleSdp);
      final lines = munged.split('\r\n');
      final mAudio = lines.firstWhere((l) => l.startsWith('m=audio '));
      final mVideo = lines.firstWhere((l) => l.startsWith('m=video '));

      // Constrained Baseline 102 + RTX 103 first, then 99, then fallback VP8/96/97/98
      expect(mAudio, 'm=audio 9 UDP/TLS/RTP/SAVPF 111');
      expect(mVideo, 'm=video 9 UDP/TLS/RTP/SAVPF 102 103 99 96 97 98');
    });

    test('returns unchanged SDP if no H264 codecs exist', () {
      const vpOnly = 'v=0\r\nm=video 9 UDP/TLS/RTP/SAVPF 96\r\na=rtpmap:96 VP8/90000';
      expect(preferH264InSdp(vpOnly), vpOnly);
    });
  });

  group('WebHlsPlayer shim widget', () {
    testWidgets('renders cleanly via conditional import on non-web VM', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WebHlsPlayer(
              url: 'https://res.cloudinary.com/demo/video/live/stream_hls.m3u8',
            ),
          ),
        ),
      );
      expect(find.byType(WebHlsPlayer), findsOneWidget);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });
}
