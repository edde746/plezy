import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/audio_route_service.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_output_controller.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music_assistant/music_assistant_players.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/music/output_picker_sheet.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/stub_music_playback_service.dart';

/// The picker's whole job is that a user can tell the three paths apart.
///
/// So these assert on the *distinctions* rather than on layout: that AirPlay
/// and Music Assistant are separate offers, that each carries the sentence
/// explaining what happens when the phone goes away, and that the tick lands
/// on the one that is really in charge.
class _FakeOutputs extends MusicOutputController {
  _FakeOutputs({required this._outputs, required this._selected}) : super(serverManager: MultiServerManager());

  final List<MusicOutput> _outputs;
  MusicOutput _selected;

  @override
  List<MusicOutput> get outputs => _outputs;

  @override
  MusicOutput get selected => _selected;

  MusicOutput? lastSelected;

  @override
  Future<void> select(MusicOutput output) async {
    lastSelected = output;
    _selected = output;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}

  List<MusicOutput> rooms = const [];

  @override
  List<MusicOutput> get groupableRooms => rooms;

  List<MusicOutput>? grouped;
  Object? groupError;

  @override
  Future<void> selectGroup(List<MusicOutput> rooms) async {
    final error = groupError;
    if (error != null) throw error;
    grouped = rooms;
  }
}

/// A route the test drives directly, so no platform channel is involved.
class _FakeRoutes extends AudioRouteService {
  _FakeRoutes({required this.supportedOverride, this._route = AudioRoute.unknown}) : super(supported: false);

  final bool supportedOverride;
  AudioRoute _route;

  @override
  bool get supported => supportedOverride;

  @override
  AudioRoute get route => _route;

  @override
  bool get isAirPlay => supportedOverride && _route.isAirPlay;

  void set(AudioRoute route) {
    _route = route;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}
}

final _maTrack = MediaItem(
  id: 'library://track/1',
  backend: MediaBackend.musicAssistant,
  kind: MediaKind.track,
  serverId: 'srv',
  title: 'Oxbow',
);

class _Loaded extends StubMusicPlaybackService {
  _Loaded(this._track);

  final MediaItem _track;

  @override
  MediaItem? get currentTrack => _track;
}

