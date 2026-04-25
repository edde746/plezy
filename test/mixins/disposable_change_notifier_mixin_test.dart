import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mixins/disposable_change_notifier_mixin.dart';

class _Probe extends ChangeNotifier with DisposableChangeNotifierMixin {}

void main() {
  group('DisposableChangeNotifierMixin', () {
    test('isDisposed is false on a fresh notifier', () {
      final n = _Probe();
      expect(n.isDisposed, isFalse);
      n.dispose();
    });

    test('safeNotifyListeners returns true and notifies when not disposed', () {
      final n = _Probe();
      var fired = 0;
      n.addListener(() => fired++);

      final result = n.safeNotifyListeners();

      expect(result, isTrue);
      expect(fired, 1);
      n.dispose();
    });

    test('safeNotifyListeners returns false and does not notify after dispose', () {
      final n = _Probe();
      var fired = 0;
      n.addListener(() => fired++);

      n.dispose();
      final result = n.safeNotifyListeners();

      expect(result, isFalse);
      expect(fired, 0);
    });

    test('isDisposed flips to true after dispose()', () {
      final n = _Probe();
      expect(n.isDisposed, isFalse);

      n.dispose();

      expect(n.isDisposed, isTrue);
    });

    test('multiple safeNotifyListeners calls succeed before dispose', () {
      final n = _Probe();
      var fired = 0;
      n.addListener(() => fired++);

      expect(n.safeNotifyListeners(), isTrue);
      expect(n.safeNotifyListeners(), isTrue);
      expect(n.safeNotifyListeners(), isTrue);

      expect(fired, 3);
      n.dispose();
    });

    test('safeNotifyListeners after dispose does not throw', () {
      final n = _Probe();
      n.dispose();

      // Without the mixin's guard, ChangeNotifier.notifyListeners would throw
      // a debug-only assertion. The whole point of the mixin is to no-op.
      expect(n.safeNotifyListeners, returnsNormally);
    });
  });
}
