import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/livetv/guide_search_sheet.dart';
import 'package:plezy/services/companion_remote/companion_remote_receiver.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/multi_server_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));
  tearDown(() => CompanionRemoteReceiver.instance.onSearchAction = null);

  testWidgets('empty query lists every channel and typing filters by title, call sign, and number', (tester) async {
    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('KALP'), findsOneWidget);
    expect(find.text('KBET'), findsOneWidget);
    expect(find.text(t.liveTv.programsSection), findsNothing);

    // Title match.
    await tester.enterText(find.byType(TextField), 'news');
    await tester.pumpAndSettle();
    expect(find.text('KALP'), findsOneWidget);
    expect(find.text('KBET'), findsNothing);

    // Call-sign match.
    await tester.enterText(find.byType(TextField), 'kbet');
    await tester.pumpAndSettle();
    expect(find.text('KALP'), findsNothing);
    expect(find.text('KBET'), findsOneWidget);

    // Number match.
    await tester.enterText(find.byType(TextField), '100');
    await tester.pumpAndSettle();
    expect(find.text('KALP'), findsOneWidget);
    expect(find.text('KBET'), findsNothing);
  });

  testWidgets('selecting a channel returns it and closes the sheet', (tester) async {
    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(const []);
    await tester.pumpAndSettle();

    await tester.tap(find.text('KALP'));
    await tester.pumpAndSettle();

    expect(harness.selectedChannels.map((c) => c.key), ['channel-alpha']);
    expect(harness.selectedPrograms, isEmpty);
    expect(find.byType(GuideSearchSheet), findsNothing);
  });

  testWidgets('a program query needs two characters, matches series names, and drops ended airings', (tester) async {
    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(harness.programs);
    await tester.pumpAndSettle();

    // One character never queries programs; with no channel match either,
    // the sheet reports no results.
    await tester.enterText(find.byType(TextField), 'c');
    await tester.pumpAndSettle();
    expect(find.text(t.liveTv.programsSection), findsNothing);
    expect(find.text(t.liveTv.searchNoResults(query: 'c')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'champ');
    await tester.pumpAndSettle();
    expect(find.text(t.liveTv.programsSection), findsOneWidget);
    expect(find.text('Championship Game'), findsOneWidget);

    // Series name (grandparentTitle) matches too.
    await tester.enterText(find.byType(TextField), 'cooking');
    await tester.pumpAndSettle();
    expect(find.text(t.liveTv.programsSection), findsOneWidget);

    // The lookback window returns already-finished programs; they are dropped.
    await tester.enterText(find.byType(TextField), 'ended');
    await tester.pumpAndSettle();
    expect(find.text(t.liveTv.searchNoResults(query: 'ended')), findsOneWidget);
  });

  testWidgets('selecting a program result returns the airing resolved to its channel', (tester) async {
    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(harness.programs);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'champ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Championship Game'));
    await tester.pumpAndSettle();

    expect(harness.selectedChannels, isEmpty);
    expect(harness.selectedPrograms, hasLength(1));
    expect(harness.selectedPrograms.single.channel.key, 'channel-beta');
    expect(harness.selectedPrograms.single.program.ratingKey, 'program-game');
    expect(find.byType(GuideSearchSheet), findsNothing);
  });

  testWidgets('companion remote queries land in the open sheet and the previous handler is restored', (tester) async {
    final receivedByGlobalHandler = <String?>[];
    void globalHandler(String? query) => receivedByGlobalHandler.add(query);
    CompanionRemoteReceiver.instance.onSearchAction = globalHandler;

    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(const []);
    await tester.pumpAndSettle();

    // The sheet took the search action over.
    final takeover = CompanionRemoteReceiver.instance.onSearchAction;
    expect(takeover, isNotNull);
    expect(takeover, isNot(equals(globalHandler)));

    takeover!('beta');
    await tester.pumpAndSettle();
    expect(receivedByGlobalHandler, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'beta');
    expect(find.text('KALP'), findsNothing);
    expect(find.text('KBET'), findsOneWidget);

    // Closing the sheet restores the global handler.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(GuideSearchSheet), findsNothing);
    expect(CompanionRemoteReceiver.instance.onSearchAction, equals(globalHandler));
  });

  testWidgets('arrow-down from the field lands D-pad focus on the first result', (tester) async {
    final harness = _SheetHarness();
    addTearDown(harness.dispose);
    await harness.open(tester);
    harness.schedule.complete(const []);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, 'GuideSearch_firstResult');
  });
}

