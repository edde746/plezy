// Regression coverage for issue #2009: the guide's recording indicator and
// the program sheet's Record/Manage state. Fixtures mirror the reporter's
// PMS 1.43.3 JSON captures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_library.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/models/media_grab_operation.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/livetv/tabs/guide_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/multi_server_fixtures.dart';

const _episodeRatingKey = 'plex%3A%2F%2Fepisode%2F6a7fba88cb8a706b4d3047bb';

/// Reporter's scheduled grab from `/media/subscriptions/scheduled`.
const Map<String, dynamic> _scheduledGrabJson = {
  'mediaSubscriptionID': 1106,
  'mediaIndex': 0,
  'id': 'e97afe16706b598f31c62cf6a402daab8562fa64',
  'key': '/media/grabbers/operations/e97afe16706b598f31c62cf6a402daab8562fa64',
  'grabberIdentifier': 'tv.plex.grabbers.hdhomerun',
  'grabberProtocol': 'livetv',
  'deviceID': 1,
  'status': 'scheduled',
  'provider': 'tv.plex.providers.epg.cloud:2',
  'Metadata': {
    'ratingKey': _episodeRatingKey,
    'guid': 'plex://episode/6a7fba88cb8a706b4d3047bb',
    'key': '/tv.plex.providers.epg.cloud:2/metadata/$_episodeRatingKey',
    'type': 'episode',
    'title': "Motorway Cops: Catching Britain's Speeders",
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  Finder recordingDot() => find.byTooltip(t.liveTv.recordingScheduled);

  Future<_Harness> pumpGuide(
    WidgetTester tester, {
    required Map<String, dynamic> Function(int beginsAt) gridJson,
    List<MediaGrabOperation> grabs = const [],
    List<MediaSubscription> mappingResult = const [],
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 720);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final client = _DvrFakeClient(serverId: 'server-a', gridJson: gridJson)
      ..dvrSupport.grabs = grabs
      ..dvrSupport.mappingResult = mappingResult;
    final manager = MultiServerManager()..debugRegisterClientForTesting(client);
    final provider = testMultiServerProvider(manager)
      ..debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-a')]);
    addTearDown(provider.dispose);

    final channel = LiveTvChannel(
      key: 'channel-station-a',
      identifier: 'station-a',
      callSign: 'A',
      serverId: 'server-a',
      liveDvrKey: 'dvr-a',
    );

    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<MultiServerProvider>.value(
            value: provider,
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: Scaffold(body: GuideTab(channels: [channel])),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _Harness(client: client);
  }

  Map<String, dynamic> subscribedEpisodeGrid(int beginsAt) => {
    'ratingKey': _episodeRatingKey,
    'guid': 'plex://episode/6a7fba88cb8a706b4d3047bb',
    'key': '/tv.plex.providers.epg.cloud:2/metadata/$_episodeRatingKey',
    'type': 'episode',
    'title': "Motorway Cops: Catching Britain's Speeders",
    'Media': [
      {'beginsAt': beginsAt, 'endsAt': beginsAt + 3600, 'channelIdentifier': 'station-a'},
    ],
  };

  testWidgets('scheduled grab with matching grid identifiers produces the dot', (tester) async {
    await pumpGuide(tester, gridJson: subscribedEpisodeGrid, grabs: [MediaGrabOperation.fromJson(_scheduledGrabJson)]);

    expect(find.text("Motorway Cops: Catching Britain's Speeders"), findsOneWidget);
    expect(recordingDot(), findsOneWidget);
  });

  testWidgets('grid airing tagged with grandparentSubscriptionID shows the dot without any grabs', (tester) async {
    // The reporter's grid tags subscribed airings itself; the dot must not
    // depend on cross-matching grab metadata (issue #2009).
    await pumpGuide(
      tester,
      gridJson: (beginsAt) => {...subscribedEpisodeGrid(beginsAt), 'grandparentSubscriptionID': '1106'},
    );

    expect(recordingDot(), findsOneWidget);
  });

  testWidgets('active grab nesting its airing under Video still produces the dot', (tester) async {
    // Non-scheduled statuses render the airing under `Video` in PMS JSON.
    final grab = MediaGrabOperation.fromJson({
      'id': 'grab-2',
      'mediaSubscriptionID': 1106,
      'status': 'recording',
      'Video': (_scheduledGrabJson['Metadata'] as Map<String, dynamic>),
    });
    await pumpGuide(tester, gridJson: subscribedEpisodeGrid, grabs: [grab]);

    expect(recordingDot(), findsOneWidget);
  });

  testWidgets('recording scheduled from the sheet keeps its dot after an empty grab refresh', (tester) async {
    // The reporter saw no indicator even for a moment: the optimistic key was
    // wiped by the follow-up grab refresh racing the server materializing the
    // grab. The local action must stay authoritative until a grid reload.
    final harness = await pumpGuide(tester, gridJson: subscribedEpisodeGrid);

    await tester.longPress(find.text("Motorway Cops: Catching Britain's Speeders"));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.liveTv.record));
    await tester.pumpAndSettle();
    expect(find.text(t.liveTv.recordOptions), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, t.liveTv.record).last);
    await tester.pumpAndSettle();

    expect(harness.client.dvrSupport.createdRequests, hasLength(1));
    expect(harness.client.dvrSupport.scheduledFetches, greaterThan(0));
    expect(recordingDot(), findsOneWidget);

    // Let the success snackbar's dismiss timer elapse.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(recordingDot(), findsOneWidget);
  });

  testWidgets('sheet shows Manage recording for a tagged airing without a mapping call', (tester) async {
    // Previously the sheet always issued the identifier-scoped mapping call,
    // which 404s on PMS, so the button always read "Record" (issue #2009).
    final harness = await pumpGuide(
      tester,
      gridJson: (beginsAt) => {...subscribedEpisodeGrid(beginsAt), 'grandparentSubscriptionID': '1106'},
    );

    await tester.longPress(find.text("Motorway Cops: Catching Britain's Speeders"));
    await tester.pumpAndSettle();

    expect(find.text(t.liveTv.manageRecording), findsOneWidget);
    expect(find.text(t.liveTv.record), findsNothing);
    expect(harness.client.dvrSupport.mappingCalls, 0);
  });

  testWidgets('sheet falls back to the mapping endpoint for an untagged airing', (tester) async {
    final harness = await pumpGuide(
      tester,
      gridJson: subscribedEpisodeGrid,
      mappingResult: const [MediaSubscription(key: '1106', title: 'All Episodes')],
    );

    await tester.longPress(find.text("Motorway Cops: Catching Britain's Speeders"));
    await tester.pumpAndSettle();

    expect(harness.client.dvrSupport.mappingCalls, 1);
    expect(find.text(t.liveTv.manageRecording), findsOneWidget);
  });

  testWidgets('cancelling from the sheet hides the dot despite stale grid attributes', (tester) async {
    // The rendered programs keep their subscriptionID attributes until the
    // next grid load; the local cancel must win over the stale positive.
    final harness = await pumpGuide(
      tester,
      gridJson: (beginsAt) => {...subscribedEpisodeGrid(beginsAt), 'grandparentSubscriptionID': '1106'},
    );
    expect(recordingDot(), findsOneWidget);

    await tester.longPress(find.text("Motorway Cops: Catching Britain's Speeders"));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.liveTv.manageRecording));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.liveTv.deleteRule).last);
    await tester.pumpAndSettle();

    expect(harness.client.dvrSupport.deletedRules, ['1106']);
    expect(recordingDot(), findsNothing);

    // Let the success snackbar's dismiss timer elapse.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(recordingDot(), findsNothing);
  });
}

