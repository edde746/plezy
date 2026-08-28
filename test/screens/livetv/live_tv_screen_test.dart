import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
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
import 'package:plezy/screens/livetv/live_tv_screen.dart';
import 'package:plezy/screens/livetv/tabs/guide_tab.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  setUp(() async {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.liveTvDefaultFavorites, true);
  });

  testWidgets('loaded empty favorites shows the favorites empty state and can restore all channels', (tester) async {
    final harness = await _pumpLiveTvScreen(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });

    expect(find.byIcon(Symbols.star_rounded), findsOneWidget);
    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);

    harness.liveTv.favorites.complete(const []);
    await tester.pumpAndSettle();

    expect(find.byType(GuideTab), findsNothing);
    expect(find.text(t.liveTv.noFavoriteChannels), findsOneWidget);
    expect(find.text(t.liveTv.showAllChannels), findsOneWidget);

    await tester.tap(find.text(t.liveTv.showAllChannels));
    await tester.pumpAndSettle();

    expect(find.text(t.liveTv.noFavoriteChannels), findsNothing);
    expect(find.byIcon(Symbols.star_outline_rounded), findsOneWidget);
    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);
  });

  testWidgets('favorites matching no loaded channel show the favorites empty state', (tester) async {
    final harness = await _pumpLiveTvScreen(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });

    harness.liveTv.favorites.complete([FavoriteChannel(id: 'channel-gone', source: 'server://server-a/provider-a')]);
    await tester.pumpAndSettle();

    expect(find.byType(GuideTab), findsNothing);
    expect(find.text(t.liveTv.noFavoriteChannels), findsOneWidget);
    expect(find.text(t.liveTv.showAllChannels), findsOneWidget);
  });

  testWidgets('refresh keeps the favorites filter narrow while favorites reload', (tester) async {
    final harness = await _pumpLiveTvScreen(tester, channelKeys: const ['channel-a', 'channel-b']);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });

    final favorite = FavoriteChannel(id: 'channel-a', source: 'server://server-a/provider-a');
    harness.liveTv.favorites.complete([favorite]);
    await tester.pumpAndSettle();

    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);

    await tester.tap(find.byIcon(Symbols.refresh_rounded));
    await tester.pumpAndSettle();

    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);

    harness.liveTv.favorites.complete([favorite]);
    await tester.pumpAndSettle();

    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);
  });

  testWidgets('guide search covers all channels and selecting a non-favorite drops the favorites filter', (
    tester,
  ) async {
    final harness = await _pumpLiveTvScreen(tester, channelKeys: const ['channel-a', 'channel-b']);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });

    harness.liveTv.favorites.complete([FavoriteChannel(id: 'channel-a', source: 'server://server-a/provider-a')]);
    await tester.pumpAndSettle();
    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);

    await tester.tap(find.byIcon(Symbols.search_rounded));
    await tester.pumpAndSettle();

    // The sheet searches the full lineup, not the favorites-filtered one.
    final sheet = find.byType(GuideSearchSheet);
    expect(find.descendant(of: sheet, matching: find.text('Unique Channel A')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Unique Channel channel-b')), findsOneWidget);

    await tester.tap(find.descendant(of: sheet, matching: find.text('Unique Channel channel-b')));
    await tester.pumpAndSettle();

    // The target row must exist to land on, so the filter is dropped and the
    // guide widens to the full lineup.
    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a', 'channel-b']);
  });

  testWidgets('favorite read failure preserves raw Guide channels', (tester) async {
    final harness = await _pumpLiveTvScreen(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });

    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);

    harness.liveTv.favorites.completeError(StateError('favorite read failed'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.star_rounded), findsOneWidget);
    expect(_guideChannels(tester).map((channel) => channel.key), ['channel-a']);
  });
  testWidgets('favorite failure keeps favorites loaded from healthy stores', (tester) async {
    final failedLiveTv = _FakeLiveTvSupport(serverId: 'server-a', storeKey: 'store-a');
    final healthyLiveTv = _FakeLiveTvSupport(serverId: 'server-b', storeKey: 'store-b');
    final failedClient = _FakeMediaServerClient(failedLiveTv, serverId: ServerId('server-a'));
    final healthyClient = _FakeMediaServerClient(healthyLiveTv, serverId: ServerId('server-b'));
    final manager = MultiServerManager()
      ..debugRegisterClientForTesting(failedClient)
      ..debugRegisterClientForTesting(healthyClient);
    final provider = testMultiServerProvider(manager);
    provider.debugSetLiveTvServersForTesting([
      LiveTvServerInfo(serverId: 'server-a', dvrKey: 'dvr-a', lineup: 'provider-a'),
      LiveTvServerInfo(serverId: 'server-b', dvrKey: 'dvr-b', lineup: 'provider-b'),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      manager.dispose();
    });
    await tester.pumpWidget(
      TranslationProvider(
        child: InputModeTracker(
          child: ChangeNotifierProvider<MultiServerProvider>.value(
            value: provider,
            child: MaterialApp(theme: monoTheme(dark: true), home: const LiveTvScreen()),
          ),
        ),
      ),
    );
    failedLiveTv.favorites.completeError(StateError('favorite read failed'));
    healthyLiveTv.favorites.complete([FavoriteChannel(id: 'channel-server-b', source: 'server://server-b/provider-b')]);
    await tester.pumpAndSettle();

    final guide = tester.widget<GuideTab>(find.byType(GuideTab));
    final healthyChannel = guide.channels.singleWhere((channel) => channel.serverId == 'server-b');
    expect(guide.isFavoriteChannel!(healthyChannel), isTrue);
    expect(guide.channels.map((channel) => channel.serverId), ['server-b']);
  });

  testWidgets('favorite write failure keeps optimistic state, shows feedback, and leaves the queue usable', (
    tester,
  ) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.liveTvDefaultFavorites, false);
    final harness = await _pumpLiveTvScreen(tester);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      harness.dispose();
    });
    harness.liveTv.writeFailures.add(StateError('favorite write failed'));
    harness.liveTv.favorites.complete(const []);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Unique Channel A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    var guide = tester.widget<GuideTab>(find.byType(GuideTab));
    expect(guide.isFavoriteChannel!(guide.channels.single), isTrue);
    expect(find.text(t.liveTv.favoritesUpdateFailed), findsOneWidget);
    expect(harness.liveTv.writes.map((write) => write.map((favorite) => favorite.id).toList()), [
      ['channel-a'],
    ]);

    await tester.longPress(find.text('Unique Channel A'));
    await tester.pumpAndSettle();

    guide = tester.widget<GuideTab>(find.byType(GuideTab));
    expect(guide.isFavoriteChannel!(guide.channels.single), isFalse);
    expect(harness.liveTv.writes.map((write) => write.map((favorite) => favorite.id).toList()), [
      ['channel-a'],
      <String>[],
    ]);
  });
}

