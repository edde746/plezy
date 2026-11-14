import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music/audio_route_service.dart';

/// The route is an *observation*, and these cover the two ways it can be
/// wrong: reported as something it is not, or not reported at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('test/audio_route');
  const eventChannel = EventChannel('test/audio_route/events');

  late List<Map<String, Object?>> answers;
  late StreamController<Map<String, Object?>> pushed;

  /// Drives the event channel the way the platform does, through the binary
  /// messenger, so the codec is exercised rather than bypassed.
  void emit(Map<String, Object?> route) => pushed.add(route);

  setUp(() {
    answers = [];
    pushed = StreamController<Map<String, Object?>>.broadcast();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, (
      call,
    ) async {
      if (call.method != 'getRoute') return null;
      return answers.isEmpty ? null : answers.removeAt(0);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          pushed.stream.listen(sink.success);
        },
      ),
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(eventChannel, null);
    await pushed.close();
  });

  AudioRouteService build({bool supported = true}) =>
      AudioRouteService(methodChannel: methodChannel, eventChannel: eventChannel, supported: supported);

  test('a platform without a system route reports nothing and asks nothing', () async {
    // Android and the desktops have no AVAudioSession, and the AirPlay option
    // must not appear there claiming a route it cannot see.
    answers.add({'name': 'Dining Room', 'kind': 'airPlay'});
    final service = build(supported: false);
    await service.start();

    expect(service.supported, isFalse);
    expect(service.isAirPlay, isFalse);
    expect(service.route, AudioRoute.unknown);
    // The answer was never consumed, so the channel was never called.
    expect(answers, hasLength(1));
    service.dispose();
  });

  test('the route is read once at start rather than waited for', () async {
    // The stream emits on subscribe, but a stream that fails to attach must
    // still leave a usable answer instead of a permanently blank route.
    answers.add({'name': 'Jack’s AirPods', 'kind': 'bluetooth'});
    final service = build();
    await service.start();

    expect(service.route.name, 'Jack’s AirPods');
    expect(service.route.kind, AudioRouteKind.bluetooth);
    expect(service.isAirPlay, isFalse);
    service.dispose();
  });

  test('picking an AirPlay destination arrives as a change, not a poll', () async {
    answers.add({'name': 'iPhone Speaker', 'kind': 'speaker'});
    final service = build();
    await service.start();

    var notifications = 0;
    service.addListener(() => notifications++);

    emit({'name': 'Dining Room', 'kind': 'airPlay'});
    await pumpEventQueue();

    expect(service.isAirPlay, isTrue);
    expect(service.route.name, 'Dining Room');
    expect(notifications, 1);
    service.dispose();
  });

  test('an unchanged route does not notify', () async {
    // The picker rebuilds on every notification, and the route change
    // notification fires for reasons that leave the output port alone
    // (category changes, a mic being reconfigured).
    answers.add({'name': 'iPhone Speaker', 'kind': 'speaker'});
    final service = build();
    await service.start();

    var notifications = 0;
    service.addListener(() => notifications++);

    emit({'name': 'iPhone Speaker', 'kind': 'speaker'});
    await pumpEventQueue();

    expect(notifications, 0);
    service.dispose();
  });

  test('a missing plugin leaves the route unknown rather than throwing', () async {
    // The whole AirPlay row is optional. A build without the native side must
    // degrade to "no AirPlay offered", never to a crash on the picker.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(methodChannel, null);
    final service = build();
    await service.refresh();

    expect(service.route, AudioRoute.unknown);
    expect(service.isAirPlay, isFalse);
    service.dispose();
  });

  test('an unrecognised port kind is unknown, not guessed at', () {
    expect(AudioRoute.parseKind('somethingNew'), AudioRouteKind.unknown);
    expect(AudioRoute.parseKind(null), AudioRouteKind.unknown);
    expect(AudioRoute.parseKind('airPlay'), AudioRouteKind.airPlay);
  });
}
