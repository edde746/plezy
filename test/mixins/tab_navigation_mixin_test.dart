import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/tab_navigation_mixin.dart';
import 'package:plezy/services/gamepad_service.dart';

/// Probe widget that mounts the mixin against a real BuildContext + Ticker.
///
/// Tests stage [tabCount] focus nodes and read the resulting controller state
/// after [initTabNavigation] runs.
class _Probe extends StatefulWidget {
  const _Probe({super.key, required this.tabCount, required this.onState, this.initialIndex = 0});

  final int tabCount;
  final int initialIndex;
  final void Function(_ProbeState state) onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with TickerProviderStateMixin<_Probe>, TabNavigationMixin<_Probe> {
  late final List<FocusNode> _nodes;
  int onTabChangedCalls = 0;

  @override
  List<FocusNode> get tabChipFocusNodes => _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.tabCount, (i) => FocusNode(debugLabel: 'tab_$i'));
    initTabNavigation();
    if (widget.initialIndex != 0) {
      tabController.index = widget.initialIndex;
    }
    widget.onState(this);
  }

  @override
  void onTabChanged() {
    onTabChangedCalls++;
    super.onTabChanged();
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    disposeTabNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Column(
      children: [for (final node in _nodes) Focus(focusNode: node, child: const SizedBox.shrink())],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TabNavigationMixin', () {
    setUp(GamepadService.debugClearTabNavigationHandlers);

    tearDown(GamepadService.debugClearTabNavigationHandlers);

    testWidgets('initTabNavigation creates a TabController with the right length', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, onState: (s) => state = s));

      expect(state.tabCount, 3);
      expect(state.tabController.length, 3);
      // Initial tab is 0 by default.
      expect(state.tabController.index, 0);
      // Auto-focus suppression flag starts false.
      expect(state.suppressAutoFocus, isFalse);
    });

    testWidgets('initTabNavigation registers owner-scoped bumper navigation', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, onState: (s) => state = s));

      GamepadService.debugDispatchTabNavigation(previous: false);
      await tester.pump();
      expect(state.tabController.index, 1);
    });

    testWidgets('disposing one tab screen preserves another owner registration', (tester) async {
      late _ProbeState first;
      late _ProbeState second;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _Probe(key: const ValueKey('first'), tabCount: 2, onState: (s) => first = s),
              _Probe(key: const ValueKey('second'), tabCount: 2, onState: (s) => second = s),
            ],
          ),
        ),
      );

      GamepadService.debugDispatchTabNavigation(previous: false);
      await tester.pump();
      expect(first.tabController.index, 1);
      expect(second.tabController.index, 0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _Probe(key: const ValueKey('second'), tabCount: 2, onState: (s) => second = s),
        ),
      );
      GamepadService.debugDispatchTabNavigation(previous: false);
      await tester.pump();

      expect(second.tabController.index, 1);
    });

    testWidgets('tabChipFocusNodes drives tabCount; getTabChipFocusNode returns the right node', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 4, onState: (s) => state = s));

      expect(state.tabCount, 4);
      // Each indexed lookup returns the same node reference — the mixin must
      // not stash its own copies.
      for (var i = 0; i < 4; i++) {
        expect(identical(state.getTabChipFocusNode(i), state.tabChipFocusNodes[i]), isTrue);
      }
    });

    testWidgets('goToNextTab advances the index and stops at the last tab', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, onState: (s) => state = s));

      // 0 -> 1
      state.goToNextTab();
      await tester.pump();
      expect(state.tabController.index, 1);
      // suppressAutoFocus is set as a side-effect of programmatic navigation.
      expect(state.suppressAutoFocus, isTrue);

      // 1 -> 2
      state.goToNextTab();
      await tester.pump();
      expect(state.tabController.index, 2);

      // 2 (last) -> stays at 2 (mixin guards against overflow).
      state.goToNextTab();
      await tester.pump();
      expect(state.tabController.index, 2);
    });

    testWidgets('goToPreviousTab decrements the index and stops at the first tab', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, initialIndex: 2, onState: (s) => state = s));

      // 2 -> 1
      state.goToPreviousTab();
      await tester.pump();
      expect(state.tabController.index, 1);

      // 1 -> 0
      state.goToPreviousTab();
      await tester.pump();
      expect(state.tabController.index, 0);

      // 0 (first) -> stays at 0.
      state.goToPreviousTab();
      await tester.pump();
      expect(state.tabController.index, 0);
    });

    testWidgets('dispose + re-init reseats the TabController without LateInitializationError', (tester) async {
      // Regression: libraries_screen calls disposeTabNavigation() then
      // initTabNavigation() inside _updateVisibleTabs whenever the visible
      // tab set changes (e.g. switching between a Plex library with 4 tabs
      // and a Jellyfin library with 1). A `late final` on `tabController`
      // would throw LateInitializationError on the second init; the mixin
      // must allow re-initialization for the lifetime of the State.
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, onState: (s) => state = s));
      final original = state.tabController;

      state.disposeTabNavigation();
      // After dispose+init the controller field must point at a fresh
      // instance so the listener and gamepad bindings reattach cleanly.
      state.initTabNavigation();

      expect(identical(state.tabController, original), isFalse);
      expect(state.tabController.length, 3);
      expect(state.tabController.index, 0);

      // The original is disposed, while the owner-scoped registry points at
      // the newly initialized controller.
      GamepadService.debugDispatchTabNavigation(previous: false);
      await tester.pump();
      expect(state.tabController.index, 1);
    });

    testWidgets('onTabChanged fires when tabController.index changes', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, onState: (s) => state = s));

      final before = state.onTabChangedCalls;
      state.tabController.index = 1;
      // index= triggers an animation; pump until it settles so the listener
      // fires its terminal event.
      await tester.pumpAndSettle();

      expect(state.onTabChangedCalls, greaterThan(before));
    });
    testWidgets('focusTabBar focuses the active chip and suppresses content auto-focus', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 3, initialIndex: 1, onState: (s) => state = s));
      final activeNode = state.getTabChipFocusNode(1);

      expect(activeNode.hasFocus, isFalse);
      state.focusTabBar();
      await tester.pump();

      expect(state.suppressAutoFocus, isTrue);
      expect(activeNode.hasFocus, isTrue);
    });

    testWidgets('onTabBarBack is null-safe outside MainScreenFocusScope (no throw)', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(tabCount: 2, onState: (s) => state = s));

      // Without a MainScreenFocusScope ancestor, the helper hits a null `?.`
      // and returns without doing anything; it must not throw.
      expect(state.onTabBarBack, returnsNormally);
    });
  });
}
