import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wakelock_plus/src/wakelock_plus_linux_plugin.dart';

class MockDBusClient extends Mock implements DBusClient {}

class MockDBusRemoteObject extends Mock implements DBusRemoteObject {}

class FakeDBusSignature extends Fake implements DBusSignature {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeDBusSignature());
    registerFallbackValue(DBusObjectPath('/test/fallback'));
  });

  group('WakelockPlusLinuxPlugin', () {
    late MockDBusClient client;
    late MockDBusRemoteObject portal;
    late WakelockPlusLinuxPlugin plugin;

    const destination = 'org.freedesktop.portal.Desktop';
    const inhibitInterface = 'org.freedesktop.portal.Inhibit';
    const requestInterface = 'org.freedesktop.portal.Request';
    final firstHandle = DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/first');
    final secondHandle = DBusObjectPath('/org/freedesktop/portal/desktop/request/1_1/second');

    setUp(() {
      client = MockDBusClient();
      portal = MockDBusRemoteObject();
      plugin = WakelockPlusLinuxPlugin(client: client, object: portal, appNameGetter: () async => 'TestApp');
    });

    void stubClose(DBusObjectPath handle, {Future<DBusMethodSuccessResponse> Function()? response}) {
      when(
        () => client.callMethod(
          destination: destination,
          path: handle,
          interface: requestInterface,
          name: 'Close',
          values: any(named: 'values'),
          replySignature: DBusSignature.empty,
        ),
      ).thenAnswer((_) => response?.call() ?? Future.value(DBusMethodSuccessResponse([])));
    }

    Future<void> waitForInhibit() => untilCalled(
      () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
    );

    Future<void> waitForClose(DBusObjectPath handle) => untilCalled(
      () => client.callMethod(
        destination: destination,
        path: handle,
        interface: requestInterface,
        name: 'Close',
        values: any(named: 'values'),
        replySignature: DBusSignature.empty,
      ),
    );

    test('starts disabled', () async {
      expect(await plugin.enabled, isFalse);
    });

    test('Inhibit uses the idle flag and application reason', () async {
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) async => DBusMethodSuccessResponse([firstHandle]));

      await plugin.toggle(enable: true);

      final values =
          verify(
                () => portal.callMethod(inhibitInterface, 'Inhibit', captureAny(), replySignature: DBusSignature('o')),
              ).captured.single
              as List<DBusValue>;
      expect(values, hasLength(3));
      expect(values[0], isA<DBusString>());
      expect((values[1] as DBusUint32).value, 8);
      final options = values[2] as DBusDict;
      expect(options.children.containsKey(const DBusString('reason')), isTrue);
      expect(await plugin.enabled, isTrue);
    });

    test('closes an acquisition that finishes after disable', () async {
      final inhibit = Completer<DBusMethodSuccessResponse>();
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) => inhibit.future);
      stubClose(firstHandle);

      final enabling = plugin.toggle(enable: true);
      await waitForInhibit();
      final disabling = plugin.toggle(enable: false);
      inhibit.complete(DBusMethodSuccessResponse([firstHandle]));

      await Future.wait([enabling, disabling]);

      expect(await plugin.enabled, isFalse);
      verify(
        () => client.callMethod(
          destination: destination,
          path: firstHandle,
          interface: requestInterface,
          name: 'Close',
          values: [],
          replySignature: DBusSignature.empty,
        ),
      ).called(1);
    });

    test('disable then enable serializes release before reacquisition', () async {
      var inhibitCalls = 0;
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) async {
        inhibitCalls++;
        return DBusMethodSuccessResponse([inhibitCalls == 1 ? firstHandle : secondHandle]);
      });
      final close = Completer<DBusMethodSuccessResponse>();
      stubClose(firstHandle, response: () => close.future);

      await plugin.toggle(enable: true);
      final disabling = plugin.toggle(enable: false);
      await waitForClose(firstHandle);
      final enabling = plugin.toggle(enable: true);

      await Future<void>.delayed(Duration.zero);
      expect(inhibitCalls, 1, reason: 'reacquisition must wait for Close');

      close.complete(DBusMethodSuccessResponse([]));
      await Future.wait([disabling, enabling]);

      expect(inhibitCalls, 2);
      expect(await plugin.enabled, isTrue);
      verify(
        () => client.callMethod(
          destination: destination,
          path: firstHandle,
          interface: requestInterface,
          name: 'Close',
          values: [],
          replySignature: DBusSignature.empty,
        ),
      ).called(1);
    });

    test('redundant enables never replace the live handle', () async {
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) async => DBusMethodSuccessResponse([firstHandle]));

      await Future.wait([plugin.toggle(enable: true), plugin.toggle(enable: true), plugin.toggle(enable: true)]);

      expect(await plugin.enabled, isTrue);
      verify(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).called(1);
    });

    test('retains a handle when Close fails and retries teardown', () async {
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) async => DBusMethodSuccessResponse([firstHandle]));
      var closeAttempts = 0;
      stubClose(
        firstHandle,
        response: () {
          closeAttempts++;
          if (closeAttempts == 1) {
            return Future.error(StateError('close failed'));
          }
          return Future.value(DBusMethodSuccessResponse([]));
        },
      );

      await plugin.toggle(enable: true);
      await expectLater(plugin.toggle(enable: false), throwsA(isA<StateError>()));
      expect(await plugin.enabled, isTrue);

      await plugin.toggle(enable: false);
      expect(closeAttempts, 2);
      expect(await plugin.enabled, isFalse);
    });

    test('continues the serialized tail after Inhibit fails', () async {
      var inhibitAttempts = 0;
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) {
        inhibitAttempts++;
        if (inhibitAttempts == 1) {
          return Future.error(StateError('inhibit failed'));
        }
        return Future.value(DBusMethodSuccessResponse([firstHandle]));
      });

      await expectLater(plugin.toggle(enable: true), throwsA(isA<StateError>()));
      expect(await plugin.enabled, isFalse);

      await plugin.toggle(enable: true);
      expect(inhibitAttempts, 2);
      expect(await plugin.enabled, isTrue);
    });

    test('final disable closes the only live handle exactly once', () async {
      when(
        () => portal.callMethod(inhibitInterface, 'Inhibit', any(), replySignature: any(named: 'replySignature')),
      ).thenAnswer((_) async => DBusMethodSuccessResponse([firstHandle]));
      stubClose(firstHandle);

      await plugin.toggle(enable: true);
      await plugin.toggle(enable: false);
      await plugin.toggle(enable: false);

      expect(await plugin.enabled, isFalse);
      verify(
        () => client.callMethod(
          destination: destination,
          path: firstHandle,
          interface: requestInterface,
          name: 'Close',
          values: [],
          replySignature: DBusSignature.empty,
        ),
      ).called(1);
    });
  });
}
