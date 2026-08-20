import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_display_criteria.dart';
import 'package:plezy/models/download_models.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/providers/user_profile_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/download_storage_service.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/io_fakes.dart';
import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// Regression coverage for the in-place reload rollback: a reload that fails
/// AFTER `beforeArm` disposed the progress tracker but BEFORE the open
/// boundary must rebuild the tracker and bind it to the restored previous
/// item — otherwise the resumed session plays on with no progress reporting
/// and no exit flush.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpRoot;
  late PathProviderPlatform previousPathProvider;
  late AppDatabase db;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    DownloadStorageService.resetForTesting();
    await SettingsService.getInstance();
    tmpRoot = await Directory.systemTemp.createTemp('playback_reload_failure_test_');
    previousPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = FakePathProvider(tmpRoot);
    await DownloadStorageService.instance.initialize(SettingsService.instance);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
    DownloadStorageService.resetForTesting();
    SettingsService.resetForTesting();
    PathProviderPlatform.instance = previousPathProvider;
    if (await tmpRoot.exists()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  testWidgets('reload failing at the open boundary rebuilds the tracker for the prior item', (tester) async {
    final priorItem = testMediaItem(id: 'movie-prior', serverId: 'srv-1', title: 'Prior movie');
    final targetItem = testMediaItem(id: 'movie-next', serverId: 'srv-1', title: 'Next movie');

    // The reload target resolves offline from this row; the content:// path is
    // treated as directly playable (no filesystem check), so the flow reaches
    // player.open deterministically.
    await _insertCompletedDownload(db, serverId: ServerId('srv-1'), ratingKey: 'movie-next');

    final multi = testMultiServer();
    final offlineWatch = OfflineWatchSyncService(database: db, serverManager: multi.manager);
    final userProfiles = UserProfileProvider();
    addTearDown(() {
      offlineWatch.dispose();
      userProfiles.dispose();
    });

    final nativeInitialize = Completer<bool>();
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        if (call.method == 'initialize') return nativeInitialize.future;
        return Future<Object?>.value(null);
      },
      eventHandler: (_) async => null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
              ChangeNotifierProvider<MultiServerProvider>.value(value: multi.provider),
              ChangeNotifierProvider<OfflineWatchSyncService>.value(value: offlineWatch),
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProfiles),
              Provider<AppDatabase>.value(value: db),
            ],
            child: MaterialApp(
              home: VideoPlayerScreen(key: key, metadata: priorItem, isOffline: true),
            ),
          ),
        );
        expect(key.currentState, isNotNull);

        final fakePlayer = _OpenThrowingPlayer();
        addTearDown(fakePlayer.dispose);
        key.currentState!.player = fakePlayer;
        expect(key.currentState!.debugProgressTrackerForTesting, isNull);

        var navDone = false;
        final nav = key.currentState!.navigateToQueueItem(targetItem).whenComplete(() => navDone = true);
        // Drive the reload to completion: the offline profile-settings wait
        // bounds itself at 2s of test clock, and drift/database work needs
        // real-event-loop yields.
        for (var i = 0; i < 400 && !navDone; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (!navDone) {
            await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 2)));
          }
        }
        expect(navDone, isTrue, reason: 'the in-place reload must settle');
        await nav;

        expect(fakePlayer.openCalls, 1, reason: 'the reload must fail at player.open — after beforeArm ran');

        // The rollback must rebuild the tracker beforeArm disposed and bind it
        // to the restored previous item, not the failed replacement.
        final tracker = key.currentState!.debugProgressTrackerForTesting;
        expect(tracker, isNotNull, reason: 'a failed pre-open reload must re-wire progress reporting');
        expect(tracker!.metadata.globalKey, priorItem.globalKey);
        expect(tracker.metadata.globalKey, isNot(targetItem.globalKey));

        // Let the rollback's failure snackbar run its display timer down so
        // nothing is pending when the tree unmounts.
        await tester.pump(const Duration(seconds: 5));
        await tester.pump(const Duration(seconds: 1));

        await tester.pumpWidget(const SizedBox.shrink());
        nativeInitialize.complete(true);
        await tester.pump();
      },
    );
  });
}

/// Minimal player for the reload flow whose `open` always throws — the exact
/// "failure before the open boundary" the rollback path recovers from.
class _OpenThrowingPlayer extends FakeSyncPlayer {
  _OpenThrowingPlayer() : super(playing: true, duration: const Duration(minutes: 40));

  int openCalls = 0;

  @override
  String get playerType => 'mpv';

  @override
  bool get attachesExternalSubtitlesAtOpen => true;

  @override
  bool get needsDecoderRefreshAfterDisplaySwitch => false;

  @override
  Future<void> setProperty(String name, String value) async {}

  @override
  Future<void> setDisplayCriteria(MediaDisplayCriteria? criteria, {int extraDelayMs = 0}) async {}

  @override
  Future<bool> requestAudioFocus() async => true;

  @override
  Future<void> open(
    Media media, {
    bool play = true,
    bool isLive = false,
    List<SubtitleTrack>? externalSubtitles,
    Duration? timelineDuration,
  }) async {
    openCalls++;
    throw StateError('open failed before the open boundary');
  }
}

Future<void> _insertCompletedDownload(AppDatabase db, {required ServerId serverId, required String ratingKey}) async {
  await db
      .into(db.downloadedMedia)
      .insert(
        DownloadedMediaCompanion.insert(
          serverId: serverId,
          ratingKey: ratingKey,
          globalKey: '$serverId:$ratingKey',
          type: 'movie',
          status: DownloadStatus.completed.index,
          videoFilePath: Value('content://offline/$ratingKey'),
          mediaIndex: const Value(0),
        ),
      );
}
