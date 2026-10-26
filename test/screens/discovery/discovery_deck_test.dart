import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/discovery/discovery_controls.dart';
import 'package:plezy/screens/discovery/discovery_deck_view.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/platform_detector.dart';

Widget app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  bool accessible = false,
  bool reduced = false,
}) => TranslationProvider(
  child: InputModeTracker(
    child: MaterialApp(
      theme: monoTheme(MonoPalette.dark),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            accessibleNavigation: accessible,
            disableAnimations: reduced,
          ),
          child: Directionality(
            textDirection: direction,
            child: Scaffold(
              appBar: AppBar(title: const Text('Find your next')),
              body: child,
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

  testWidgets('empty deck keeps restart reachable in a small window with large text', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 320);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var refreshes = 0;
    await tester.pumpWidget(
      app(
        Column(
          children: [
            Expanded(
              child: DiscoveryEmptyView(
                heading: 'Nothing matches this moment',
                hint: 'Try another format or give yourself more time.',
                icon: Symbols.explore_rounded,
                onRefresh: () => refreshes++,
              ),
            ),
            const SizedBox(height: 72),
          ],
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.text(t.discover.findNext.refresh));
    expect(refreshes, 1);
  });

  for (final size in [
    const Size(320, 320),
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 720),
    const Size(3840, 2160),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('actions fit without scrolling at $size, text scale $scale', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var saves = 0;
        await tester.pumpWidget(
          app(
            DiscoveryDeckView(
              choiceId: 'one',
              title: 'A very long title that can wrap over many lines '.repeat(5),
              subtitle: 'Subtitle '.repeat(100),
              facts: 'Movie · 120 minutes',
              summary: 'Synopsis '.repeat(2000),
              artwork: const ColoredBox(color: Colors.indigo),
              artworkAspectRatio: 2 / 3,
              enabled: true,
              onSave: () => saves++,
              onSkip: () {},
              onDetails: () {},
              actions: DiscoveryActionBar(
                primaryLabel: 'Play',
                primaryIcon: Symbols.play_arrow_rounded,
                onSave: () => saves++,
                onSkip: () {},
                onOpen: () {},
                onDetails: () {},
                onUndo: () {},
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsNothing);
        for (final label in ['Not now', 'Save', 'Play', 'Details', 'Undo', 'How it works']) {
          final finder = find.text(label);
          expect(finder, findsOneWidget);
          final rect = tester.getRect(finder);
          expect(rect.top, greaterThanOrEqualTo(0), reason: label);
          expect(rect.bottom, lessThanOrEqualTo(size.height), reason: label);
          expect(rect.left, greaterThanOrEqualTo(0), reason: label);
          expect(rect.right, lessThanOrEqualTo(size.width), reason: label);
        }
        await tester.tap(find.text('Save'));
        expect(saves, 1);
      });
    }
  }

  for (final rtl in [false, true]) {
    testWidgets('touch and TV arrows agree in ${rtl ? 'RTL' : 'LTR'}; repeats do not skip picks', (tester) async {
      var saved = 0, skipped = 0, opened = 0;
      late StateSetter rebuild;
      var choiceId = 'one';
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Center(
                child: SizedBox(
                  width: 300,
                  height: 350,
                  child: DiscoverySwipeCard(
                    choiceId: choiceId,
                    canSwipe: true,
                    autofocus: true,
                    onSave: () => saved++,
                    onSkip: () => skipped++,
                    onDetails: () => opened++,
                    child: const ColoredBox(color: Colors.blue),
                  ),
                ),
              );
            },
          ),
          direction: rtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      );
      await tester.pumpAndSettle();
      final card = find.byType(DiscoverySwipeCard);
      await tester.drag(card, Offset(rtl ? -160 : 160, 0));
      await tester.pump();
      expect(saved, 1);
      await tester.drag(card, Offset(rtl ? 160 : -160, 0));
      await tester.pump();
      expect(skipped, 1);
      await tester.drag(card, const Offset(28, 0));
      await tester.pump();
      expect(saved + skipped, 2);
      final saveKey = rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
      final skipKey = rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
      await tester.sendKeyDownEvent(saveKey);
      await tester.pump();
      expect(saved, 2);
      rebuild(() => choiceId = 'two');
      await tester.pump();
      await tester.sendKeyRepeatEvent(saveKey);
      await tester.sendKeyUpEvent(saveKey);
      await tester.pump();
      expect(saved, 2);
      await tester.sendKeyEvent(skipKey);
      await tester.pump();
      expect(skipped, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('screen reader mode keeps buttons usable without swipe interception', (tester) async {
    var actions = 0;
    await tester.pumpWidget(
      app(
        DiscoveryDeckView(
          choiceId: 'accessible',
          title: 'Accessible title',
          subtitle: '',
          facts: 'Book',
          summary: '',
          artwork: const ColoredBox(color: Colors.blue),
          artworkAspectRatio: 2 / 3,
          enabled: true,
          onSave: () => actions++,
          onSkip: () => actions++,
          onDetails: () {},
          actions: DiscoveryActionBar(
            primaryLabel: 'Read',
            primaryIcon: Symbols.menu_book_rounded,
            onSave: () => actions++,
            onSkip: () => actions++,
            onOpen: () {},
            onDetails: () {},
          ),
        ),
        accessible: true,
      ),
    );
    await tester.drag(find.byType(DiscoverySwipeCard), const Offset(240, 0));
    await tester.pump();
    expect(actions, 0);
    expect(find.text(t.discover.findNext.chooseHint), findsOneWidget);
    await tester.tap(find.text('Save'));
    expect(actions, 1);
    final semantics = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.widgetWithText(OutlinedButton, 'Save')),
      matchesSemantics(
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        label: 'Save',
        isFocusable: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('help explains outcomes and is reachable without leaving the deck', (tester) async {
    await tester.pumpWidget(app(DiscoveryActionBar(primaryLabel: 'Play', primaryIcon: Symbols.play_arrow_rounded)));
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text(t.discover.findNext.notNowHelp), findsOneWidget);
    expect(find.text(t.discover.findNext.saveHelp), findsOneWidget);
    expect(find.text(t.discover.findNext.controlsHelp), findsOneWidget);
    await tester.ensureVisible(find.text('Close'));
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text(t.discover.findNext.saveHelp), findsNothing);
  });

  testWidgets('RTL buttons visibly match the physical swipe directions', (tester) async {
    await tester.runAsync(() => LocaleSettings.setLocale(AppLocale.ar));
    await tester.pumpWidget(
      app(
        DiscoveryActionBar(
          primaryLabel: t.discover.findNext.read,
          primaryIcon: Symbols.menu_book_rounded,
          onSave: () {},
          onSkip: () {},
          onOpen: () {},
          onDetails: () {},
        ),
        direction: TextDirection.rtl,
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getCenter(find.text(t.common.save)).dx,
      lessThan(tester.getCenter(find.text(t.discover.findNext.notNow)).dx),
    );
    expect(
      find.descendant(
        of: find.widgetWithText(OutlinedButton, t.common.save),
        matching: find.byIcon(Symbols.arrow_back_rounded),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reduced motion keeps the card still and disabled controls cannot commit', (tester) async {
    var decisions = 0;
    var enabled = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: DiscoverySwipeCard(
                  choiceId: 'motion',
                  canSwipe: enabled,
                  autofocus: true,
                  onSave: () => decisions++,
                  onSkip: () => decisions++,
                  child: const ColoredBox(color: Colors.blue),
                ),
              ),
            );
          },
        ),
        reduced: true,
      ),
    );
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(tester.getCenter(find.byType(DiscoverySwipeCard)));
    await gesture.moveBy(const Offset(160, 0));
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.descendant(of: find.byType(DiscoverySwipeCard), matching: find.byType(Transform)).last,
    );
    expect(transform.transform.getTranslation().x, 0);
    expect(find.textContaining('Release to confirm'), findsOneWidget);
    await gesture.up();
    expect(decisions, 1);
    rebuild(() => enabled = false);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.drag(find.byType(DiscoverySwipeCard), const Offset(160, 0));
    expect(decisions, 1);
  });

  testWidgets('TV hint explains focused-cover controls', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    addTearDown(() => TvDetectionService.debugSetAppleTVOverride(null));
    await tester.pumpWidget(
      app(const DiscoveryActionBar(primaryLabel: 'Play', primaryIcon: Symbols.play_arrow_rounded)),
    );
    expect(find.text(t.discover.findNext.remoteHint), findsOneWidget);
  });
}

extension on String {
  String repeat(int count) => List.filled(count, this).join();
}
