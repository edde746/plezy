import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/providers/trackers_provider.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/mdblist/mdblist_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_account_store.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_tracker.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/rating_bottom_sheet.dart';
import 'package:provider/provider.dart';

import '../test_helpers/io_fakes.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Sizing suite for [RatingBottomSheet]. The sheet no longer carries its own
/// `ConstrainedBox(maxHeight: height * 0.64/0.74)`: it is a
/// `Column(mainAxisSize: .min)` + `Flexible` + `ListView(shrinkWrap: true)`
/// whose only ceiling is the [OverlaySheetHost] cap (`viewportHeight * 0.75`,
/// itself capped at 720 on a desktop OS). Every test drives the real host so
/// the cap under test is the production one.
void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
    _resetTrackerBindings();
  });
  tearDown(_resetTrackerBindings);

  testWidgets('an unratable tracker keeps its row so the sheet cannot resize under the user', (tester) async {
    // The score load resolves asynchronously and finds every tracker unratable
    // for this item. Removing those rows would shorten the sheet hundreds of ms
    // after it opens, and because sheets are bottom-anchored that slides the
    // rows above them — live rating controls — out from under the user.
    await _seedAllTrackerSessions(_profileUuid);
    await _pumpRatingSheet(
      tester,
      viewport: const Size(1280, 800),
      serverClient: _StubServerClient(ServerCapabilities.plex),
      profileUuid: _profileUuid,
      item: testMediaItem(id: 'ep-1', kind: MediaKind.episode, serverId: 'server-1', serverName: 'Living Room'),
    );

    // Post-frame resolve has already run and reported every tracker unavailable.
    expect(find.text(t.rateSheet.notAvailable), findsNWidgets(5));
    expect(_listContentExtent(tester), _tallListExtent, reason: 'no row may be dropped');

    final heightAfterResolve = tester.getSize(_sheetFinder).height;
    final serverRowTop = tester.getRect(find.text(t.rateSheet.server)).top;

    // Pump well past any further async settling: nothing may move.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(tester.getSize(_sheetFinder).height, heightAfterResolve);
    expect(tester.getRect(find.text(t.rateSheet.server)).top, serverRowTop);
  });
}

/// The sheet body itself — the direct child of the host's capping
/// `ConstrainedBox`, so its height *is* the clamped sheet height.
final Finder _sheetFinder = find.byType(RatingBottomSheet);

/// Six 54px rows (48px min-height row + 6px gap) plus the list's 4/12 padding.
const double _tallListExtent = 6 * 54 + 16;

double _listContentExtent(WidgetTester tester) {
  final position = tester
      .state<ScrollableState>(find.descendant(of: _sheetFinder, matching: find.byType(Scrollable)))
      .position;
  return position.maxScrollExtent + position.viewportDimension;
}

const _profileUuid = 'profile-1';

Future<void> _pumpRatingSheet(
  WidgetTester tester, {
  required Size viewport,
  MediaServerClient? serverClient,
  String? profileUuid,
  MediaItem? item,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Pin the two platform gates the host's cap consults, so the 0.75/720 math
  // is the same on every machine running the suite.
  PlatformDetector.debugSetIsDesktopOSOverride(true);
  addTearDown(() => PlatformDetector.debugSetIsDesktopOSOverride(null));
  TvDetectionService.debugSetAppleTVOverride(false);
  addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  final trackers = TrackersProvider(httpClientFactory: () => FakeHttpClient(200, const <int>[]));
  addTearDown(trackers.dispose);
  if (profileUuid != null) {
    await trackers.onActiveProfileChanged(profileUuid);
  }

  final resolvedItem = item ?? testMediaItem(id: 'item-1', serverId: 'server-1', serverName: 'Living Room');

  await tester.pumpWidget(
    ChangeNotifierProvider<TrackersProvider>.value(
      value: trackers,
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.macOS, extensions: const [testMonoTokens]),
        home: OverlaySheetHost(
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => OverlaySheetController.of(context).show<void>(
                    builder: (_) => RatingBottomSheet(item: resolvedItem, serverClient: serverClient),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> _seedAllTrackerSessions(String uuid) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  for (final service in TrackerService.values) {
    await trackerAccountStore(service).save(
      uuid,
      TrackerSession(
        accessToken: '${service.name}-at',
        refreshToken: '${service.name}-rt',
        expiresAt: now + 3600,
        createdAt: now,
        username: 'tester',
      ),
    );
  }
  BaseSharedPreferencesService.resetForTesting();
}

/// The tracker singletons outlive a test; unbind the seeded sessions so the
/// next case starts disconnected.
void _resetTrackerBindings() {
  MalTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  AnilistTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  SimklTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  TraktTracker.instance.rebindSession(null, onSessionInvalidated: () {});
  MdblistTracker.instance.rebindSession(null, onSessionInvalidated: () {});
}

/// Narrow stand-in for the media server: while laying out, the sheet reads only
/// [capabilities] (which decides whether the server row renders at all),
/// [backend], [serverName], and [serverId].
class _StubServerClient implements MediaServerClient {
  _StubServerClient(this.capabilities);

  @override
  final ServerCapabilities capabilities;

  @override
  ServerId get serverId => ServerId('server-1');

  @override
  String? get serverName => 'Living Room';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
