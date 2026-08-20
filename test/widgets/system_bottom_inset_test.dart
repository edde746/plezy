import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_action_bar.dart';
import 'package:plezy/mixins/grid_focus_node_mixin.dart';
import 'package:plezy/screens/focusable_detail_screen_mixin.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/focused_scroll_scaffold.dart';
import 'package:plezy/widgets/system_bottom_inset.dart';

/// Stand-in for the Android 3-button navigation bar (#1766).
const _navBarInset = 48.0;
const _viewportHeight = 800.0;
const _rowHeight = 100.0;
const _rowCount = 20;
const _lastRow = 'Row ${_rowCount - 1}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  group('SliverSystemBottomInset', () {
    testWidgets('reserves exactly the system bottom inset as extra scroll extent', (tester) async {
      await _pump(tester, const _PlainScrollView());

      expect(_position(tester).maxScrollExtent, 1000 - _viewportHeight + _navBarInset);
    });

    testWidgets('collapses to nothing when the platform reports no bottom inset', (tester) async {
      await _pump(tester, const _PlainScrollView(), bottomInset: 0);

      expect(_position(tester).maxScrollExtent, 1000 - _viewportHeight);
    });
  });

  group('FocusedScrollScaffold', () {
    testWidgets('scrolls its last row clear of the system navigation bar', (tester) async {
      await _pump(tester, FocusedScrollScaffold(title: const Text('Settings'), slivers: [_rows()]));
      await _scrollToEnd(tester);

      expect(tester.getRect(find.text(_lastRow)).bottom, moreOrLessEquals(_viewportHeight - _navBarInset));
    });

    testWidgets('leaves the last row flush with the viewport when there is no inset', (tester) async {
      await _pump(tester, FocusedScrollScaffold(title: const Text('Settings'), slivers: [_rows()]), bottomInset: 0);
      await _scrollToEnd(tester);

      expect(tester.getRect(find.text(_lastRow)).bottom, moreOrLessEquals(_viewportHeight));
    });
  });

  group('FocusableDetailScreenMixin.buildDetailScaffold', () {
    testWidgets('scrolls its last row clear of the system navigation bar', (tester) async {
      await _pump(tester, const _DetailSurface());
      await _scrollToEnd(tester);

      expect(tester.getRect(find.text(_lastRow)).bottom, moreOrLessEquals(_viewportHeight - _navBarInset));
    });

    // The music detail screens append their own spacer to clear the floating
    // mini-player. That spacer and the system inset must add up, not replace
    // each other — the mini-player itself already floats above the nav bar.
    testWidgets('stacks the system inset under a screen-supplied trailing spacer', (tester) async {
      const spacer = 64.0;
      await _pump(tester, const _DetailSurface(trailingSpacer: spacer));
      await _scrollToEnd(tester);

      expect(tester.getRect(find.text(_lastRow)).bottom, moreOrLessEquals(_viewportHeight - _navBarInset - spacer));
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child, {double bottomInset = _navBarInset}) async {
  tester.view.physicalSize = const Size(400, _viewportHeight);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        // copyWith keeps the real viewport metrics and overrides only the
        // padding, so layout still sees a 400x800 phone.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: EdgeInsets.only(bottom: bottomInset)),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ScrollPosition _position(WidgetTester tester) => tester.state<ScrollableState>(find.byType(Scrollable)).position;

Future<void> _scrollToEnd(WidgetTester tester) async {
  final position = _position(tester);
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
}

Widget _rows() => SliverList.builder(
  itemCount: _rowCount,
  itemBuilder: (context, index) => SizedBox(height: _rowHeight, child: Text('Row $index')),
);

class _PlainScrollView extends StatelessWidget {
  const _PlainScrollView();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: 1000)),
        SliverSystemBottomInset(),
      ],
    );
  }
}

class _DetailSurface extends StatefulWidget {
  const _DetailSurface({this.trailingSpacer = 0});

  final double trailingSpacer;

  @override
  State<_DetailSurface> createState() => _DetailSurfaceState();
}

class _DetailSurfaceState extends State<_DetailSurface>
    with GridFocusNodeMixin<_DetailSurface>, FocusableDetailScreenMixin<_DetailSurface> {
  @override
  bool get hasItems => true;

  @override
  List<FocusableAction> getAppBarActions() => const [];

  @override
  void dispose() {
    disposeFocusResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildDetailScaffold(
      slivers: [
        _rows(),
        if (widget.trailingSpacer > 0) SliverToBoxAdapter(child: SizedBox(height: widget.trailingSpacer)),
      ],
    );
  }
}
