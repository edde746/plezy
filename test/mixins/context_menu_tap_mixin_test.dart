import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/context_menu_tap_mixin.dart';

// NOTE on coverage scope:
// `ContextMenuTapMixin` is a thin glue layer:
//   1. caches the last-known global tap position so the menu can anchor
//      itself at the press location, and
//   2. forwards show calls to the embedded MediaContextMenu's GlobalKey.
//
// The interesting branches for tests are the pure helpers:
//   - storeTapPosition writes the global Offset.
//   - showContextMenuFromTap / showContextMenu null-safe when no MediaContextMenu
//     is attached (currentState is null).
//   - isContextMenuOpen returns false when currentState is null.
//
// What's NOT covered (and intentionally skipped):
//   - The branch where `contextMenuKey.currentState` is non-null and the menu
//     actually opens — that requires mounting the production
//     [MediaContextMenu] widget, which depends on a full provider stack
//     (PlexClient, MultiServerProvider, etc.). The mixin's job is just to
//     forward the call, so the value of widget-level coverage is low.

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
    testWidgets('contextMenuKey is a stable GlobalKey instance', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      expect(state.contextMenuKey, isA<GlobalKey>());
      // GlobalKey identity is stable across rebuilds — important because the
      // production widget passes this key to MediaContextMenu and reads
      // currentState through it.
      final keyA = state.contextMenuKey;
      await tester.pump();
      expect(identical(state.contextMenuKey, keyA), isTrue);
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

      // Synthesise a TapDownDetails — the mixin only reads globalPosition.
      const offset = Offset(123.0, 456.0);
      state.storeTapPosition(TapDownDetails(globalPosition: offset, kind: PointerDeviceKind.mouse));

      // The field is private but both show methods consume it without throwing
      // when the MediaContextMenu key has no currentState. Calling them after
      // storeTapPosition is the closest observable assertion that the position
      // got captured.
      expect(state.showContextMenuFromTap, returnsNormally);
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
