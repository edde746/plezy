import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/services/gamepad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one-shot reads do not subscribe to input-mode changes', (tester) async {
    var listeningBuilds = 0;
    var oneShotBuilds = 0;
    InputMode? listeningMode;
    InputMode? oneShotMode;

    await tester.pumpWidget(
      InputModeTracker(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  listeningBuilds++;
                  listeningMode = InputModeTracker.of(context);
                  return const SizedBox.shrink();
                },
              ),
              Builder(
                builder: (context) {
                  oneShotBuilds++;
                  oneShotMode = InputModeTracker.of(context, listen: false);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(listeningMode, InputMode.pointer);
    expect(oneShotMode, InputMode.pointer);
    expect(listeningBuilds, 1);
    expect(oneShotBuilds, 1);

    GamepadService.onGamepadInput!.call();
    await tester.pump();

    expect(listeningMode, InputMode.keyboard);
    expect(listeningBuilds, 2);
    expect(oneShotMode, InputMode.pointer);
    expect(oneShotBuilds, 1);
  });
}
