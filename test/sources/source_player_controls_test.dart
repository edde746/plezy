import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/presentation_formats.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/mpv/player/audio_spectrum.dart';
import 'package:plezy/multiview/workspace_controller.dart';
import 'package:plezy/screens/sources/source_player_screen.dart';
import 'package:plezy/screens/sources/source_queue_sheet.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/sources/source_controller.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/source_playback.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/music/music_visualizer.dart';
import 'package:provider/provider.dart';

import '../services/music/music_playback_service_test.dart' show FakePlayer;
import 'fixtures/memory_sources.dart';

class _MpvPlayer extends FakePlayer implements AudioSpectrumAnalyzer {
  final StreamController<AudioSpectrumSample?> spectrumSamples = StreamController<AudioSpectrumSample?>.broadcast(
    sync: true,
  );
  final properties = <String, String>{};
  final writes = <(String, String)>[];
  bool spectrumEnabled = false;

  @override
  PlayerState get state => super.state.copyWith(seekable: true);

  @override
  String get playerType => 'mpv';

  @override
  Stream<AudioSpectrumSample?> get audioSpectrumStream => spectrumSamples.stream;

  @override
  bool get audioPassthroughActive => false;

  @override
  Future<bool> setAudioSpectrumAnalysisEnabled(bool enabled) async {
    spectrumEnabled = enabled;
    return enabled;
  }

  @override
  void closeControllers() {
    super.closeControllers();
    unawaited(spectrumSamples.close());
  }

  @override
  Future<void> setProperty(String name, String value) async {
    writes.add((name, value));
    properties[name] = value;
  }

  @override
  Future<String?> getProperty(String name) async => properties[name];
}

class _Playback extends ChangeNotifier implements SourcePlayback {
  _Playback(this.player, {this.audio = false, this.localBookmarkKey, bool queued = false})
    : entry = queued
          ? _queueEntry
          : audio
          ? _audioEntry
          : _videoEntry,
      _queueEnabled = queued {
    _queueOrder.addAll(List.generate(entry.files.length, (index) => index));
  }

  static const _videoFile = PublicationFile(
    id: 'movie',
    name: 'Movie.mkv',
    mimeType: 'video/x-matroska',
    durationMs: 180000,
  );
  static const _audioFile = PublicationFile(id: 'track', name: 'Track.mp3', mimeType: 'audio/mpeg', durationMs: 180000);
  static const _videoEntry = SourceEntry(
    sourceId: 'open:session',
    id: 'movie-session',
    title: 'Movie',
    kind: SourceItemKind.video,
    files: [_videoFile],
  );
  static const _audioEntry = SourceEntry(
    sourceId: 'open:session',
    id: 'audio-session',
    title: 'Track',
    kind: SourceItemKind.music,
    files: [_audioFile],
  );
  static const _queueFiles = [
    PublicationFile(id: 'queue-1', name: '01.mp3', mimeType: 'audio/mpeg', durationMs: 180000),
    PublicationFile(id: 'queue-2', name: '02.mp3', mimeType: 'audio/mpeg', durationMs: 180000),
    PublicationFile(
      id: 'queue-3',
      name: 'https://listener:secret@music.example/03.mp3?token=private',
      mimeType: 'audio/mpeg',
      durationMs: 180000,
    ),
  ];
  static const _queueEntry = SourceEntry(
    sourceId: 'open:session',
    id: 'audio-queue-session',
    title: 'Audio queue',
    kind: SourceItemKind.music,
    files: _queueFiles,
  );

  final bool audio;
  final String? localBookmarkKey;
  final bool _queueEnabled;
  final List<int> _queueOrder = [];
  bool _queueShuffled = false;
  MusicRepeatMode _queueRepeatMode = MusicRepeatMode.off;
  int _fileIndex = 0;

  @override
  final SourceEntry entry;
  @override
  PublicationProgress? get progress => null;
  @override
  PublicationMode get mode => audio ? PublicationMode.listening : PublicationMode.watching;
  @override
  bool get active => true;
  @override
  bool get video => !audio;
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
  String? get localMediaBookmarkKey => localBookmarkKey;
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
  int get durationMs => files.fold(0, (total, file) => total + (file.durationMs ?? 0));
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
  int get currentFileDurationMs => files[_fileIndex].durationMs!;
  @override
  int get fileIndex => _fileIndex;
  @override
  List<PublicationFile> get files => entry.files;
  @override
  bool get canUseDirectQueueControls => _queueEnabled;
  @override
  bool get queueShuffled => _queueShuffled;
  @override
  MusicRepeatMode get queueRepeatMode => _queueRepeatMode;
  @override
  int get currentQueuePosition => _queueOrder.indexOf(_fileIndex);
  @override
  List<int> get queueFileIndices => List.unmodifiable(_queueOrder);
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
  Future<void> toggleQueueShuffle() async {
    if (!_queueEnabled) return;
    final position = currentQueuePosition;
    final prefix = _queueOrder.take(position + 1).toList();
    final remaining = _queueOrder.skip(position + 1).toList().reversed.toList();
    _queueOrder
      ..clear()
      ..addAll([...prefix, ...remaining]);
    _queueShuffled = !_queueShuffled;
    notifyListeners();
  }

