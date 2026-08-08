import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/captions_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CaptionsService.onToggleSubtitleSelector = null;
  });

  test('dispatches toggleSubtitleSelector to the registered callback', () async {
    var toggled = 0;
    CaptionsService.onToggleSubtitleSelector = () => toggled++;

    await CaptionsService.handleMethodCall(const MethodCall('toggleSubtitleSelector'));

    expect(toggled, 1);
  });

  test('no-ops when no callback is registered', () async {
    await CaptionsService.handleMethodCall(const MethodCall('toggleSubtitleSelector'));
  });

  test('ignores unknown methods without calling the callback', () async {
    var toggled = 0;
    CaptionsService.onToggleSubtitleSelector = () => toggled++;

    await CaptionsService.handleMethodCall(const MethodCall('somethingElse'));

    expect(toggled, 0);
  });

  test('resolves the singleton so the constructor registers the channel handler', () {
    final service = CaptionsService();
    expect(identical(service, CaptionsService()), isTrue);
  });
}
