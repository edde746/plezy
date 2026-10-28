import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/screens/sources/source_player_screen.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_playback.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

import '../services/music/music_playback_service_test.dart' show FakePlayer;
import 'fixtures/memory_sources.dart';

class _MpvPlayer extends FakePlayer {
  final properties = <String, String>{};
  final writes = <(String, String)>[];

  @override
  PlayerState get state => super.state.copyWith(seekable: true);

  @override
  String get playerType => 'mpv';

  @override
  Future<void> setProperty(String name, String value) async {
    writes.add((name, value));
    properties[name] = value;
  }

  @override
  Future<String?> getProperty(String name) async => properties[name];
}

class _Playback extends ChangeNotifier implements SourcePlayback {
  _Playback(this.player);

  static const _file = PublicationFile(
    id: 'movie',
    name: 'Movie.mkv',
    mimeType: 'video/x-matroska',
    durationMs: 180000,
  );

  @override
  final entry = const SourceEntry(
    sourceId: 'open:session',
    id: 'movie-session',
    title: 'Movie',
    kind: SourceItemKind.video,
    files: [_file],
  );
  @override
  PublicationProgress? get progress => null;
  @override
  PublicationMode get mode => PublicationMode.watching;
  @override
  bool get active => true;
  @override
  bool get video => true;
  @override
  bool get isTransientInput => true;
  @override
  bool get isLiveInput => false;
  @override
  bool get isCapturePreview => false;
  @override
  bool get isRecordingStream => false;
  @override
  bool get canExportLocalPlaylist => false;
  @override
  String? get localVideoBookmarkKey => null;
  @override
  final Player player;
  @override
  bool get opening => false;
  @override
  bool get playing => true;
  @override
  bool fullPlayerVisible = false;
  @override
  int positionMs = 23000;
  @override
  int get durationMs => _file.durationMs!;
  @override
  int get timelineStartMs => 0;
  @override
  int get timelineEndMs => durationMs;
  @override
  int? get bookRemainingMs => durationMs - positionMs;
  @override
  int? get chapterRemainingMs => null;
  @override
  bool get chapterTimeline => false;
  @override
  int get currentFilePositionMs => positionMs;
  @override
  int get currentFileDurationMs => durationMs;
  @override
  int get fileIndex => 0;
  @override
  List<PublicationFile> get files => const [_file];
  @override
  bool get hasCompleteTimeline => true;
  @override
  bool get canUndoSeek => false;
  @override
  DateTime? get sleepDeadline => null;
  @override
  double get speed => 1;
  @override
  int get backwardSeconds => 15;
  @override
  int get forwardSeconds => 30;
  @override
  bool get sleepEnabled => false;
  @override
  BookChapter? get currentChapter => null;
  @override
  List<BookChapter> get chapters => const [];
  @override
  SourceFailure? get failure => null;

  @override
  Future<void> seek(int position) async {
    positionMs = position;
    notifyListeners();
  }

  @override
  Future<void> previousChapter() async {}
  @override
  Future<void> nextChapter() async {}
  @override
  Future<void> stop() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SourceDatabase db;
  late MemorySources sources;
  late _Playback playback;
  late _MpvPlayer player;

  setUp(() {
    db = SourceDatabase(NativeDatabase.memory());
    sources = MemorySources(SourceRepository(db), Directory('/tmp/plezy-source-player-controls'));
    player = _MpvPlayer();
    playback = _Playback(player);
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    playback.dispose();
    player.closeControllers();
    sources.dispose();
    await db.close();
  });

  testWidgets('A/B loop controls set ordered MPV points and clear the temporary loop', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MultiviewWorkspaceController()),
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<SourcePlayback>.value(value: playback),
        ],
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.macOS),
            home: const SourcePlayerScreen(),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final loopButton = find.byTooltip(t.videoControls.segmentLoop);
    expect(loopButton, findsOneWidget);
    await tester.ensureVisible(loopButton);
    await tester.tap(loopButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(t.videoControls.setLoopStart));
    await tester.pump(const Duration(milliseconds: 250));
    expect(player.writes, [('ab-loop-b', 'no'), ('ab-loop-a', '23.000')]);

    playback.positionMs = 42000;
    player.setPosition(const Duration(seconds: 42));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(loopButton);
    await tester.tap(loopButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(t.videoControls.setLoopEnd));
    await tester.pump(const Duration(milliseconds: 250));
    expect(player.writes.last, ('ab-loop-b', '42.000'));

    await tester.ensureVisible(loopButton);
    await tester.tap(loopButton);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(t.videoControls.clearSegmentLoop));
    await tester.pump(const Duration(milliseconds: 250));
    expect(player.writes.sublist(player.writes.length - 2), [('ab-loop-a', 'no'), ('ab-loop-b', 'no')]);
    expect(tester.takeException(), isNull);
  });
}