  @override
  Future<void> setQueueRepeatMode(MusicRepeatMode mode) async {
    _queueRepeatMode = mode;
    notifyListeners();
  }

  @override
  Future<void> selectQueueFile(int fileIndex) async {
    if (_queueEnabled && _queueOrder.contains(fileIndex)) {
      _fileIndex = fileIndex;
      notifyListeners();
    }
  }

  @override
  Future<void> stop() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _captureSourcePlayer(WidgetTester tester, String name) async {
  final output = Platform.environment['PLEZY_UI_SCREENSHOTS'];
  if (output == null) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('source-bookmark-capture')));
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    if (Platform.environment['PLEZY_UI_SCREENSHOTS'] == null) return;
    final font = FontLoader('Roboto')..addFont(rootBundle.load('assets/go-noto-current-regular.ttf'));
    await font.load();
    final material = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
    for (final face in ['Rounded', 'Outlined']) {
      final symbols = FontLoader('packages/material_symbols_icons/MaterialSymbols$face')
        ..addFont(rootBundle.load('packages/material_symbols_icons/lib/fonts/MaterialSymbols$face.ttf'));
      await symbols.load();
    }
  });

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

  testWidgets('direct audio offers named bookmarks in the existing chapter area on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    playback = _Playback(player, audio: true, localBookmarkKey: 'open-media:private-hash');
    final baseTheme = monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.macOS);
    final screenshotTheme = Platform.environment['PLEZY_UI_SCREENSHOTS'] == null
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'Roboto'),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
            ),
          );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MultiviewWorkspaceController()),
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<SourcePlayback>.value(value: playback),
        ],
        child: InputModeTracker(
          child: RepaintBoundary(
            key: const ValueKey('source-bookmark-capture'),
            child: MaterialApp(
              theme: screenshotTheme,
              debugShowCheckedModeBanner: false,
              home: const SourcePlayerScreen(),
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text(t.videoControls.chaptersAndBookmarks), findsOneWidget);
    final addBookmark = find.text(isolateDisplayText(t.videoControls.addBookmark));
    expect(addBookmark, findsOneWidget);
    for (var attempt = 0; attempt < 4; attempt++) {
      if (tester.getRect(addBookmark).bottom <= 800) break;
      await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    final rect = tester.getRect(addBookmark);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(320));
    await _captureSourcePlayer(tester, 'source-audio-bookmark-phone-dark');
    await tester.tap(addBookmark);
    await tester.pumpAndSettle();
    expect(find.text(t.videoControls.bookmarkName), findsOneWidget);
    expect(find.text(t.videoControls.bookmarkDefaultName(n: 1)), findsOneWidget);
    await _captureSourcePlayer(tester, 'source-audio-bookmark-dialog-phone-dark');
    await tester.tap(find.text(t.common.cancel));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio visualization stays inside the source player on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    playback = _Playback(player, audio: true);
    final baseTheme = monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.macOS);
    final screenshotTheme = Platform.environment['PLEZY_UI_SCREENSHOTS'] == null
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'Roboto'),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
            ),
          );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MultiviewWorkspaceController()),
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<SourcePlayback>.value(value: playback),
        ],
        child: InputModeTracker(
          child: RepaintBoundary(
            key: const ValueKey('source-player-capture'),
            child: MaterialApp(
              theme: screenshotTheme,
              debugShowCheckedModeBanner: false,
              home: const SourcePlayerScreen(),
            ),
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final toggle = find.byWidgetPredicate((widget) => widget is IconButton && widget.tooltip == t.music.visualizer);
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<IconButton>(toggle).isSelected, isTrue, reason: 'visualizer toolbar action toggles on');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(MusicVisualizer), findsOneWidget);
    expect(player.spectrumEnabled, isTrue);

    player.spectrumSamples.add(const AudioSpectrumSample(centroidHz: 5400, flatness: 0.48));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(t.music.visualizerLiveAudio), findsOneWidget);
    expect(tester.takeException(), isNull);

    final output = Platform.environment['PLEZY_UI_SCREENSHOTS'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('source-player-capture')),
        );
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await File('$output/source-visualizer-phone-dark.png').writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<IconButton>(toggle).isSelected, isFalse, reason: 'visualizer toolbar action toggles off');
    await tester.pump(const Duration(milliseconds: 300));
    expect(player.spectrumEnabled, isFalse, reason: 'hiding the visualizer releases its optional analysis filter');
    expect(find.byType(MusicVisualizer), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct queue browsing uses the shared phone sheet and labelled playback actions', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    playback = _Playback(player, audio: true, queued: true);
    final baseTheme = monoTheme(MonoPalette.dark).copyWith(platform: TargetPlatform.macOS);
    final screenshotTheme = Platform.environment['PLEZY_UI_SCREENSHOTS'] == null
        ? baseTheme
        : baseTheme.copyWith(
            textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
            primaryTextTheme: baseTheme.primaryTextTheme.apply(fontFamily: 'Roboto'),
            appBarTheme: baseTheme.appBarTheme.copyWith(
              titleTextStyle: baseTheme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
            ),
          );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MultiviewWorkspaceController()),
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<SourcePlayback>.value(value: playback),
        ],
        child: InputModeTracker(
          child: RepaintBoundary(
            key: const ValueKey('source-queue-capture'),
            child: MaterialApp(
              theme: screenshotTheme,
              debugShowCheckedModeBanner: false,
              home: const SourcePlayerScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final openQueue = find.byTooltip(t.music.queue);
    expect(openQueue, findsOneWidget);
    final toolbarRect = tester.getRect(openQueue);
    expect(toolbarRect.left, greaterThanOrEqualTo(0));
    expect(toolbarRect.right, lessThanOrEqualTo(320));
    await tester.tap(openQueue);
    await tester.pumpAndSettle();

    expect(find.textContaining('01.mp3'), findsOneWidget);
    expect(find.textContaining('02.mp3'), findsOneWidget);
    expect(find.textContaining('03.mp3'), findsOneWidget);
    expect(find.textContaining('https://'), findsNothing);
    expect(find.textContaining('secret'), findsNothing);
    expect(find.textContaining(t.music.nowPlaying), findsOneWidget);
    expect(find.byTooltip(t.common.shuffle), findsOneWidget);
    expect(find.byTooltip(t.music.repeat), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip(t.common.shuffle)).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isFalse,
    );
    expect(
      tester.getSemantics(find.byKey(const ValueKey('source-queue-0'))).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    expect(tester.takeException(), isNull);

    final output = Platform.environment['PLEZY_UI_SCREENSHOTS'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('source-queue-capture')));
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        await File('$output/source-queue-phone-dark.png').writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await tester.tap(find.byTooltip(t.common.shuffle));
    await tester.pumpAndSettle();
    expect(playback.queueShuffled, isTrue);
    expect(
      tester.getSemantics(find.byTooltip(t.common.shuffle)).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(find.byTooltip(t.music.repeat));
    await tester.pumpAndSettle();
    expect(playback.queueRepeatMode, MusicRepeatMode.all);
    expect(find.byTooltip(t.music.repeatAll), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip(t.music.repeatAll)).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isTrue,
    );
    await tester.tap(find.byTooltip(t.music.repeatAll));
    await tester.pumpAndSettle();
    expect(playback.queueRepeatMode, MusicRepeatMode.one);
    expect(find.byTooltip(t.music.repeatOne), findsOneWidget);
    await tester.tap(find.byTooltip(t.music.repeatOne));
    await tester.pumpAndSettle();
    expect(playback.queueRepeatMode, MusicRepeatMode.off);
    expect(find.byTooltip(t.music.repeat), findsOneWidget);
    expect(
      tester.getSemantics(find.byTooltip(t.music.repeat)).getSemanticsData().flagsCollection.isSelected,
      ui.Tristate.isFalse,
    );

    await tester.tap(find.byKey(const ValueKey('source-queue-1')));
    await tester.pumpAndSettle();
    expect(playback.fileIndex, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(MonoPalette.dark),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(width: 320, height: 600, child: SourceQueueSheet(playback: playback)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('03.mp3'), findsOneWidget);
    expect(find.bySemanticsLabel(t.music.trackCount(n: 3)), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'the queue sheet remains usable at 2× text scaling');
    semantics.dispose();
  });
}
