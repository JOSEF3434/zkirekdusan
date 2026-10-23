// test/features/downloads/web_downloads_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/presentation/widgets/video_thumbnail_widget.dart';
import 'package:mobile/core/storage/download_service.dart';
import 'package:mobile/core/storage/web_download_helper.dart';
import 'package:mobile/core/utils/localization_service.dart';
import 'package:mobile/features/library/presentation/widgets/web_download_card.dart';
import 'package:mobile/features/library/presentation/widgets/web_downloads_view.dart';

String testTr(String key, [Map<String, dynamic>? args]) {
  final map = {
    'offline.your_downloads': 'Your downloads',
    'library.downloads': 'Downloads',
    'downloads.empty': 'No downloads yet.',
    'downloads.empty_web_hint':
        'On web, use the download icon on a video to save it via your browser.',
    'downloads.status.downloading': 'Downloading...',
    'downloads.status.queued': 'Waiting to download...',
    'downloads.status.paused': 'Paused',
    'downloads.status.completed': 'Downloaded',
    'downloads.status.failed': 'Download failed',
    'downloads.status.expired': 'Session expired',
    'downloads.web_info':
        'On web, downloaded videos trigger a browser save dialog.',
    'downloads.storage': '{0} MB',
    'downloads.clear_all': 'Clear All',
    'downloads.retry': 'Retry',
    'downloads.delete': 'Delete download',
    'offline.play': 'Play Offline',
    'downloads.play_online': 'Play online',
    'explore.title': 'Explore',
  };
  var text = map[key] ?? key;
  if (args != null) {
    args.forEach((k, v) => text = text.replaceAll('{$k}', v.toString()));
  }
  return text;
}

