import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:plezy/services/connectivity_probe.dart';
import 'package:plezy/utils/app_logger.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const _unknown = [ConnectivityResult.other];
const _warnMessage = 'Connectivity probe unavailable; assuming online';

/// The shape dbus produces without a system bus: an unawaited Future rejects
/// with [SocketException] in the caller's zone while the awaited call never
/// completes.
Future<List<ConnectivityResult>> _leakAndHang() {
  unawaited(Future<void>.error(const SocketException('no system bus')));
  return Completer<List<ConnectivityResult>>().future;
}

Future<List<ConnectivityResult>> _hang() => Completer<List<ConnectivityResult>>().future;

Future<List<ConnectivityResult>> _throwPlatform() async =>
    throw PlatformException(code: 'error', message: 'NetworkManager::StartListen');

class _FakeConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  _FakeConnectivityPlatform({
    Future<List<ConnectivityResult>> Function()? check,
    Stream<List<ConnectivityResult>>? changes,
  }) : _check = check ?? _hang,
       _changes = changes ?? const Stream.empty();

  final Future<List<ConnectivityResult>> Function() _check;
  final Stream<List<ConnectivityResult>> _changes;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() => _check();

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _changes;
}

Iterable<LogEntry> _probeLogs(Level level) =>
    MemoryLogOutput.getLogs().where((entry) => entry.level == level && entry.message == _warnMessage);

void main() {
  setUp(() {
    ConnectivityProbe.resetForTesting();
    MemoryLogOutput.clearLogs();
  });

  tearDown(() {
    ConnectivityProbe.resetForTesting();
    MemoryLogOutput.clearLogs();
  });

  group('check', () {
    test('leaked SocketException settles to unknown without escaping the caller zone', () {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(check: _leakAndHang);

      fakeAsync((async) {
        List<ConnectivityResult>? result;
        ConnectivityProbe.check(timeout: const Duration(seconds: 3)).then((value) => result = value);

        async.flushMicrotasks();
        expect(result, _unknown, reason: 'the leaked error settles the probe before the timeout');
        async.elapse(const Duration(seconds: 3));
        expect(result, _unknown);
      });

      expect(_probeLogs(Level.warning).single.error, contains('no system bus'));
    });

    test('a hung platform resolves to unknown at the timeout', () {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(check: _hang);

      fakeAsync((async) {
        List<ConnectivityResult>? result;
        ConnectivityProbe.check(timeout: const Duration(seconds: 3)).then((value) => result = value);

        async.elapse(const Duration(seconds: 2));
        expect(result, isNull);
        async.elapse(const Duration(seconds: 1));
        expect(result, _unknown);
      });
    });

    test('PlatformException resolves to unknown', () async {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(check: _throwPlatform);

      expect(await ConnectivityProbe.check(), _unknown);
      expect(_probeLogs(Level.warning).single.error, contains('NetworkManager::StartListen'));
    });

    test('warns on the first failure only', () async {
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(check: _throwPlatform);

      await ConnectivityProbe.check();
      await ConnectivityProbe.check();
      await ConnectivityProbe.check();

      expect(_probeLogs(Level.warning), hasLength(1));
      expect(_probeLogs(Level.debug), hasLength(2));
    });
  });

  group('changes', () {
    test('a throwing async onListen is contained and later events still reach the consumer', () async {
      // Same shape as connectivity_plus_linux: an `async` function bound to the
      // `void Function()` onListen slot, so its rejected Future has no owner.
      Future<void> startListen() async => throw StateError('org.freedesktop.DBus.Error.ServiceUnknown');
      final plugin = StreamController<List<ConnectivityResult>>.broadcast(onListen: startListen);
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(changes: plugin.stream);

      final received = <List<ConnectivityResult>>[];
      final subscription = ConnectivityProbe.changes.listen(received.add);
      await pumpEventQueue();

      expect(_probeLogs(Level.warning).single.error, contains('ServiceUnknown'));

      plugin.add(const [ConnectivityResult.wifi]);
      await pumpEventQueue();
      expect(received, [
        [ConnectivityResult.wifi],
      ]);

      await subscription.cancel();
      await plugin.close();
    });

    test('plugin stream errors are logged, not forwarded', () async {
      final plugin = StreamController<List<ConnectivityResult>>.broadcast();
      ConnectivityPlatform.instance = _FakeConnectivityPlatform(changes: plugin.stream);

      final received = <List<ConnectivityResult>>[];
      Object? forwarded;
      final subscription = ConnectivityProbe.changes.listen(received.add, onError: (Object e) => forwarded = e);
      await pumpEventQueue();

      plugin.addError(StateError('bus vanished'));
      plugin.add(const [ConnectivityResult.ethernet]);
      await pumpEventQueue();

      expect(forwarded, isNull);
      expect(received, [
        [ConnectivityResult.ethernet],
      ]);
      expect(_probeLogs(Level.warning), hasLength(1));

      await subscription.cancel();
      await plugin.close();
    });
  });
}
