import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/hero_carousel_backdrop.dart';

const _phone = Size(390, 560);
const _desktop = Size(1600, 600);

class _Art extends StatelessWidget {
  const _Art(this.index, {required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Finder _art(int index) => find.byWidgetPredicate((w) => w is _Art && w.index == index);

T _above<T extends Widget>(WidgetTester tester, int index) =>
    tester.widget<T>(find.ancestor(of: _art(index), matching: find.byType(T)).first);

double _opacity(WidgetTester tester, int index) => _above<Opacity>(tester, index).opacity;

double _drift(WidgetTester tester, int index) => _above<FractionalTranslation>(tester, index).translation.dx;

double _widthFactor(WidgetTester tester, int index) => _above<FractionallySizedBox>(tester, index).widthFactor!;

/// Half the extra width on each side: how far the layer can move before its
/// edge would enter the viewport.
double _overflow(WidgetTester tester, int index) => (_widthFactor(tester, index) - 1) / 2;

List<int> _mounted(WidgetTester tester) => tester.widgetList<_Art>(find.byType(_Art)).map((a) => a.index).toList();

/// Mirrors the Discover hero: backdrop behind a [PageView] whose
/// `onPageChanged` drives the settled index.
Future<PageController> _pump(
  WidgetTester tester, {
  Size viewSize = _phone,
  int initialPage = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = PageController(initialPage: initialPage);
  final current = ValueNotifier<int>(initialPage);
  addTearDown(controller.dispose);
  addTearDown(current.dispose);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: viewSize, disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<int>(
                valueListenable: current,
                builder: (context, index, _) => HeroCarouselBackdrop(
                  controller: controller,
                  currentIndex: index,
                  itemCount: 4,
                  backdropBuilder: (context, index, active, artSize) => _Art(index, active: active),
                ),
              ),
            ),
            PageView.builder(
              controller: controller,
              physics: const BouncingScrollPhysics(),
              itemCount: 4,
              onPageChanged: (index) => current.value = index,
              itemBuilder: (context, index) => const SizedBox.expand(),
            ),
          ],
        ),
      ),
    ),
  );
  return controller;
}

/// Starts a drag and moves past touch slop so later moves track 1:1.
Future<TestGesture> _startDrag(WidgetTester tester, double direction) async {
  final gesture = await tester.startGesture(_phone.center(Offset.zero));
  await gesture.moveBy(Offset(20 * direction, 0));
  await tester.pump();
  return gesture;
}

void main() {
  testWidgets('settled page shows only its artwork; neighbours are mounted but transparent', (tester) async {
    await _pump(tester);

    expect(_mounted(tester), [0, 1, 2], reason: 'the far page is not mounted; neighbours preload');
    expect(
      [
        for (final i in [0, 1, 2]) _opacity(tester, i),
      ],
      [0.0, 1.0, 0.0],
    );
    expect(tester.widgetList<_Art>(find.byType(_Art)).where((a) => a.active).map((a) => a.index), [1]);
    expect(_drift(tester, 1), 0.0, reason: 'settled art is centred in its overflow');
  });

  testWidgets('a forward swipe fades the next artwork over an opaque current one, without a pop at mid-swipe', (
    tester,
  ) async {
    final controller = await _pump(tester);
    final gesture = await _startDrag(tester, -1);
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();

    var page = controller.page!;
    expect(page, inExclusiveRange(1.0, 1.5));
    expect(_opacity(tester, 1), 1.0, reason: 'outgoing stays opaque, so the crossfade never dips');
    expect(_opacity(tester, 2), closeTo(page - 1, 1e-9));
    expect(_drift(tester, 1), lessThan(0), reason: 'outgoing drifts left with the swipe');
    expect(_drift(tester, 2), greaterThan(0), reason: 'incoming drifts in from the right');
    for (final i in [1, 2]) {
      expect(_drift(tester, i).abs(), lessThanOrEqualTo(_overflow(tester, i)), reason: 'no art edge enters view');
    }

    // Crossing the midpoint flips the settled index; the fade must continue.
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    page = controller.page!;
    expect(page, inExclusiveRange(1.5, 2.0));
    expect(_mounted(tester), [1, 2, 3]);
    expect(_opacity(tester, 1), 1.0);
    expect(_opacity(tester, 2), closeTo(page - 1, 1e-9));
    expect(_opacity(tester, 3), 0.0);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.page, 2.0);
    expect(
      [
        for (final i in [1, 2, 3]) _opacity(tester, i),
      ],
      [0.0, 1.0, 0.0],
    );
    expect(_drift(tester, 2), 0.0);
  });

  testWidgets('a backward swipe fades the current artwork out over the previous one', (tester) async {
    final controller = await _pump(tester, initialPage: 2);
    final gesture = await _startDrag(tester, 1);
    await gesture.moveBy(const Offset(140, 0));
    await tester.pump();

    final page = controller.page!;
    expect(page, inExclusiveRange(1.5, 2.0));
    expect(_opacity(tester, 1), 1.0, reason: 'previous page paints below at full opacity');
    expect(_opacity(tester, 2), closeTo(page - 1, 1e-9));
    expect(_drift(tester, 2), greaterThan(0), reason: 'outgoing drifts right with the swipe');
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a portrait phone drifts a quarter width; a wide viewport caps the zoom the drift costs', (tester) async {
    await _pump(tester);
    expect(_overflow(tester, 1), greaterThanOrEqualTo(0.25), reason: 'cover-fit art has spare width to drift in');

    await _pump(tester, viewSize: _desktop);
    final widthFactor = _widthFactor(tester, 1);
    expect(widthFactor, greaterThan(1.0), reason: 'wide heroes still drift');
    expect(widthFactor, lessThanOrEqualTo(1.2), reason: 'art fit by width zooms by the widened box');
  });

  testWidgets('reduced motion keeps the crossfade but drops the drift', (tester) async {
    final controller = await _pump(tester, disableAnimations: true);
    final gesture = await _startDrag(tester, -1);
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();

    expect(_opacity(tester, 2), closeTo(controller.page! - 1, 1e-9));
    for (final i in [1, 2]) {
      expect(_drift(tester, i), 0.0);
      expect(_widthFactor(tester, i), 1.0);
    }
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('overscroll past the first page neither fades nor moves its artwork', (tester) async {
    final controller = await _pump(tester, initialPage: 0);
    final gesture = await _startDrag(tester, 1);
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();

    expect(controller.position.pixels, lessThan(0), reason: 'the drag overscrolls the first page');
    expect(_opacity(tester, 0), 1.0);
    expect(_drift(tester, 0), 0.0);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
