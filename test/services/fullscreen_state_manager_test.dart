import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/fullscreen_state_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FullscreenStateManager manager;

  setUp(() {
    manager = FullscreenStateManager();
  });

  // The manager is a singleton, so every case has to hand it back windowed with
  // no scope open. No test below leaves more than one scope on the stack.
  tearDown(() {
    manager.endScope();
    manager.setFullscreen(false);
  });

  group('scope ownership', () {
    test('fullscreen predating the scope is not owned by it', () {
      manager.setFullscreen(true);

      manager.beginScope();

      expect(manager.scopeOwnsFullscreen, isFalse);
    });

    test('fullscreen entered inside the scope is owned by it', () {
      manager.beginScope();

      manager.setFullscreen(true);

      expect(manager.scopeOwnsFullscreen, isTrue);
    });

    test('leaving fullscreen inside the scope drops ownership', () {
      manager.beginScope();
      manager.setFullscreen(true);

      manager.setFullscreen(false);

      expect(manager.scopeOwnsFullscreen, isFalse);
    });

    test('ownership does not survive the scope closing', () {
      manager.beginScope();
      manager.setFullscreen(true);

      manager.endScope();

      expect(manager.scopeOwnsFullscreen, isFalse);
    });

    test('ownership carries across a nested scope swap', () {
      manager.beginScope();
      manager.setFullscreen(true);

      // The next episode's player is constructed before the outgoing one is
      // disposed, so the scopes overlap rather than nest cleanly.
      manager.beginScope();
      manager.endScope();

      expect(manager.scopeOwnsFullscreen, isTrue);
    });

    test('fullscreen entered with no scope open is owned by nobody', () {
      manager.setFullscreen(true);

      expect(manager.scopeOwnsFullscreen, isFalse);
    });

    test('unbalanced endScope does not open a scope', () {
      manager.endScope();

      manager.setFullscreen(true);

      expect(manager.scopeOwnsFullscreen, isFalse);
    });
  });
}
