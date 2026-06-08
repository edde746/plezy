import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/orientation_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restoreSystemUI explicitly shows overlays before edge-to-edge', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await OrientationHelper.restoreSystemUI();

    expect(calls, hasLength(2));
    expect(calls[0].method, 'SystemChrome.setEnabledSystemUIOverlays');
    expect(calls[0].arguments, ['SystemUiOverlay.top', 'SystemUiOverlay.bottom']);
    expect(calls[1].method, 'SystemChrome.setEnabledSystemUIMode');
    expect(calls[1].arguments, 'SystemUiMode.edgeToEdge');
  });
}
