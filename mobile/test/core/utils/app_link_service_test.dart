import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/app_link_service.dart';

void main() {
  group('AppLinkService - Deployed Base URL & Configuration', () {
    test('defaults baseHttps to configured FRONTEND_BASE_URL (https://zikire-kdusan.onrender.com)', () {
      expect(AppLinkService.baseHttps, equals('https://zikire-kdusan.onrender.com'));
      expect(AppLinkService.baseHost, equals('zikire-kdusan.onrender.com'));
    });

    test('recognizes known hosts', () {
      expect(AppLinkService.isKnownHost('zikire-kdusan.onrender.com'), isTrue);
      expect(AppLinkService.isKnownHost('zikrekidusan.onrender.com'), isTrue);
      expect(AppLinkService.isKnownHost('app.zikrekidusan.com'), isTrue);
      expect(AppLinkService.isKnownHost('zikrekidusan.com'), isTrue);
      expect(AppLinkService.isKnownHost('unknown-evil-site.com'), isFalse);
    });
  });

  group('AppLinkService - User Link Generation (Production Requirements)', () {
    const sampleUserIdWithoutUsername = '0e599727-5c5c-4219-be29-7bfdcdea6147';
    const sampleUserIdWithUsername = '0847aece-76ef-4f5d-8f6d-d9a3befbc571';

    test('generates username-based link for user WITH username (e.g. john1)', () {
      final link = AppLinkService.userLink(
        username: 'john1',
        userId: sampleUserIdWithUsername,
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/john1'));

      final display = AppLinkService.userDisplay(
        username: 'john1',
        userId: sampleUserIdWithUsername,
      );
      expect(display, equals('@john1'));
    });

    test('strips leading @ from username during generation', () {
      final link = AppLinkService.userLink(
        username: '@mr_J',
        userId: '19fbdfd7-5675-45c0-bae8-2d3c0359c786',
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/mr_J'));
    });

    test('falls back to /u/{userId} when user has NO username (null) — exact sample user', () {
      final link = AppLinkService.userLink(
        username: null,
        userId: sampleUserIdWithoutUsername,
      );
      expect(
        link,
        equals('https://zikire-kdusan.onrender.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147'),
      );

      final display = AppLinkService.userDisplay(
        username: null,
        userId: sampleUserIdWithoutUsername,
      );
      expect(
        display,
        equals('zikire-kdusan.onrender.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147'),
      );
    });

    test('falls back to /u/{userId} when username is whitespace', () {
      final link = AppLinkService.userLink(
        username: '   ',
        userId: sampleUserIdWithoutUsername,
      );
      expect(
        link,
        equals('https://zikire-kdusan.onrender.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147'),
      );
    });

    test('falls back to /u/{userId} when username string is a raw UUID', () {
      final link = AppLinkService.userLink(
        username: '0e599727-5c5c-4219-be29-7bfdcdea6147',
        userId: sampleUserIdWithoutUsername,
      );
      expect(
        link,
        equals('https://zikire-kdusan.onrender.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147'),
      );
    });
  });

  group('AppLinkService - Group, Channel, Post, Video Links', () {
    const testGroupId = 'grp-123-abc';
    const testChannelId = 'chn-456-def';

    test('group link uses slug when available', () {
      final link = AppLinkService.groupLink(
        slug: 'orthodox_tewahedo',
        groupId: testGroupId,
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/orthodox_tewahedo'));
    });

    test('group link uses invite token when provided', () {
      final link = AppLinkService.groupLink(
        groupId: testGroupId,
        inviteToken: 'xyz789token',
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/join/group/xyz789token'));
    });

    test('group fallback to /g/<groupId>', () {
      final link = AppLinkService.groupLink(
        groupId: testGroupId,
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/g/grp-123-abc'));
    });

    test('channel link uses handle when available', () {
      final link = AppLinkService.channelLink(
        handle: 'saint_mary_teachings',
        channelId: testChannelId,
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/saint_mary_teachings'));
    });

    test('channel fallback to /c/<channelId>', () {
      final link = AppLinkService.channelLink(
        channelId: testChannelId,
      );
      expect(link, equals('https://zikire-kdusan.onrender.com/c/chn-456-def'));
    });

    test('post and video canonical links', () {
      expect(
        AppLinkService.postLink('post-888'),
        equals('https://zikire-kdusan.onrender.com/posts/post-888'),
      );
      expect(
        AppLinkService.videoLink('vid-999'),
        equals('https://zikire-kdusan.onrender.com/video/vid-999'),
      );
    });
  });

  group('AppLinkService - Universal Parsing (Deployed URLs, QR, Legacy)', () {
    test('parses exact sample deployed user URL with UUID (/u/{userId})', () {
      final res = AppLinkService.parse(
        'https://zikire-kdusan.onrender.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );
      expect(res.type, equals(AppLinkEntityType.user));
      expect(res.identifier, equals('0e599727-5c5c-4219-be29-7bfdcdea6147'));
    });

    test('parses deployed username URL without /u/ prefix', () {
      final res = AppLinkService.parse('https://zikire-kdusan.onrender.com/john1');
      expect(res.type, equals(AppLinkEntityType.user));
      expect(res.identifier, equals('john1'));
    });

    test('parses deployed username URL with @ prefix in path', () {
      final res = AppLinkService.parse('https://zikire-kdusan.onrender.com/@john1');
      expect(res.type, equals(AppLinkEntityType.user));
      expect(res.identifier, equals('john1'));
    });

    test('parses legacy app.zikrekidusan.com user URL for backward compatibility', () {
      final res = AppLinkService.parse(
        'https://app.zikrekidusan.com/u/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );
      expect(res.type, equals(AppLinkEntityType.user));
      expect(res.identifier, equals('0e599727-5c5c-4219-be29-7bfdcdea6147'));
    });

    test('parses custom URI scheme: zikrekidusan://profile/user/<id>', () {
      final res = AppLinkService.parse(
        'zikrekidusan://profile/user/0e599727-5c5c-4219-be29-7bfdcdea6147',
      );
      expect(res.type, equals(AppLinkEntityType.user));
      expect(res.identifier, equals('0e599727-5c5c-4219-be29-7bfdcdea6147'));
    });

    test('parses deployed group invite link', () {
      final res = AppLinkService.parse(
        'https://zikire-kdusan.onrender.com/join/group/token_abc123',
      );
      expect(res.type, equals(AppLinkEntityType.groupInvite));
      expect(res.identifier, equals('token_abc123'));
    });

    test('parses manual @handle and raw username inputs', () {
      final resAt = AppLinkService.parse('@mr_J');
      expect(resAt.type, equals(AppLinkEntityType.user));
      expect(resAt.identifier, equals('mr_J'));

      final resRaw = AppLinkService.parse('sara_bi');
      expect(resRaw.type, equals(AppLinkEntityType.user));
      expect(resRaw.identifier, equals('sara_bi'));
    });
  });
}
