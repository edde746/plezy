import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/base_notifier.dart';

class _IntNotifier extends BaseNotifier<int> {}

void main() {
  group('BaseNotifier', () {
    test('single listener receives events', () async {
      final n = _IntNotifier();
      final received = <int>[];
      final sub = n.stream.listen(received.add);

      n.notify(1);
      n.notify(2);
      n.notify(3);
      await Future<void>.delayed(Duration.zero);

      expect(received, [1, 2, 3]);
      await sub.cancel();
      n.dispose();
    });

    test('broadcasts to multiple listeners', () async {
      final n = _IntNotifier();
      final a = <int>[];
      final b = <int>[];
      final subA = n.stream.listen(a.add);
      final subB = n.stream.listen(b.add);

      n.notify(10);
      n.notify(20);
      await Future<void>.delayed(Duration.zero);

      expect(a, [10, 20]);
      expect(b, [10, 20]);
      await subA.cancel();
      await subB.cancel();
      n.dispose();
    });

    test('dispose is idempotent', () {
      final n = _IntNotifier();
      n.dispose();
      expect(n.dispose, returnsNormally);
    });

    test('notify after dispose throws StateError', () {
      final n = _IntNotifier();
      n.dispose();
      expect(() => n.notify(1), throwsStateError);
    });

    test('stream access after dispose throws StateError', () {
      final n = _IntNotifier();
      n.dispose();
      expect(() => n.stream, throwsStateError);
    });

    test('controller is lazily created on first access', () async {
      final n = _IntNotifier();
      // Notify before stream access — should still work (creates controller).
      n.notify(7);
      final received = <int>[];
      final sub = n.stream.listen(received.add);
      n.notify(8);
      await Future<void>.delayed(Duration.zero);

      // 7 is dropped because no listener was attached yet.
      expect(received, [8]);
      await sub.cancel();
      n.dispose();
    });

    test('dispose closes the underlying controller (done event fires)', () async {
      final n = _IntNotifier();
      final doneCompleter = Completer<void>();
      final sub = n.stream.listen((_) {}, onDone: doneCompleter.complete);
      n.dispose();
      await doneCompleter.future.timeout(const Duration(seconds: 1));
      expect(doneCompleter.isCompleted, isTrue);
      await sub.cancel();
    });
  });
}