void main() {
  const sonos = MusicOutput(
    id: 'srv|RINCON_1',
    name: 'Dining Room',
    serverId: 'srv',
    playerId: 'RINCON_1',
    available: true,
  );

  Future<void> pump(
    WidgetTester tester, {
    required _FakeOutputs outputs,
    required _FakeRoutes routes,
    MusicPlaybackService? playback,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MusicOutputController>.value(value: outputs),
          ChangeNotifierProvider<AudioRouteService>.value(value: routes),
          if (playback != null) ChangeNotifierProvider<MusicPlaybackService>.value(value: playback),
        ],
        child: MaterialApp(
          theme: monoTheme(MonoPalette.dark),
          home: const Scaffold(body: OutputPickerSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a chosen speaker stays ticked; the phone is not ticked on a guess', (tester) async {
    // Opened from the mini player the sheet builds on a modal route, outside
    // the session's provider scope. It used to read an unreachable controller
    // as "the phone is selected", so choosing a speaker and reopening the
    // picker showed the tick back on This device — the choice looked discarded
    // when it had not been.
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: sonos);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'iPhone Speaker', kind: AudioRouteKind.speaker),
    );
    await pump(tester, outputs: outputs, routes: routes);

    // The tick is the only thing on screen that says which output is chosen.
    bool ticked(String label) {
      final row = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
      expect(row, findsWidgets, reason: '$label should be on screen');
      return find.descendant(of: row.first, matching: find.byIcon(Symbols.check_rounded)).evaluate().isNotEmpty;
    }

    expect(ticked('Dining Room'), isTrue, reason: 'the chosen speaker must stay ticked');
    expect(ticked('This device'), isFalse, reason: 'the phone must not be ticked while a speaker is chosen');
  });

  testWidgets('a Music Assistant track cannot be moved to the phone, and the row says why', (tester) async {
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: sonos);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'iPhone Speaker', kind: AudioRouteKind.speaker),
    );
    await pump(tester, outputs: outputs, routes: routes, playback: _Loaded(_maTrack));

    expect(find.text(t.music.outputThisDeviceMusicAssistant), findsOneWidget);
    await tester.tap(find.text('This device'));
    await tester.pumpAndSettle();
    expect(outputs.lastSelected, isNull, reason: 'switching would stop the speaker and leave nothing playing');
    expect(find.text(t.music.outputAirPlay), findsNothing, reason: 'AirPlay runs on the phone and fails the same way');
  });

  testWidgets('with no controller in scope it ticks nothing rather than guessing the phone', (tester) async {
    // The modal fallback builds against the navigator, outside the session's
    // provider scope. Reading that as "the phone is selected" is what put the
    // tick back on This device after a speaker had been chosen.
    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        home: const Scaffold(body: OutputPickerSheet()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This device'), findsOneWidget, reason: 'the phone row still has to be shown');
    expect(
      find.byIcon(Symbols.check_rounded),
      findsNothing,
      reason: 'an unreachable controller means the selection is unknown, not the phone',
    );
  });

  testWidgets('the three paths are offered as three, without prose beneath them', (tester) async {
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: MusicOutput.thisDevice);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'iPhone Speaker', kind: AudioRouteKind.speaker),
    );
    await pump(tester, outputs: outputs, routes: routes);

    expect(find.text('This device'), findsOneWidget);
    expect(find.text('AirPlay'), findsOneWidget);
    expect(find.text('Dining Room'), findsOneWidget);

    // The explanatory captions under each row were removed deliberately: the
    // three names carry the choice, and the prose repeated what the section
    // headings already said. Asserted as absent so they do not drift back.
    expect(find.textContaining('Playback stops when the app does'), findsNothing);
    expect(find.textContaining('Keep the phone nearby'), findsNothing);
    expect(find.textContaining('Keeps going when your phone sleeps'), findsNothing);
    expect(find.text('This phone'), findsNothing, reason: 'the heading only repeated the row beneath it');
    // And the one thing a name can never disambiguate: the same speaker in
    // two groups.
    expect(find.textContaining('same speaker can appear in both'), findsOneWidget);
  });

  testWidgets('the tick moves to AirPlay when the route does, without a second output', (tester) async {
    // The two local rows share one selection. `thisDevice` stays a single
    // output in the controller — it is one engine — and the route decides
    // which row is ticked.
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: MusicOutput.thisDevice);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'iPhone Speaker', kind: AudioRouteKind.speaker),
    );
    await pump(tester, outputs: outputs, routes: routes);

    expect(find.text('Choose a destination'), findsOneWidget);

    routes.set(const AudioRoute(name: 'Dining Room', kind: AudioRouteKind.airPlay));
    await tester.pumpAndSettle();

    expect(find.text('Streaming to Dining Room'), findsOneWidget);
    // Still exactly one Music Assistant output — AirPlay added no player.
    expect(outputs.outputs.where((o) => o.isRemote), hasLength(1));
  });

  testWidgets('tapping AirPlay hands the engine back to the phone', (tester) async {
    // Coming from a Sonos selection, the tick is meaningless unless the local
    // engine is the one that will play. AirPlay routes *this phone's* audio.
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: sonos);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'Dining Room', kind: AudioRouteKind.airPlay),
    );
    await pump(tester, outputs: outputs, routes: routes);

    await tester.tap(find.text('AirPlay'));
    await tester.pumpAndSettle();

    expect(outputs.lastSelected, MusicOutput.thisDevice);
  });

  testWidgets('a platform with no system route offers no AirPlay', (tester) async {
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice, sonos], selected: MusicOutput.thisDevice);
    await pump(tester, outputs: outputs, routes: _FakeRoutes(supportedOverride: false));

    expect(find.text('AirPlay'), findsNothing);
    // …and with nothing to confuse the Sonos row with, the note that exists
    // only to disambiguate the two is not shown either.
    expect(find.textContaining('same speaker can appear in both'), findsNothing);
    expect(find.text('Dining Room'), findsOneWidget);
  });

  testWidgets('the phone row names a headphone route instead of claiming the speaker', (tester) async {
    // "This device" is true about the engine and misleading about where the
    // sound is; the system already has the better word for it.
    final outputs = _FakeOutputs(outputs: const [MusicOutput.thisDevice], selected: MusicOutput.thisDevice);
    final routes = _FakeRoutes(
      supportedOverride: true,
      route: const AudioRoute(name: 'Jack’s AirPods', kind: AudioRouteKind.bluetooth),
    );
    await pump(tester, outputs: outputs, routes: routes);

    expect(find.text('Jack’s AirPods'), findsOneWidget);
  });

  group('several speakers', () {
    const den = MusicOutput(id: 'srv|RINCON_2', name: 'Den', serverId: 'srv', playerId: 'RINCON_2', available: true);
    const elsewhere = MusicOutput(id: 'other|X', name: 'Cabin', serverId: 'other', playerId: 'X', available: true);

    _FakeOutputs withRooms(List<MusicOutput> rooms) =>
        _FakeOutputs(outputs: [MusicOutput.thisDevice, ...rooms], selected: MusicOutput.thisDevice)..rooms = rooms;

    Future<void> open(WidgetTester tester, _FakeOutputs outputs) async {
      await pump(tester, outputs: outputs, routes: _FakeRoutes(supportedOverride: false));
      await tester.tap(find.text(t.music.outputGroupAction));
      await tester.pumpAndSettle();
    }

    testWidgets('is not offered with fewer than two rooms to group', (tester) async {
      await pump(tester, outputs: withRooms(const [sonos]), routes: _FakeRoutes(supportedOverride: false));

      expect(find.text(t.music.outputGroupAction), findsNothing);
    });

    testWidgets('needs two rooms, then plays to the ones that were ticked', (tester) async {
      final outputs = withRooms(const [sonos, den]);
      await open(tester, outputs);

      await tester.tap(find.text('Dining Room'));
      await tester.pump();
      expect(find.text(t.music.outputGroupPickTwo), findsOneWidget);

      await tester.tap(find.text('Den'));
      await tester.pump();
      await tester.tap(find.text(t.music.outputGroupPlay(n: 2)));
      await tester.pumpAndSettle();

      expect(outputs.grouped, const [sonos, den]);
    });

    testWidgets('a room on another server cannot join', (tester) async {
      await open(tester, withRooms(const [sonos, elsewhere]));

      await tester.tap(find.text('Dining Room'));
      await tester.pump();

      final tile = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Cabin'));
      expect(tile.onChanged, isNull);
    });

    testWidgets('a refused room is named, with the ticks left in place to fix it', (tester) async {
      final outputs = withRooms(const [sonos, den])..groupError = const MaGroupRefusedException({'RINCON_2'});
      await open(tester, outputs);

      await tester.tap(find.text('Dining Room'));
      await tester.tap(find.text('Den'));
      await tester.pump();
      await tester.tap(find.text(t.music.outputGroupPlay(n: 2)));
      await tester.pumpAndSettle();

      expect(find.text(t.music.outputGroupRefused(names: 'Den')), findsOneWidget);
      expect(find.text(t.music.outputGroupPlay(n: 2)), findsOneWidget);
    });
  });
}
