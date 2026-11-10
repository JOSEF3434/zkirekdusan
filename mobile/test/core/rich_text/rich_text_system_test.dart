// mobile/test/core/rich_text/rich_text_system_test.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/rich_text/mention_entity.dart';
import 'package:mobile/core/rich_text/mention_text_controller.dart';
import 'package:mobile/core/rich_text/providers/content_search_provider.dart';
import 'package:mobile/core/rich_text/repository/mention_repository.dart';
import 'package:mobile/core/rich_text/rich_text_renderer.dart';
import 'package:mobile/features/explore/data/search_repository.dart';
import 'package:mobile/features/explore/domain/search_model.dart';
import 'package:mobile/features/home/domain/video_model.dart';

class _FakeDio implements Dio {
  dynamic nextResponseData;
  DioException? nextError;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    if (nextError != null) throw nextError!;
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: nextResponseData as T,
      statusCode: 200,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSearchRepository extends SearchRepository {
  SearchResponseDto? stubbedResponse;
  Object? stubbedError;
  int callCount = 0;

  _FakeSearchRepository() : super(_FakeDio());

  @override
  Future<SearchResponseDto> search({
    required String query,
    SearchEntityType? type,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    if (stubbedError != null) throw stubbedError!;
    return stubbedResponse ??
        const SearchResponseDto(
          results: SearchResultsDto(),
          page: 1,
          limit: 20,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const uuidUser = '4a7a8988-0deb-4c4d-9685-97577886df56';
  const uuidUser2 = '0e599727-5c5c-4219-be29-7bfdcdea6147';
  const uuidVideo = '78f7e836-21eb-4ed9-be89-854b46a37ffe';
  const uuidBook = '94be4fbf-b204-4370-af6c-203d866e63e3';
  const uuidGroup = '2dbac866-db60-43af-a305-da549cc70229';
  const uuidChannel = 'dc2787cb-c11c-47b1-9868-7398f8eb1b37';

  group('MentionTextController trigger & token handling', () {
    test('detects @ and # triggers cleanly and ignores emails/URLs', () {
      final triggers = <(MentionTrigger, String)>[];
      final ctrl = MentionTextController(
        onTriggerChanged: (t, q) => triggers.add((t, q)),
      );
      addTearDown(ctrl.dispose);

      // Typing @jo
      ctrl.value = const TextEditingValue(
        text: 'Hello @jo',
        selection: TextSelection.collapsed(offset: 9),
      );
      expect(ctrl.activeTrigger, MentionTrigger.atMention);
      expect(ctrl.triggerQuery, 'jo');

      // Typing an email should NOT trigger
      ctrl.value = const TextEditingValue(
        text: 'email me user@gmail.com',
        selection: TextSelection.collapsed(offset: 23),
      );
      expect(ctrl.activeTrigger, MentionTrigger.none);

      // Typing a URL hash anchor should NOT trigger
      ctrl.value = const TextEditingValue(
        text: 'see https://example.com/page#section',
        selection: TextSelection.collapsed(offset: 36),
      );
      expect(ctrl.activeTrigger, MentionTrigger.none);

      // Typing #test at word boundary SHOULD trigger
      ctrl.value = const TextEditingValue(
        text: 'watch #test',
        selection: TextSelection.collapsed(offset: 11),
      );
      expect(ctrl.activeTrigger, MentionTrigger.hashContent);
      expect(ctrl.triggerQuery, 'test');

      // Existing token should NOT re-trigger
      ctrl.value = const TextEditingValue(
        text: '@[user:$uuidUser:jj]',
        selection: TextSelection.collapsed(offset: 45),
      );
      expect(ctrl.activeTrigger, MentionTrigger.none);
    });

    test('insertMention and insertContentRef insert canonical tokens & extract only @mentions', () {
      final ctrl = MentionTextController();
      addTearDown(ctrl.dispose);

      ctrl.value = const TextEditingValue(
        text: 'Hi @jj',
        selection: TextSelection.collapsed(offset: 6),
      );
      ctrl.insertMention(
        const MentionSuggestion(
          id: uuidUser,
          type: MentionEntityType.user,
          username: 'jj',
          displayName: 'jj',
        ),
      );
      expect(ctrl.text, 'Hi @[user:$uuidUser:jj] ');

      // Append # reference to ANOTHER user (picked via # global search)
      ctrl.value = TextEditingValue(
        text: '${ctrl.text}#mr',
        selection: TextSelection.collapsed(offset: ctrl.text.length + 3),
      );
      ctrl.insertContentRef(
        const ContentSearchItem(
          id: uuidUser2,
          entityType: 'user',
          title: 'mr j',
        ),
      );
      expect(
        ctrl.text,
        'Hi @[user:$uuidUser:jj] #[user:$uuidUser2:mr j] ',
      );

      // Only @ mention ID should be extracted for notification!
      final mentionedIds = ctrl.extractMentionedUserIds();
      expect(mentionedIds, equals([uuidUser]));
      expect(mentionedIds, isNot(contains(uuidUser2)));
      expect(ctrl.plainText, 'Hi @jj #mr j ');
    });
  });

  group('RichTextRenderer parser & sanitizer', () {
    test('parses @mentions and all # global search entity types including Amharic/Unicode', () {
      final input =
          'ሰላም @[user:$uuidUser:jj] @[group:$uuidGroup:tests] @[channel:$uuidChannel:test] '
          'ይመልከቱ #[video:$uuidVideo:test] #[book:$uuidBook:ሙከራ [1]] '
          '#[user:$uuidUser2:mr j]';

      final entities = parseEntities(input);
      expect(entities.length, 6);
      expect(entities[0].type, MentionEntityType.user);
      expect(entities[0].triggerChar, '@');
      expect(entities[1].type, MentionEntityType.group);
      expect(entities[2].type, MentionEntityType.channel);
      expect(entities[3].type, MentionEntityType.video);
      expect(entities[4].type, MentionEntityType.book);
      expect(entities[5].type, MentionEntityType.user);
      expect(entities[5].triggerChar, '#');

      expect(
        stripTokens('@[user:$uuidUser:jj] watched #[video:$uuidVideo:test]'),
        '@jj watched #test',
      );
    });
  });

  group('MentionRepository ResponseInterceptor unwrapping', () {
    test('unwraps { success: true, data: [...] } envelope cleanly', () async {
      final fakeDio = _FakeDio();
      fakeDio.nextResponseData = {
        'success': true,
        'data': [
          {
            'id': uuidUser,
            'type': 'user',
            'username': 'jj',
            'displayName': 'jj',
            'isVerified': false,
          },
          {
            'id': uuidChannel,
            'type': 'channel',
            'username': 'test',
            'displayName': 'test Channel',
          },
        ],
        'timestamp': '2026-11-10T00:00:00Z',
      };

      final repo = MentionRepository(fakeDio);
      final suggestions = await repo.suggestMentions('j');
      expect(suggestions.length, 2);
      expect(suggestions[0].id, uuidUser);
      expect(suggestions[0].username, 'jj');
      expect(suggestions[1].type, MentionEntityType.channel);
    });

    test('propagates errors as AppException instead of swallowing silently', () async {
      final fakeDio = _FakeDio();
      fakeDio.nextError = DioException(
        requestOptions: RequestOptions(path: '/mentions/suggest'),
        type: DioExceptionType.connectionError,
      );
      final repo = MentionRepository(fakeDio);
      expect(
        () => repo.suggestMentions('f'),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('SearchModel & VideoRenditionDto parsing', () {
    test('parses Prisma string enum resolution ("R_720P") without throwing', () {
      final r = VideoRenditionDto.fromJson({
        'id': 'r1',
        'resolution': 'R_720P',
        'bitrate': 2500,
        'url': 'https://example.com/720.m3u8',
        'isReady': true,
      });
      expect(r.resolution, 720);
      expect(r.status, 'READY');
    });

    test('SearchResultsDto parses videos, books, channels, groups, users, posts, streams', () {
      final dto = SearchResultsDto.fromJson({
        'videos': [
          {
            'id': uuidVideo,
            'title': 'test',
            'status': 'READY',
            'visibility': 'PUBLIC',
            'viewsCount': 35,
            'channelName': 'app Channel',
            'renditions': [
              {'id': 'ren1', 'resolution': 'R_720P', 'bitrate': 1200, 'url': 'https://x.m3u8'},
            ],
            'author': {'id': uuidUser, 'username': 'jj'},
          },
        ],
        'books': [
          {
            'id': uuidBook,
            'title': 'test',
            'titleAm': 'ሙከራ',
            'author': 'mr. z',
            'isDictionary': false,
          },
        ],
        'channels': [
          {'id': uuidChannel, 'name': 'test Channel', 'handle': '@test'},
        ],
        'groups': [
          {'id': uuidGroup, 'name': 'tests', 'slug': 'tests', 'membersCount': 3},
        ],
        'users': [
          {'id': uuidUser, 'username': 'jj', 'displayName': 'jj'},
        ],
      });

      expect(dto.videos.length, 1);
      expect(dto.videos.first.title, 'test');
      expect(dto.books.length, 1);
      expect(dto.books.first.titleAm, 'ሙከራ');
      expect(dto.channels.first.cleanHandle, 'test');
      expect(dto.groups.length, 1);
      expect(dto.users.length, 1);
    });
  });

  group('ContentSearchNotifier reuses Global SearchRepository', () {
    test('fetches and maps videos + books + channels from SearchRepository', () async {
      final fakeSearchRepo = _FakeSearchRepository();
      fakeSearchRepo.stubbedResponse = SearchResponseDto(
        page: 1,
        limit: 12,
        results: SearchResultsDto.fromJson({
          'videos': [
            {
              'id': uuidVideo,
              'title': 'test',
              'status': 'READY',
              'visibility': 'PUBLIC',
              'viewsCount': 35,
              'author': {'id': uuidUser, 'username': 'jj'},
            },
          ],
          'books': [
            {'id': uuidBook, 'title': 'test', 'author': 'mr. z'},
          ],
        }),
      );

      final container = ProviderContainer(
        overrides: [
          searchRepositoryProvider.overrideWithValue(fakeSearchRepo),
        ],
      );
      addTearDown(container.dispose);

      // Keep autoDispose provider alive just like ref.watch in _ContentSearchSheet
      final sub = container.listen(contentSearchProvider, (_, _) {});
      addTearDown(sub.close);

      container.read(contentSearchProvider.notifier).search('test');
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final state = container.read(contentSearchProvider);
      expect(fakeSearchRepo.callCount, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.items.length, 2);
      expect(state.items[0].entityType, 'video');
      expect(state.items[0].title, 'test');
      expect(state.items[1].entityType, 'book');
    });
  });
}
