import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/context_menu_tap_mixin.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.onState});

  final void Function(_ProbeState state) onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ContextMenuTapMixin<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onState(this);
  }

  @override
  Widget build(BuildContext context) =>
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContextMenuTapMixin', () {
    testWidgets('contextMenuKey remains stable across rebuilds', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));
      final initialKey = state.contextMenuKey;

      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      expect(identical(state.contextMenuKey, initialKey), isTrue);
    });

    testWidgets('isContextMenuOpen returns false when no menu is mounted', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));
      // currentState is null — the `?? false` fallback must hold.
      expect(state.isContextMenuOpen, isFalse);
    });

    testWidgets('storeTapPosition records the global tap offset', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      const offset = Offset(123.0, 456.0);
      state.storeTapPosition(TapDownDetails(globalPosition: offset));

      expect(state.lastTapPosition, offset);
    });

    testWidgets('showContextMenuFromTap and showContextMenu are no-ops without a mounted menu', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      // Both helpers go through `currentState?.showContextMenu(...)` so when
      // the GlobalKey isn't attached to a MediaContextMenu the calls silently
      // succeed. This is the contract: tap handlers can fire even when the
      // menu hasn't been instantiated yet.
      expect(state.showContextMenu, returnsNormally);
      expect(state.showContextMenuFromTap, returnsNormally);
    });
  });
}
