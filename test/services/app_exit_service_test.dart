import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/app_exit_service.dart';

void main() {
  test('desktop exit uses the required application exit API', () async {
    ui.AppExitType? requestedType;
    int? requestedCode;

    expect(
      await AppExitService.requestExit(
        exitApplicationForTesting: (exitType, exitCode) async {
          requestedType = exitType;
          requestedCode = exitCode;
          return ui.AppExitResponse.exit;
        },
      ),
      isTrue,
    );
    expect(requestedType, ui.AppExitType.required);
    expect(requestedCode, 0);
  });

  // The window's close button must run the registered onExitRequested handlers
  // (app-level teardown, including the terminal playback report), which only a
  // cancelable request does — `required` skips them.
  test('graceful desktop exit uses a cancelable application exit', () async {
    ui.AppExitType? requestedType;
    int? requestedCode;

    expect(
      await AppExitService.requestGracefulExit(
        exitApplicationForTesting: (exitType, exitCode) async {
          requestedType = exitType;
          requestedCode = exitCode;
          return ui.AppExitResponse.exit;
        },
      ),
      isTrue,
    );
    expect(requestedType, ui.AppExitType.cancelable);
    expect(requestedCode, 0);
  });

  test('a declined graceful exit reports failure so the caller can hard-exit', () async {
    expect(
      await AppExitService.requestGracefulExit(exitApplicationForTesting: (_, _) async => ui.AppExitResponse.cancel),
      isFalse,
    );
  });
}