void main() {
  group('1. VideoThumbnailWidget & Fallback Scenarios', () {
    testWidgets(
      'Displays fallback gradient with play icon when thumbnail is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VideoThumbnailWidget(thumbnailUrl: null)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Displays fallback gradient with play icon when thumbnail is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VideoThumbnailWidget(thumbnailUrl: '')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Displays fallback gradient with play icon when thumbnail has only whitespace',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VideoThumbnailWidget(thumbnailUrl: '   ')),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      },
    );

    testWidgets('Static buildFallback produces consistent Home page styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) =>
                  VideoThumbnailWidget.buildFallback(ctx, playIconSize: 40),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('Renders image widget when thumbnail is valid URL', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoThumbnailWidget(
              thumbnailUrl:
                  'https://res.cloudinary.com/demo/image/upload/sample.jpg',
            ),
          ),
        ),
      );
      // Widget mounts without error
      expect(find.byType(VideoThumbnailWidget), findsOneWidget);
    });
  });

  group('2. DownloadMetadata Serialization & Incomplete Data', () {
    test('Serializes and deserializes complete metadata accurately', () {
      final now = DateTime(2026, 10, 13, 12, 0);
      final meta = DownloadMetadata(
        videoId: 'vid-100',
        title: 'Complete Title',
        localPath: 'blob:http://localhost:5000/1234',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        sizeBytes: 15728640,
        quality: '720p',
        status: VideoDownloadStatus.completed,
        channelName: 'Test Channel',
        duration: '10:00',
        downloadedAt: now,
      );

      final json = meta.toJson();
      expect(json['videoId'], 'vid-100');
      expect(json['title'], 'Complete Title');
      expect(json['channelName'], 'Test Channel');
      expect(json['status'], 'completed');

      final reconstructed = DownloadMetadata.fromJson(json);
      expect(reconstructed.videoId, 'vid-100');
      expect(reconstructed.title, 'Complete Title');
      expect(reconstructed.channelName, 'Test Channel');
      expect(reconstructed.sizeBytes, 15728640);
      expect(reconstructed.status, VideoDownloadStatus.completed);
      expect(reconstructed.downloadedAt, now);
    });

    test('Safely handles legacy JSON with missing optional fields', () {
      final legacyJson = {
        'videoId': 'legacy-01',
        'title': 'Legacy Video',
        'localPath': '',
      };

      final meta = DownloadMetadata.fromJson(legacyJson);
      expect(meta.videoId, 'legacy-01');
      expect(meta.title, 'Legacy Video');
      expect(meta.thumbnailUrl, isNull);
      expect(meta.channelName, isNull);
      expect(meta.sizeBytes, 0);
      expect(meta.status, VideoDownloadStatus.completed);
    });

    test('copyWith updates specified fields while preserving others', () {
      final meta = DownloadMetadata(
        videoId: 'v1',
        title: 'Original Title',
        localPath: 'blob:test',
        sizeBytes: 500,
        channelName: 'Original Channel',
      );

      final updated = meta.copyWith(
        title: 'Updated Title',
        thumbnailUrl: 'https://example.com/new_thumb.jpg',
      );

      expect(updated.videoId, 'v1');
      expect(updated.title, 'Updated Title');
      expect(updated.channelName, 'Original Channel');
      expect(updated.thumbnailUrl, 'https://example.com/new_thumb.jpg');
    });
  });

  group('3. Download States Rendering on WebDownloadCard', () {
    testWidgets(
      'Queued download displays "Waiting to download..." and does NOT appear completed',
      (tester) async {
        final queuedMeta = DownloadMetadata(
          videoId: 'v-queue',
          title: 'Queued Video',
          localPath: '',
          sizeBytes: 0,
          status: VideoDownloadStatus.queued,
          channelName: 'Queue Creator',
        );

        final state = DownloadState(
          queued: {'v-queue'},
          activeTasks: {'v-queue': queuedMeta},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trProvider.overrideWithValue(testTr),
              downloadServiceProvider.overrideWith(
                (ref) => _FakeDownloadManager(state),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 320,
                  child: WebDownloadCard(videoId: 'v-queue'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Displays queued state
        expect(find.text('Waiting to download...'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);
        expect(find.text('Queued Video'), findsOneWidget);

        // Must NOT display completed state
        expect(find.text('Downloaded'), findsNothing);
      },
    );

    testWidgets(
      'Active download displays progress percentage and does NOT appear completed',
      (tester) async {
        final activeMeta = DownloadMetadata(
          videoId: 'v-active',
          title: 'Downloading Video',
          localPath: '',
          sizeBytes: 0,
          status: VideoDownloadStatus.downloading,
          channelName: 'Active Channel',
        );

        final state = DownloadState(
          downloading: {'v-active'},
          progress: {'v-active': 0.45},
          activeTasks: {'v-active': activeMeta},
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trProvider.overrideWithValue(testTr),
              downloadServiceProvider.overrideWith(
                (ref) => _FakeDownloadManager(state),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 320,
                  child: WebDownloadCard(videoId: 'v-active'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Displays progress
        expect(find.text('45%'), findsOneWidget);
        expect(find.text('Downloading... 45%'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Must NOT display completed state
        expect(find.text('Downloaded'), findsNothing);
      },
    );

    testWidgets('Completed download displays "Downloaded" and file size', (
      tester,
    ) async {
      final completedMeta = DownloadMetadata(
        videoId: 'v-comp',
        title: 'Completed Video',
        localPath: 'blob:http://localhost:5000/vid',
        sizeBytes: 26214400, // 25 MB
        status: VideoDownloadStatus.completed,
        channelName: 'Completed Channel',
      );

      final state = DownloadState(downloads: {'v-comp': completedMeta});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue(testTr),
            downloadServiceProvider.overrideWith(
              (ref) => _FakeDownloadManager(state),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 320,
                child: WebDownloadCard(
                  videoId: 'v-comp',
                  metadata: completedMeta,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed Video'), findsOneWidget);
      expect(find.text('Downloaded'), findsOneWidget);
      expect(find.text('25.0 MB'), findsAtLeastNWidgets(1));
    });

    testWidgets('Failed download displays failure notice and retry action', (
      tester,
    ) async {
      final failedMeta = DownloadMetadata(
        videoId: 'v-fail',
        title: 'Failed Video',
        localPath: '',
        sizeBytes: 0,
        status: VideoDownloadStatus.failed,
        channelName: 'Failed Channel',
      );

      final state = DownloadState(
        errors: {'v-fail': 'Network timeout'},
        activeTasks: {'v-fail': failedMeta},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue(testTr),
            downloadServiceProvider.overrideWith(
              (ref) => _FakeDownloadManager(state),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 360,
                height: 320,
                child: WebDownloadCard(videoId: 'v-fail'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed Video'), findsOneWidget);
      expect(find.textContaining('Download failed'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });

  group('4. Web Blob URL Validation & Playback Handling', () {
    test('WebDownloadHelper stub returns false for isBlobUrlValid', () async {
      final result = await WebDownloadHelper.isBlobUrlValid(
        'blob:http://localhost/test',
      );
      expect(result, isFalse);
    });

    testWidgets(
      'Completed download without valid blob allows online fallback',
      (tester) async {
        final completedMeta = DownloadMetadata(
          videoId: 'v-exp',
          title: 'Expired Blob Video',
          localPath: 'blob:http://localhost:5000/expired',
          sizeBytes: 10485760,
          status: VideoDownloadStatus.completed,
          channelName: 'Channel',
        );

        final state = DownloadState(downloads: {'v-exp': completedMeta});

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trProvider.overrideWithValue(testTr),
              downloadServiceProvider.overrideWith(
                (ref) => _FakeDownloadManager(state),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 320,
                  child: WebDownloadCard(
                    videoId: 'v-exp',
                    metadata: completedMeta,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Expired Blob Video'), findsOneWidget);
      },
    );
  });

  group('5. Responsive WebDownloadsView Layout', () {
    testWidgets('Renders empty state when no downloads exist', (tester) async {
      const state = DownloadState();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue(testTr),
            downloadServiceProvider.overrideWith(
              (ref) => _FakeDownloadManager(state),
            ),
          ],
          child: const MaterialApp(home: WebDownloadsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your downloads'), findsOneWidget);
      expect(find.text('No downloads yet.'), findsOneWidget);
      expect(find.byIcon(Icons.download_for_offline_outlined), findsOneWidget);
    });

    testWidgets('Renders grid on wide desktop constraints without overflow', (
      tester,
    ) async {
      final meta1 = DownloadMetadata(
        videoId: 'v1',
        title: 'Desktop Video 1',
        localPath: 'blob:test1',
        sizeBytes: 10485760,
        channelName: 'Channel 1',
      );
      final meta2 = DownloadMetadata(
        videoId: 'v2',
        title: 'Desktop Video 2',
        localPath: 'blob:test2',
        sizeBytes: 20971520,
        channelName: 'Channel 2',
      );

      final state = DownloadState(downloads: {'v1': meta1, 'v2': meta2});

      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue(testTr),
            downloadServiceProvider.overrideWith(
              (ref) => _FakeDownloadManager(state),
            ),
          ],
          child: const MaterialApp(home: WebDownloadsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your downloads'), findsOneWidget);
      expect(find.text('Desktop Video 1'), findsOneWidget);
      expect(find.text('Desktop Video 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders grid on mobile screen constraints without overflow', (
      tester,
    ) async {
      final meta1 = DownloadMetadata(
        videoId: 'vm1',
        title: 'Mobile Video 1',
        localPath: 'blob:test1',
        sizeBytes: 5242880,
        channelName: 'Mobile Channel',
      );

      final state = DownloadState(downloads: {'vm1': meta1});

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trProvider.overrideWithValue(testTr),
            downloadServiceProvider.overrideWith(
              (ref) => _FakeDownloadManager(state),
            ),
          ],
          child: const MaterialApp(home: WebDownloadsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your downloads'), findsOneWidget);
      expect(find.text('Mobile Video 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Renders horizontal list view card without overflow on wide screen',
      (tester) async {
        final meta = DownloadMetadata(
          videoId: 'vl1',
          title:
              'List View Video with Long Title to Test Overflow and Wrapping',
          localPath: 'blob:test1',
          sizeBytes: 15728640,
          channelName: 'List Creator Channel',
        );

        final state = DownloadState(downloads: {'vl1': meta});

        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trProvider.overrideWithValue(testTr),
              downloadServiceProvider.overrideWith(
                (ref) => _FakeDownloadManager(state),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 1000,
                  child: WebDownloadCard(
                    videoId: 'vl1',
                    metadata: meta,
                    isListView: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'List View Video with Long Title to Test Overflow and Wrapping',
          ),
          findsOneWidget,
        );
        expect(find.text('List Creator Channel'), findsOneWidget);
        expect(find.text('15.0 MB'), findsOneWidget);
        expect(find.text('Downloaded'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Renders horizontal list view card without overflow on narrow mobile screen',
      (tester) async {
        final meta = DownloadMetadata(
          videoId: 'vl2',
          title: 'Mobile List View Video',
          localPath: 'blob:test2',
          sizeBytes: 8388608,
          channelName: 'Mobile Creator',
        );

        final state = DownloadState(downloads: {'vl2': meta});

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              trProvider.overrideWithValue(testTr),
              downloadServiceProvider.overrideWith(
                (ref) => _FakeDownloadManager(state),
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 390,
                  child: WebDownloadCard(
                    videoId: 'vl2',
                    metadata: meta,
                    isListView: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mobile List View Video'), findsOneWidget);
        expect(find.text('Mobile Creator'), findsOneWidget);
        expect(find.text('8.0 MB'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

class _FakeDownloadManager extends StateNotifier<DownloadState>
    implements VideoDownloadManager {
  _FakeDownloadManager(super.state);

  @override
  Future<void> loadLocalDownloads() async {}

  @override
  Future<void> startDownload({
    required String videoId,
    required String url,
    required String title,
    String? thumbnailUrl,
    String quality = '720p',
    bool allowMobileData = false,
    String? channelName,
    DownloadStorageMode storageMode = DownloadStorageMode.inAppOnly,
  }) async {}

  @override
  Future<void> pauseDownload(String videoId) async {}

  @override
  Future<void> resumeDownload(String videoId) async {}

  @override
  Future<void> cancelDownload(String videoId) async {}

  @override
  Future<void> retryDownload(String videoId) async {}

  @override
  Future<void> deleteDownload(String videoId) async {}

  @override
  Future<void> updateMetadata(
    String videoId, {
    String? thumbnailUrl,
    String? channelName,
    String? title,
  }) async {}

  @override
  Future<void> deleteAllDownloads() async {}
}
