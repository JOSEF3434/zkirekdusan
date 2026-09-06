// lib/core/utils/media_url_resolver.dart
import '../../app/env/env.dart';

class MediaUrlResolver {
  /// Resolves any relative, localhost, or Cloudinary URL into a fully reachable,
  /// platform-appropriate URL for mobile, web, emulator, and physical devices.
  static String? resolve(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;

    // 0. Cloudinary URLs are always complete, secure HTTPS URLs — pass through immediately
    if (isCloudinary(trimmed)) {
      return trimmed;
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      final base = Env.apiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');
      return trimmed.startsWith('/') ? '$base$trimmed' : '$base/$trimmed';
    }

    // 2. If it's an absolute URL pointing to loopback/local addresses
    final uri = Uri.tryParse(trimmed);
    if (uri != null &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '0.0.0.0' ||
            uri.host == '10.0.2.2')) {
      final baseUri = Uri.tryParse(Env.apiBaseUrl);
      if (baseUri != null && baseUri.host.isNotEmpty) {
        // When connecting from a real device over network to a remote server (e.g. Render),
        // replace localhost with the remote server host without keeping internal port 3000
        final portPart = baseUri.hasPort ? ':${baseUri.port}' : '';
        return '${baseUri.scheme}://${baseUri.host}$portPart${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
      }
    }

    return trimmed;
  }

  /// Checks if a given URL is hosted on Cloudinary.
  static bool isCloudinary(String? url) {
    if (url == null) return false;
    return url.contains('res.cloudinary.com') || url.contains('cloudinary.com');
  }

  /// Extracts the Cloudinary cloud_name and public_id from a Cloudinary URL.
  static ({String cloudName, String publicId})? parseCloudinaryUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final segments = uri.pathSegments;
      final uploadIdx = segments.indexOf('upload');
      if (uploadIdx < 0 || uploadIdx + 1 >= segments.length) return null;
      final cloudName = segments[0];
      final afterUpload = segments.sublist(uploadIdx + 1);
      int startIdx = 0;
      for (int i = 0; i < afterUpload.length; i++) {
        final seg = afterUpload[i];
        if (seg.startsWith('v') && int.tryParse(seg.substring(1)) != null) {
          startIdx = i + 1;
          break;
        }
        final isTransform = !seg.contains('.') &&
            !seg.startsWith('file_') &&
            (seg.contains(',') ||
                seg.startsWith('sp_') ||
                seg.startsWith('h_') ||
                seg.startsWith('w_') ||
                seg.startsWith('q_') ||
                seg.startsWith('f_') ||
                seg.startsWith('c_') ||
                seg.startsWith('so_') ||
                seg.startsWith('vc_'));

        if (isTransform) {
          startIdx = i + 1;
        } else {
          // Reached folder or filename — transformations have ended!
          break;
        }
      }
      final publicWithExt = afterUpload.sublist(startIdx).join('/');
      final dotIdx = publicWithExt.lastIndexOf('.');
      final publicId =
          dotIdx > 0 ? publicWithExt.substring(0, dotIdx) : publicWithExt;
      return (cloudName: cloudName, publicId: publicId);
    } catch (_) {
      return null;
    }
  }

  /// Converts a Cloudinary video URL to the direct raw uploaded MP4 file URL.
  /// This file is stored directly on Cloudinary CDN and needs zero transformation time,
  /// providing instantaneous playback on all Android ExoPlayer and iOS AVPlayer devices.
  static String toCloudinaryRaw(String url) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return url;
    return 'https://res.cloudinary.com/${parsed.cloudName}/video/upload/${parsed.publicId}.mp4';
  }

  /// Converts a Cloudinary video URL to an optimized, universal direct MP4 playback URL.
  static String toCloudinaryMp4(String url) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return url;
    return 'https://res.cloudinary.com/${parsed.cloudName}/video/upload/q_auto,f_mp4/${parsed.publicId}.mp4';
  }

  /// Converts a Cloudinary video URL to an HLS streaming URL.
  static String toCloudinaryHls(String url) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return url;
    return 'https://res.cloudinary.com/${parsed.cloudName}/video/upload/sp_hd/${parsed.publicId}.m3u8';
  }

  /// Converts a Cloudinary video URL to a specific resolution rendition MP4.
  static String toCloudinaryRendition(String url, int height) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return url;
    return 'https://res.cloudinary.com/${parsed.cloudName}/video/upload/h_$height,c_scale,q_auto,vc_auto/${parsed.publicId}.mp4';
  }

  /// Converts a Cloudinary image URL to an optimized image URL.
  static String toCloudinaryImage(
    String url, {
    int? width,
    int? height,
  }) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return url;
    final transforms = <String>['q_auto', 'f_auto'];
    if (width != null) transforms.add('w_$width');
    if (height != null) transforms.add('h_$height');
    return 'https://res.cloudinary.com/${parsed.cloudName}/image/upload/${transforms.join(',')}/${parsed.publicId}';
  }

  /// Converts a Cloudinary video URL to an auto-generated thumbnail snapshot.
  static String? toCloudinaryVideoThumbnail(String url) {
    final parsed = parseCloudinaryUrl(url);
    if (parsed == null) return null;
    return 'https://res.cloudinary.com/${parsed.cloudName}/video/upload/so_1,w_800,h_450,c_fill,q_auto,f_jpg/${parsed.publicId}.jpg';
  }

  /// Resolves the best available thumbnail URL.
  /// If no custom thumbnail was provided, automatically extracts a snapshot
  /// from the video stream or rendition URLs (e.g. via Cloudinary).
  static String? resolveThumbnail({
    String? thumbnailUrl,
    String? videoUrl,
    String? hlsUrl,
    List<String>? renditionUrls,
  }) {
    final direct = resolve(thumbnailUrl);
    if (direct != null && direct.isNotEmpty) return direct;

    if (videoUrl != null && isCloudinary(videoUrl)) {
      final thumb = toCloudinaryVideoThumbnail(videoUrl);
      if (thumb != null) return thumb;
    }
    if (hlsUrl != null && isCloudinary(hlsUrl)) {
      final thumb = toCloudinaryVideoThumbnail(hlsUrl);
      if (thumb != null) return thumb;
    }
    if (renditionUrls != null) {
      for (final r in renditionUrls) {
        if (isCloudinary(r)) {
          final thumb = toCloudinaryVideoThumbnail(r);
          if (thumb != null) return thumb;
        }
      }
    }
    return null;
  }
}
