import 'dart:async';

import 'package:dbus/dbus.dart';
import 'package:meta/meta.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// The Linux implementation of the [WakelockPlusPlatformInterface].
///
/// This class implements the `wakelock_plus` plugin functionality for Linux
/// using the `org.freedesktop.portal.Inhibit` D-Bus API
/// (see https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Inhibit).
class WakelockPlusLinuxPlugin extends WakelockPlusPlatformInterface {
  /// Registers this class as the default instance of [WakelockPlatformInterface].
  static void registerWith() {
    WakelockPlusPlatformInterface.instance = WakelockPlusLinuxPlugin();
  }

  /// Constructs an instance of [WakelockPlusLinuxPlugin].
  factory WakelockPlusLinuxPlugin({
    @visibleForTesting DBusClient? client,
    @visibleForTesting DBusRemoteObject? object,
    @visibleForTesting Future<String> Function()? appNameGetter,
  }) {
    final dbusClient = client ?? DBusClient.session();
    final remoteObject =
        object ??
        DBusRemoteObject(
          dbusClient,
          name: 'org.freedesktop.portal.Desktop',
          path: DBusObjectPath('/org/freedesktop/portal/desktop'),
        );
    return WakelockPlusLinuxPlugin._internal(dbusClient, remoteObject, appNameGetter);
  }

  WakelockPlusLinuxPlugin._internal(this._client, this._object, this._appNameGetter);

  final DBusClient _client;
  final DBusRemoteObject _object;
  final Future<String> Function()? _appNameGetter;
  DBusObjectPath? _requestHandle;
  bool _desiredEnabled = false;
  Future<void> _operationTail = Future<void>.value();

  Future<String> get _appName => _appNameGetter?.call() ?? PackageInfo.fromPlatform().then((info) => info.appName);

  Future<DBusObjectPath> _acquire() async {
    final appName = await _appName;
    if (!_desiredEnabled) {
      throw const _AcquisitionCancelled();
    }

    return _object
        .callMethod('org.freedesktop.portal.Inhibit', 'Inhibit', [
          const DBusString(''),
          const DBusUint32(8),
          DBusDict.stringVariant({'reason': DBusString('$appName: wakelock active')}),
        ], replySignature: DBusSignature('o'))
        .then((response) => response.returnValues.single.asObjectPath());
  }

  Future<void> _close(DBusObjectPath handle) async {
    final requestObject = DBusRemoteObject(_client, name: 'org.freedesktop.portal.Desktop', path: handle);
    await requestObject.callMethod('org.freedesktop.portal.Request', 'Close', [], replySignature: DBusSignature.empty);
  }

  Future<void> _reconcile() async {
    final handle = _requestHandle;
    if (!_desiredEnabled) {
      if (handle == null) {
        return;
      }

      await _close(handle);
      if (identical(_requestHandle, handle)) {
        _requestHandle = null;
      }
      return;
    }

    if (handle != null) {
      return;
    }

    late final DBusObjectPath acquiredHandle;
    try {
      acquiredHandle = await _acquire();
    } on _AcquisitionCancelled {
      return;
    }

    if (_desiredEnabled && _requestHandle == null) {
      _requestHandle = acquiredHandle;
      return;
    }

    try {
      await _close(acquiredHandle);
    } catch (_) {
      // Retain an acquisition whose rollback failed so it remains observable
      // and a later disable can retry closing it.
      _requestHandle ??= acquiredHandle;
      rethrow;
    }
  }

  @override
  Future<void> toggle({required bool enable}) {
    _desiredEnabled = enable;
    final operation = _operationTail.then((_) => _reconcile());
    _operationTail = operation.catchError((_) {});
    return operation;
  }

  @override
  Future<bool> get enabled async => _requestHandle != null;
}

class _AcquisitionCancelled implements Exception {
  const _AcquisitionCancelled();
}