final class _Harness {
  _Harness({required this.client});

  final _DvrFakeClient client;
}

final class _DvrFakeClient implements MediaServerClient {
  _DvrFakeClient({required String serverId, required Map<String, dynamic> Function(int beginsAt) gridJson})
    : serverId = ServerId(serverId),
      liveTvSupport = _FakeLiveTv(serverId: serverId, gridJson: gridJson);

  @override
  final ServerId serverId;
  final _FakeLiveTv liveTvSupport;

  _FakeDvr get dvrSupport => liveTvSupport.dvrSupport;

  @override
  LiveTvSupport get liveTv => liveTvSupport;

  @override
  String get serverName => serverId.value;

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true, liveTvDvr: true);

  @override
  Future<List<MediaLibrary>> fetchLibraries() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeLiveTv implements LiveTvSupport {
  _FakeLiveTv({required this.serverId, required this.gridJson});

  final String serverId;
  final Map<String, dynamic> Function(int beginsAt) gridJson;
  final _FakeDvr dvrSupport = _FakeDvr();

  @override
  LiveTvDvrSupport? get dvr => dvrSupport;

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) async {
    final beginsAt = from!.millisecondsSinceEpoch ~/ 1000 + 600;
    // Parse the way _parseLiveTvPrograms builds grid programs.
    return [
      LiveTvProgram.fromJson(gridJson(beginsAt)).copyWith(
        serverId: ServerId(serverId),
        serverName: serverId,
        providerIdentifier: 'tv.plex.providers.epg.cloud:2',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeDvr implements LiveTvDvrSupport {
  List<MediaGrabOperation> grabs = const [];
  List<MediaSubscription> mappingResult = const [];
  final List<MediaSubscriptionCreateRequest> createdRequests = [];
  final List<String> deletedRules = [];
  int scheduledFetches = 0;
  int mappingCalls = 0;

  @override
  Future<List<MediaGrabOperation>> fetchScheduledRecordings() async {
    scheduledFetches++;
    return grabs;
  }

  @override
  Future<List<MediaSubscription>> fetchRecordingRules({bool includeGrabs = true, bool includeStorage = true}) async =>
      const [];

  @override
  Future<List<MediaSubscription>> fetchSubscriptionMapping({
    required String providerId,
    required List<String> ratingKeys,
    bool includeStorage = true,
  }) async {
    mappingCalls++;
    return mappingResult;
  }

  @override
  Future<void> deleteRecordingRule(String subscriptionId) async => deletedRules.add(subscriptionId);

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) async => [
    SubscriptionTemplate(
      subscriptions: [
        MediaSubscription(
          key: '',
          type: 4,
          targetLibrarySectionID: 1,
          title: 'All Episodes',
          airingsType: 'New Airings Only',
          selected: true,
        ),
      ],
    ),
  ];

  @override
  Future<MediaSubscription?> createRecordingRule(MediaSubscriptionCreateRequest request) async {
    createdRequests.add(request);
    return const MediaSubscription(key: '2011');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
