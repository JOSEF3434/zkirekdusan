// lib/features/live/data/sdp_codec_helper.dart
//
// Pure-Dart SDP helper so WHIP offers prefer H.264 (with its RTX payload type)
// ahead of VP8/VP9/AV1, maximizing compatibility with RTMP/FLV relays.

/// Reorder payload types on the `m=video` line so H.264 codecs (and their
/// associated `rtx` payload types) appear first, while keeping all fallback
/// codecs intact.
String preferH264InSdp(String sdp) {
  if (sdp.isEmpty) return sdp;

  final lineBreak = sdp.contains('\r\n') ? '\r\n' : '\n';
  final lines = sdp.split(RegExp(r'\r?\n'));

  int mVideoIndex = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('m=video ')) {
      mVideoIndex = i;
      break;
    }
  }
  if (mVideoIndex == -1) return sdp;

  // Scope rtpmap/fmtp inspection strictly to the video m-section.
  int sectionEnd = lines.length;
  for (int i = mVideoIndex + 1; i < lines.length; i++) {
    if (lines[i].startsWith('m=')) {
      sectionEnd = i;
      break;
    }
  }

  final h264Payloads = <String>{};
  final fmtpByPt = <String, String>{};
  final rtxAptByPt = <String, String>{};

  final rtpmapRegex = RegExp(r'^a=rtpmap:(\d+)\s+([^/\s]+)');
  final fmtpRegex = RegExp(r'^a=fmtp:(\d+)\s+(.+)$');
  final aptRegex = RegExp(r'(?:^|;)apt=(\d+)');

  for (int i = mVideoIndex + 1; i < sectionEnd; i++) {
    final line = lines[i];
    final rtpMatch = rtpmapRegex.firstMatch(line);
    if (rtpMatch != null) {
      final pt = rtpMatch.group(1)!;
      final codec = rtpMatch.group(2)!.toUpperCase();
      if (codec == 'H264') {
        h264Payloads.add(pt);
      }
      continue;
    }
    final fmtpMatch = fmtpRegex.firstMatch(line);
    if (fmtpMatch != null) {
      final pt = fmtpMatch.group(1)!;
      final params = fmtpMatch.group(2)!;
      fmtpByPt[pt] = params;
      final aptMatch = aptRegex.firstMatch(params);
      if (aptMatch != null) {
        rtxAptByPt[pt] = aptMatch.group(1)!;
      }
    }
  }

  if (h264Payloads.isEmpty) return sdp;

  // Prioritize Constrained Baseline (profile-level-id=42e01f) with packetization-mode=1
  // when multiple H.264 profiles are offered.
  final orderedH264 = h264Payloads.toList()
    ..sort((a, b) {
      final pa = fmtpByPt[a] ?? '';
      final pb = fmtpByPt[b] ?? '';
      final scoreA = (pa.contains('42e01f') ? 2 : 0) +
          (pa.contains('packetization-mode=1') ? 1 : 0);
      final scoreB = (pb.contains('42e01f') ? 2 : 0) +
          (pb.contains('packetization-mode=1') ? 1 : 0);
      return scoreB.compareTo(scoreA);
    });

  final preferred = <String>[];
  for (final h264Pt in orderedH264) {
    preferred.add(h264Pt);
    for (final entry in rtxAptByPt.entries) {
      if (entry.value == h264Pt && !preferred.contains(entry.key)) {
        preferred.add(entry.key);
      }
    }
  }

  final mParts = lines[mVideoIndex].split(' ');
  if (mParts.length <= 3) return sdp;

  final header = mParts.sublist(0, 3);
  final currentPts = mParts.sublist(3);
  final reorderedPts = <String>[
    ...preferred.where(currentPts.contains),
    ...currentPts.where((pt) => !preferred.contains(pt)),
  ];

  lines[mVideoIndex] = [...header, ...reorderedPts].join(' ');
  return lines.join(lineBreak);
}
