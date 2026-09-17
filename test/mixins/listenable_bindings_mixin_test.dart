import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/listenable_bindings_mixin.dart';

class _Probe extends StatefulWidget {
  const _Probe({required this.notifier, required this.onState});
  final ChangeNotifier notifier;
  final void Function(_ProbeState) onState;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> with ListenableBindingsMixin<_Probe> {
  int notifications = 0;

  @override
  void initState() {
    super.initState();
    bindListenable(widget.notifier, _onNotified);
    widget.onState(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Declared in an extension on purpose: an extension-method tear-off is a
/// fresh closure per evaluation, so `removeListener(_onNotified)` in `dispose`
/// would never match the one `addListener` received. The binding must not
/// depend on tear-off identity.
extension on _ProbeState {
  void _onNotified() => notifications++;
}

class _Notifier extends ChangeNotifier {
  bool get isListened => hasListeners;

  void fire() => notifyListeners();
}

void main() {
  group('ListenableBindingsMixin', () {
    testWidgets('an extension-declared listener stops with the state', (tester) async {
      final notifier = _Notifier();
      addTearDown(notifier.dispose);
      late _ProbeState state;
      await tester.pumpWidget(_Probe(notifier: notifier, onState: (s) => state = s));

      notifier.fire();
      expect(state.notifications, 1);
      expect(notifier.isListened, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(notifier.isListened, isFalse, reason: 'dispose must remove the closure that was registered');

      notifier.fire();
      expect(state.notifications, 1);
    });

    testWidgets('an early release ends the binding and the disposer runs at most once', (tester) async {
      final notifier = _Notifier();
      addTearDown(notifier.dispose);
      late _ProbeState state;
      await tester.pumpWidget(_Probe(notifier: notifier, onState: (s) => state = s));

      var disposed = 0;
      final release = state.ownDisposer(() => disposed++);
      final other = _Notifier();
      addTearDown(other.dispose);
      var otherNotifications = 0;
      final releaseOther = state.bindListenable(other, () => otherNotifications++);

      releaseOther();
      other.fire();
      expect(otherNotifications, 0);
      expect(other.isListened, isFalse);

      release();
      release();
      expect(disposed, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(disposed, 1, reason: 'a released disposer is out of the dispose chain');
      expect(notifier.isListened, isFalse, reason: 'bindings released early do not shadow the rest');
    });
  });
}
