import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/live_tv_support.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/server_capabilities.dart';
import 'package:plezy/models/livetv_program.dart';
import 'package:plezy/models/media_subscription.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/screens/livetv/live_tv_show_schedule_screen.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    TvDetectionService.debugSetAppleTVOverride(true);
  });

  tearDown(() => TvDetectionService.debugSetAppleTVOverride(null));

  testWidgets('record action is D-pad reachable and invokes the recording flow once', (tester) async {
    final dvr = _FakeLiveTvDvr();
    final client = _FakeMediaServerClient(
      liveTv: _FakeLiveTvSupport(
        dvr: dvr,
        programs: [_program(guid: 'plex://episode/recordable')],
      ),
      supportsDvr: true,
    );
    final provider = _providerFor(client);
    addTearDown(provider.dispose);

    await _pumpScreen(tester, provider);

    expect(find.byType(FocusableActionBar), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'FocusableWrapper');
    expect(dvr.subscriptionTemplateCalls, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'ActionBar[0]');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(dvr.subscriptionTemplateCalls, 1);
    expect(dvr.requestedGuids, ['plex://episode/recordable']);
  });

  testWidgets('non-recordable schedules do not add a dead app-bar focus target', (tester) async {
    final unsupportedClient = _FakeMediaServerClient(
      liveTv: _FakeLiveTvSupport(
        dvr: _FakeLiveTvDvr(),
        programs: [_program(guid: 'plex://episode/unsupported')],
      ),
      supportsDvr: false,
    );
    final unsupportedProvider = _providerFor(unsupportedClient);
    addTearDown(unsupportedProvider.dispose);

    await _pumpScreen(tester, unsupportedProvider);
    await _expectNoRecordFocusTarget(tester);

    final missingGuidClient = _FakeMediaServerClient(
      liveTv: _FakeLiveTvSupport(
        dvr: _FakeLiveTvDvr(),
        programs: [
          _program(),
          _program(guid: ''),
        ],
      ),
      supportsDvr: true,
    );
    final missingGuidProvider = _providerFor(missingGuidClient);
    addTearDown(missingGuidProvider.dispose);

    await _pumpScreen(tester, missingGuidProvider);
    await _expectNoRecordFocusTarget(tester);
  });
}

Future<void> _expectNoRecordFocusTarget(WidgetTester tester) async {
  expect(find.byType(FocusableActionBar), findsNothing);
  final scheduleFocus = FocusManager.instance.primaryFocus;
  expect(scheduleFocus?.debugLabel, 'FocusableWrapper');

  await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  await tester.pumpAndSettle();

  expect(FocusManager.instance.primaryFocus, same(scheduleFocus));
}

LiveTvProgram _program({String? guid}) => LiveTvProgram(
  guid: guid,
  title: 'Pilot',
  grandparentTitle: 'Example Show',
  beginsAt: 1_900_000_000,
  endsAt: 1_900_003_600,
);

MultiServerProvider _providerFor(MediaServerClient client) {
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  return MultiServerProvider(manager, DataAggregationService(manager));
}

Future<void> _pumpScreen(WidgetTester tester, MultiServerProvider provider) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });

  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(
            theme: monoTheme(dark: true),
            home: const LiveTvShowScheduleScreen(showTitle: 'Example Show', serverId: 'server-a', channels: []),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeMediaServerClient implements MediaServerClient {
  @override
  final LiveTvSupport liveTv;
  final bool supportsDvr;

  _FakeMediaServerClient({required this.liveTv, required this.supportsDvr});

  @override
  ServerId get serverId => ServerId('server-a');

  @override
  String? get serverName => 'Test server';

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  ServerCapabilities get capabilities => ServerCapabilities(liveTv: true, liveTvDvr: supportsDvr);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLiveTvSupport implements LiveTvSupport {
  @override
  final LiveTvDvrSupport? dvr;
  final List<LiveTvProgram> programs;

  _FakeLiveTvSupport({required this.dvr, required this.programs});

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) async => programs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLiveTvDvr implements LiveTvDvrSupport {
  int subscriptionTemplateCalls = 0;
  final List<String> requestedGuids = [];

  @override
  Future<List<SubscriptionTemplate>> getSubscriptionTemplate(String guid) async {
    subscriptionTemplateCalls++;
    requestedGuids.add(guid);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