final class _SheetHarness {
  _SheetHarness() {
    final client = _FakeMediaServerClient(schedule);
    _manager = MultiServerManager()..debugRegisterClientForTesting(client);
    _provider = testMultiServerProvider(_manager)
      ..debugSetLiveTvServersForTesting([LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-a')]);
  }

  final schedule = _ControllableSchedule();
  late final MultiServerManager _manager;
  late final MultiServerProvider _provider;

  final selectedChannels = <LiveTvChannel>[];
  final selectedPrograms = <({LiveTvChannel channel, LiveTvProgram program})>[];

  final channels = [
    LiveTvChannel(
      key: 'channel-alpha',
      identifier: 'station-alpha',
      title: 'Alpha News',
      callSign: 'KALP',
      number: '100',
      serverId: 'server-a',
      liveDvrKey: 'dvr-a',
    ),
    LiveTvChannel(
      key: 'channel-beta',
      identifier: 'station-beta',
      title: 'Beta Sports',
      callSign: 'KBET',
      number: '200',
      serverId: 'server-a',
      liveDvrKey: 'dvr-a',
    ),
  ];

  /// One upcoming airing per interesting case: a title match on Beta, a series
  /// (grandparentTitle) match on Alpha, and an already-ended airing that must
  /// be dropped despite the fetch lookback returning it.
  List<LiveTvProgram> get programs {
    final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return [
      LiveTvProgram(
        ratingKey: 'program-game',
        title: 'Championship Game',
        beginsAt: nowEpoch + 2 * 3600,
        endsAt: nowEpoch + 3 * 3600,
        channelIdentifier: 'station-beta',
        serverId: 'server-a',
      ),
      LiveTvProgram(
        ratingKey: 'program-series',
        title: 'Episode 12',
        grandparentTitle: 'Cooking Series',
        beginsAt: nowEpoch + 4 * 3600,
        endsAt: nowEpoch + 5 * 3600,
        channelIdentifier: 'station-alpha',
        serverId: 'server-a',
      ),
      LiveTvProgram(
        ratingKey: 'program-ended',
        title: 'Ended Show',
        beginsAt: nowEpoch - 3600,
        endsAt: nowEpoch - 1800,
        channelIdentifier: 'station-alpha',
        serverId: 'server-a',
      ),
    ];
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<MultiServerProvider>.value(
            value: _provider,
            child: MaterialApp(
              theme: monoTheme(dark: true),
              home: OverlaySheetHost(
                child: Scaffold(
                  body: Center(
                    child: Builder(
                      builder: (context) => ElevatedButton(
                        onPressed: () {
                          OverlaySheetController.showAdaptive<void>(
                            context,
                            isScrollControlled: true,
                            builder: (_) => GuideSearchSheet(
                              channels: channels,
                              onChannelSelected: selectedChannels.add,
                              onProgramSelected: (channel, program) =>
                                  selectedPrograms.add((channel: channel, program: program)),
                            ),
                          );
                        },
                        child: const Text('Open'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    expect(schedule.requests, hasLength(1));
  }

  void dispose() {
    _provider.dispose();
    _manager.dispose();
  }
}

final class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient(this.schedule);

  final _ControllableSchedule schedule;

  @override
  ServerId get serverId => ServerId('server-a');

  @override
  LiveTvSupport get liveTv => schedule;

  @override
  String get serverName => 'server-a';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true);

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ControllableSchedule implements LiveTvSupport {
  final List<Completer<List<LiveTvProgram>>> requests = [];

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) {
    final completer = Completer<List<LiveTvProgram>>();
    requests.add(completer);
    return completer.future;
  }

  void complete(List<LiveTvProgram> programs) => requests.last.complete(programs);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