List<LiveTvChannel> _guideChannels(WidgetTester tester) => tester.widget<GuideTab>(find.byType(GuideTab)).channels;

Future<_LiveTvHarness> _pumpLiveTvScreen(WidgetTester tester, {List<String>? channelKeys}) async {
  final liveTv = _FakeLiveTvSupport(channelKeys: channelKeys);
  final client = _FakeMediaServerClient(liveTv);
  final manager = MultiServerManager()..debugRegisterClientForTesting(client);
  final provider = testMultiServerProvider(manager);
  provider.debugSetLiveTvServersForTesting([
    LiveTvServerInfo(serverId: client.serverId.value, dvrKey: 'dvr-a', lineup: 'provider-a'),
  ]);
  final harness = _LiveTvHarness(manager: manager, provider: provider, liveTv: liveTv);

  await tester.pumpWidget(
    TranslationProvider(
      child: InputModeTracker(
        child: ChangeNotifierProvider<MultiServerProvider>.value(
          value: provider,
          child: MaterialApp(theme: monoTheme(dark: true), home: const LiveTvScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

class _LiveTvHarness {
  const _LiveTvHarness({required this.manager, required this.provider, required this.liveTv});

  final MultiServerManager manager;
  final MultiServerProvider provider;
  final _FakeLiveTvSupport liveTv;

  void dispose() {
    provider.dispose();
    manager.dispose();
  }
}

class _FakeMediaServerClient implements MediaServerClient {
  _FakeMediaServerClient(this.liveTv, {ServerId? serverId}) : serverId = serverId ?? ServerId('server-a');

  @override
  final LiveTvSupport liveTv;

  @override
  final ServerId serverId;

  @override
  String? get serverName => 'Server ${serverId.value}';

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  ServerCapabilities get capabilities => const ServerCapabilities(liveTv: true);

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLiveTvSupport implements LiveTvSupport {
  _FakeLiveTvSupport({this.serverId = 'server-a', this.storeKey = 'test-store', List<String>? channelKeys})
    : channelKeys = channelKeys ?? [serverId == 'server-a' ? 'channel-a' : 'channel-$serverId'];

  final String serverId;
  final String storeKey;
  final List<String> channelKeys;
  final List<Completer<List<FavoriteChannel>>> _favoriteRequests = [];
  int _servedFavoriteRequests = 0;

  Completer<List<FavoriteChannel>> get favorites {
    if (_favoriteRequests.length > _servedFavoriteRequests) {
      return _favoriteRequests[_servedFavoriteRequests];
    }
    if (_servedFavoriteRequests > 0 && !_favoriteRequests[_servedFavoriteRequests - 1].isCompleted) {
      return _favoriteRequests[_servedFavoriteRequests - 1];
    }
    final request = Completer<List<FavoriteChannel>>();
    _favoriteRequests.add(request);
    return request;
  }

  @override
  LiveTvDvrSupport? get dvr => null;

  @override
  String get favoriteStoreKey => storeKey;

  @override
  FavoriteChannelPersistenceMode get favoritePersistenceMode => FavoriteChannelPersistenceMode.serverSlice;

  @override
  Future<String> buildFavoriteChannelSource({String? lineup}) async => 'server://$serverId/${lineup ?? 'default'}';

  @override
  Future<List<LiveTvChannel>> fetchChannels({String? lineup}) async => [
    for (final key in channelKeys)
      LiveTvChannel(
        key: key,
        title: key == 'channel-a' ? 'Unique Channel A' : 'Unique Channel $key',
        serverId: serverId,
      ),
  ];

  @override
  Future<List<LiveTvProgram>> fetchSchedule({DateTime? from, DateTime? to}) async => const [];

  @override
  Future<List<FavoriteChannel>> fetchFavoriteChannels() {
    if (_favoriteRequests.length == _servedFavoriteRequests) {
      _favoriteRequests.add(Completer<List<FavoriteChannel>>());
    }
    return _favoriteRequests[_servedFavoriteRequests++].future;
  }

  final List<Object> writeFailures = [];
  final List<List<FavoriteChannel>> writes = [];

  @override
  Future<void> setFavoriteChannels(List<FavoriteChannel> channels) async {
    writes.add(List.of(channels));
    if (writeFailures.isNotEmpty) throw writeFailures.removeAt(0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
