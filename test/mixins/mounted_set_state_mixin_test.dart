import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/mounted_set_state_mixin.dart';

class _Probe extends StatefulWidget {
  const _Probe({this.onState});
  final void Function(_ProbeState)? onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with MountedSetStateMixin<_Probe> {
  int counter = 0;
  int builds = 0;

  @override
  void initState() {
    super.initState();
    widget.onState?.call(this);
  }

  @override
  Widget build(BuildContext context) {
    builds++;
    return Text('count=$counter', textDirection: TextDirection.ltr);
  }
}

void main() {
  group('MountedSetStateMixin', () {
    testWidgets('setStateIfMounted runs the callback and triggers rebuild while mounted', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      final initialBuilds = state.builds;
      state.setStateIfMounted(() => state.counter = 5);
      await tester.pump();

      expect(state.counter, 5);
      expect(state.builds, greaterThan(initialBuilds));
      expect(find.text('count=5'), findsOneWidget);
    });

    testWidgets('setStateIfMounted is a no-op after the widget is unmounted', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      // Unmount by replacing the widget tree.
      await tester.pumpWidget(const SizedBox.shrink());

      expect(state.mounted, isFalse);
      final buildsBefore = state.builds;

      // Should not throw and should not invoke setState (which would assert on
      // an unmounted state in debug mode).
      expect(() => state.setStateIfMounted(() => state.counter = 99), returnsNormally);

      // The callback ran is irrelevant; what matters is no setState fired.
      // counter stays at its previous value because the callback was skipped.
      expect(state.counter, 0);
      expect(state.builds, buildsBefore);
    });

    testWidgets('setStateIfMounted callback is invoked exactly once per call when mounted', (tester) async {
      late _ProbeState state;
      await tester.pumpWidget(_Probe(onState: (s) => state = s));

      var calls = 0;
      state.setStateIfMounted(() => calls++);
      await tester.pump();

      expect(calls, 1);
    });
  });
}
