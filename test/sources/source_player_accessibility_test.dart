import 'dart:io';
import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_slider.dart';
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

import 'fixtures/memory_sources.dart';

class _Playback extends ChangeNotifier implements SourcePlayback {
  @override
  final entry = const SourceEntry(sourceId: 'cloud', id: 'book', title: 'An audiobook', kind: SourceItemKind.audiobook);
  @override
  PublicationProgress? get progress => null;
  @override
  PublicationMode get mode => PublicationMode.listening;
  @override
  bool get active => true;
  @override
  bool get video => false;
  @override
  Player? get player => null;
  @override
  bool get opening => false;
  @override
  bool get playing => false;
  @override
  bool fullPlayerVisible = false;
  @override
  int positionMs = 3600000;
  @override
  int get durationMs => 36000000;
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
  bool get hasCompleteTimeline => true;
  @override
  bool get canUndoSeek => false;
  @override
  DateTime? get sleepDeadline => null;
  @override
  double get speed => 1;
  @override
  bool get sleepEnabled => false;
  @override
  BookChapter? get currentChapter => null;
  @override
  List<BookChapter> get chapters => const [];
  @override
  SourceFailure? get failure => null;
  final seeks = <int>[];
  int previous = 0;
  int next = 0;
  @override
  Future<void> seek(int position) async {
    seeks.add(position);
    positionMs = position;
    notifyListeners();
  }

  @override
  Future<void> previousChapter() async => previous++;
  @override
  Future<void> nextChapter() async => next++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('audiobook controls wrap at large text and expose keyboard and spoken navigation', (tester) async {
    final directory = (await tester.runAsync(() => Directory.systemTemp.createTemp('plezy-player-a11y-')))!;
    final db = SourceDatabase(NativeDatabase.memory());
    final sources = MemorySources(SourceRepository(db), directory);
    final playback = _Playback();
    addTearDown(() async {
      playback.dispose();
      sources.dispose();
      await db.close();
      await directory.delete(recursive: true);
    });
    LocaleSettings.setLocaleSync(AppLocale.en);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MultiviewWorkspaceController()),
          ChangeNotifierProvider<SourceController>.value(value: sources),
          ChangeNotifierProvider<SourcePlayback>.value(value: playback),
        ],
        child: InputModeTracker(
          child: MaterialApp(
            theme: monoTheme(MonoPalette.dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: const SourcePlayerScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byTooltip(t.videoControls.previousChapterButton), findsOneWidget);
    expect(find.byTooltip(t.videoControls.nextChapterButton), findsOneWidget);
    expect(find.bySemanticsLabel(t.fileSources.timePosition), findsOneWidget);
    final timeline = tester.getSemantics(find.byType(Slider)).getSemanticsData();
    expect(timeline.label, t.fileSources.timePosition);
    expect(timeline.value, '1 hour');
    expect(timeline.hasAction(SemanticsAction.increase), isTrue);
    expect(timeline.hasAction(SemanticsAction.decrease), isTrue);

    final sliderContext = tester.element(find.byType(Slider));
    Focus.of(sliderContext).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(playback.seeks, [playback.durationMs, 0]);
    expect(tester.widget<FocusableSlider>(find.byType(FocusableSlider)).value, 0);
    await tester.ensureVisible(find.byTooltip(t.videoControls.nextChapterButton));
    await tester.tap(find.byTooltip(t.videoControls.nextChapterButton));
    await tester.pumpAndSettle();
    expect(playback.next, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.dispose();
  });
}
