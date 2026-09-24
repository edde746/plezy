import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/utils/dialogs.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/widgets/focusable_filter_chip.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/tag_edit_dialog.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('suggestion chips appear once the future resolves and tapping one adds the tag', (tester) async {
    final suggestions = Completer<List<String>>();
    final result = await _pumpDialog(tester, initialTags: const ['existing'], suggestionsFuture: suggestions.future);

    expect(find.byType(FocusableFilterChip), findsNothing);

    suggestions.complete(['kids', 'horror']);
    await tester.pumpAndSettle();

    expect(find.text('kids'), findsOneWidget);
    expect(find.text('horror'), findsOneWidget);

    await tester.tap(find.text('kids'));
    await tester.pumpAndSettle();

    // The chip disappears once applied and the tag joins the editable list.
    expect(find.byType(FocusableFilterChip), findsOneWidget);
    expect(find.text('kids'), findsOneWidget);

    await _save(tester);
    expect(await result.future.future, ['existing', 'kids']);
  });

  testWidgets('suggestions filter by the typed text and exclude applied tags', (tester) async {
    await _pumpDialog(
      tester,
      initialTags: const ['kids'],
      suggestionsFuture: Future.value(['kids', 'horror', 'holiday']),
    );
    await tester.pumpAndSettle();

    // 'kids' is already applied — only the other two show.
    expect(find.byType(FocusableFilterChip), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'hor');
    await tester.pumpAndSettle();

    expect(find.text('horror'), findsOneWidget);
    expect(find.text('holiday'), findsNothing);
  });

  testWidgets('a failed suggestions future still leaves the dialog usable', (tester) async {
    final suggestions = Completer<List<String>>();
    final result = await _pumpDialog(tester, initialTags: const [], suggestionsFuture: suggestions.future);

    suggestions.completeError(StateError('offline'));
    await tester.pumpAndSettle();

    expect(find.byType(FocusableFilterChip), findsNothing);

    await tester.enterText(find.byType(TextField), 'manual');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await _save(tester);
    expect(await result.future.future, ['manual']);
  });

  testWidgets('a suggestion matching an applied tag with different casing stays hidden', (tester) async {
    await _pumpDialog(tester, initialTags: const ['Kids'], suggestionsFuture: Future.value(['kids', 'horror']));
    await tester.pumpAndSettle();

    expect(find.byType(FocusableFilterChip), findsOneWidget);
    expect(find.text('horror'), findsOneWidget);
  });

  testWidgets('D-pad can leave the suggestion chips and reach Save', (tester) async {
    await _pumpDialog(tester, initialTags: const [], suggestionsFuture: Future.value(['a', 'b', 'c', 'd', 'e', 'f']));
    await tester.pumpAndSettle();

    // Enter keyboard mode, then walk: field → first chip → … → Save.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(find.byType(FocusableFilterChip), findsWidgets);

    // From the first chip, RIGHT and DOWN must escape the chip row — the chip
    // mixin consumes both keys, so this regresses if the callbacks are dropped.
    for (var i = 0; i < 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      if (_saveHasFocus(tester)) break;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      if (_saveHasFocus(tester)) break;
    }

    expect(_saveHasFocus(tester), isTrue, reason: 'D-pad must reach Save past the chip row');
  });

  // #2453: the tag list scrolls past ~7 tags, leaving the last visible tile cut
  // off by the viewport. Its hover highlight used to paint on the dialog's
  // Material, past the list edge, over a strip that clicks fall through — the
  // tag looked clickable where it was not.
  testWidgets('a partly scrolled-out tag keeps its hover highlight inside the list', (tester) async {
    await _pumpDialog(tester, initialTags: [for (var i = 0; i < 12; i++) 'tag$i']);

    final listRect = tester.getRect(find.byType(ListView));
    final tileRect = tester.getRect(find.byType(FocusableListTile).last);
    expect(tileRect.bottom, greaterThan(listRect.bottom), reason: 'precondition: the last built tile is cut off');

    final insideTile = Offset(tileRect.center.dx, tileRect.top + 2);
    final pastListEdge = Offset(tileRect.center.dx, (listRect.bottom + tileRect.bottom) / 2);
    final idleInside = await _pixel(tester, insideTile);
    final idlePastEdge = await _pixel(tester, pastListEdge);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset(tileRect.center.dx, tileRect.top + 10));
    await tester.pumpAndSettle();

    expect(await _pixel(tester, insideTile), isNot(idleInside), reason: 'hovering highlights the visible tile');
    expect(await _pixel(tester, pastListEdge), idlePastEdge, reason: 'the highlight must not leak past the list');
  });
}

class _DialogResult {
  final Completer<List<String>?> future = Completer();
}

Future<_DialogResult> _pumpDialog(
  WidgetTester tester, {
  required List<String> initialTags,
  Future<List<String>>? suggestionsFuture,
}) async {
  tester.view.physicalSize = const Size(1280, 720);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final result = _DialogResult();
  await tester.pumpWidget(
    InputModeTracker(
      child: TranslationProvider(
        child: MaterialApp(
          theme: monoTheme(dark: true),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    final value = await showScopedDialog<List<String>>(
                      context: context,
                      builder: (_) =>
                          TagEditDialog(title: 'Label', initialTags: initialTags, suggestionsFuture: suggestionsFuture),
                    );
                    result.future.complete(value);
                  },
                  child: const Text('Open tags'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open tags'));
  await tester.pumpAndSettle();
  expect(find.byType(TagEditDialog), findsOneWidget);
  return result;
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text(t.common.save));
  await tester.pumpAndSettle();
}

bool _saveHasFocus(WidgetTester tester) {
  final saveButton = find.ancestor(of: find.text(t.common.save), matching: find.byType(DialogActionButton));
  final buttonElement = tester.element(saveButton);
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  var inside = false;
  focused.visitAncestorElements((element) {
    if (element == buttonElement) inside = true;
    return !inside;
  });
  return inside;
}

/// ARGB of the dialog route's painted frame at the global [position].
Future<int> _pixel(WidgetTester tester, Offset position) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.ancestor(of: find.byType(TagEditDialog), matching: find.byType(RepaintBoundary)).first,
  );
  final local = boundary.globalToLocal(position);
  late int width;
  late ByteData bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    width = image.width;
    bytes = (await image.toByteData())!;
    image.dispose();
  });
  final i = (local.dy.floor() * width + local.dx.floor()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  ).toARGB32();
}
