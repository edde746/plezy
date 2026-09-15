import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';

/// The app's single seam in front of `connectivity_plus`.
///
/// The plugin leaks failures past the awaited call and past a listener's
/// `onError`: dbus fires unawaited Futures from `DBusSignalStream._onListen`,
/// and the Linux plugin's `onListen` is an `async` function whose Future the
/// `StreamController` discards. Both surface as uncaught errors in whichever
/// zone made the call. dbus also never completes its connect completer when
/// the socket open fails, so the awaited `checkConnectivity()` hangs forever
/// on hosts without a system bus.
///
/// Concrete shapes seen in the wild:
/// - `dart:io` `SocketException` — no `/var/run/dbus/system_bus_socket`
///   (containers, minimal images);
/// - `DBusServiceUnknownException` (`org.freedesktop.DBus.Error.ServiceUnknown`)
///   — bus present but NetworkManager absent (systemd-networkd, iwd);
/// - `PlatformException` — Windows `NetworkManager::StartListen`;
/// - `MissingPluginException` — unit tests and unsupported hosts.
///
/// Every failure degrades identically, so the catches are untyped. They also
/// could not be typed: `package:dbus` is a transitive dependency only and
/// `depend_on_referenced_packages` forbids importing it here.
///
/// Unknown connectivity means "assume online": every failure resolves to
/// `[ConnectivityResult.other]`, which is neither `none` nor a metered link.
class ConnectivityProbe {
  ConnectivityProbe._();

  static const List<ConnectivityResult> _unknown = [ConnectivityResult.other];

  static bool _warned = false;
  static StreamController<List<ConnectivityResult>>? _changes;
  static StreamSubscription<List<ConnectivityResult>>? _pluginSubscription;

  /// Current connectivity, or `[ConnectivityResult.other]` when the platform
  /// cannot answer within [timeout] or fails in any way.
  static Future<List<ConnectivityResult>> check({Duration timeout = const Duration(seconds: 3)}) {
    // Created outside the guarded zone so callers' continuations run in their own zone.
    final completer = Completer<List<ConnectivityResult>>();
    void settle(List<ConnectivityResult> results) {
      if (!completer.isCompleted) completer.complete(results);
    }

    runZonedGuarded(
      () async {
        try {
          settle(await Connectivity().checkConnectivity().timeout(timeout, onTimeout: () => _unknown));
        } catch (e, st) {
          _warnOnce(e, st);
          settle(_unknown);
        }
      },
      (e, st) {
        _warnOnce(e, st);
        settle(_unknown);
      },
    );
    return completer.future;
  }

  /// Connectivity changes, shared by every consumer. The plugin subscription
  /// lives inside a guarded zone regardless of which consumer subscribes
  /// first; failures are logged and never forwarded.
  static Stream<List<ConnectivityResult>> get changes => (_changes ??= _createChanges()).stream;

  static StreamController<List<ConnectivityResult>> _createChanges() {
    late final StreamController<List<ConnectivityResult>> controller;
    controller = StreamController<List<ConnectivityResult>>.broadcast(
      onListen: () => runZonedGuarded(() {
        _pluginSubscription = Connectivity().onConnectivityChanged.listen(controller.add, onError: _warnOnce);
      }, _warnOnce),
      onCancel: () => runZonedGuarded(() {
        final subscription = _pluginSubscription;
        _pluginSubscription = null;
        // The plugin's async onCancel closes its bus client; a dead bus throws here too.
        unawaited(subscription?.cancel());
      }, _warnOnce),
    );
    return controller;
  }

  static void _warnOnce(Object error, StackTrace stackTrace) {
    if (_warned) {
      appLogger.d('Connectivity probe unavailable; assuming online', error: error, stackTrace: stackTrace);
      return;
    }
    _warned = true;
    appLogger.w('Connectivity probe unavailable; assuming online', error: error, stackTrace: stackTrace);
  }

  @visibleForTesting
  static void resetForTesting() {
    _warned = false;
    unawaited(_pluginSubscription?.cancel());
    _pluginSubscription = null;
    unawaited(_changes?.close());
    _changes = null;
  }
}
