import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/tvos_system_navigation_service.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = BasicMessageChannel<Object?>('flutter/tvos_system_navigation', JSONMessageCodec());
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    TvDetectionService.debugSetAppleTVOverride(true);
    TvosSystemNavigationService.resetForTesting();
  });

  tearDown(() {
    messenger.setMockDecodedMessageHandler<Object?>(channel, null);
    TvDetectionService.debugSetAppleTVOverride(null);
    TvosSystemNavigationService.resetForTesting();
  });

  test('false and null acknowledgements remain retryable until true', () async {
    final messages = <Object?>[];
    final replies = <Object?>[false, null, true];
    messenger.setMockDecodedMessageHandler<Object?>(channel, (message) async {
      messages.add(message);
      return replies.removeAt(0);
    });

    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);

    expect(messages, [
      {'menuPassthroughEnabled': true},
      {'menuPassthroughEnabled': true},
      {'menuPassthroughEnabled': true},
    ]);
  });

  test('serializes an opposing trailing value and latest desired state wins', () async {
    final messages = <Object?>[];
    var activeSends = 0;
    var maximumActiveSends = 0;
    final trueStarted = Completer<void>();
    final releaseTrue = Completer<Object?>();

    messenger.setMockDecodedMessageHandler<Object?>(channel, (message) async {
      messages.add(message);
      activeSends++;
      maximumActiveSends = activeSends > maximumActiveSends ? activeSends : maximumActiveSends;
      try {
        final enabled = (message as Map<Object?, Object?>)['menuPassthroughEnabled'];
        if (enabled == true) {
          trueStarted.complete();
          return await releaseTrue.future;
        }
        return true;
      } finally {
        activeSends--;
      }
    });

    await TvosSystemNavigationService.setMenuPassthroughEnabled(false);
    final enable = TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await trueStarted.future;
    final disable = TvosSystemNavigationService.setMenuPassthroughEnabled(false);
    releaseTrue.complete(true);
    await Future.wait([enable, disable]);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(false);

    expect(maximumActiveSends, 1);
    expect(messages, [
      {'menuPassthroughEnabled': false},
      {'menuPassthroughEnabled': true},
      {'menuPassthroughEnabled': false},
    ]);
  });

  test('platform exception does not poison an identical retry', () async {
    final messages = <Object?>[];
    var fail = true;
    messenger.setMockDecodedMessageHandler<Object?>(channel, (message) async {
      messages.add(message);
      if (fail) {
        fail = false;
        throw PlatformException(code: 'controller_unavailable');
      }
      return true;
    });

    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);

    expect(messages, [
      {'menuPassthroughEnabled': true},
      {'menuPassthroughEnabled': true},
    ]);
  });

  test('non-tvOS calls never reach the platform channel', () async {
    final messages = <Object?>[];
    messenger.setMockDecodedMessageHandler<Object?>(channel, (message) async {
      messages.add(message);
      return true;
    });
    TvDetectionService.debugSetAppleTVOverride(false);

    await TvosSystemNavigationService.setMenuPassthroughEnabled(true);
    await TvosSystemNavigationService.setMenuPassthroughEnabled(false);

    expect(messages, isEmpty);
  });
}
