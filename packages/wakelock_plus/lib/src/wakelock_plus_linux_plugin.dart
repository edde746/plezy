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
    return WakelockPlusLinuxPlugin._internal(
      dbusClient,
      remoteObject,
      appNameGetter,
    );
  }

  WakelockPlusLinuxPlugin._internal(
    this._client,
    this._object,
    this._appNameGetter,
  );

  final DBusClient _client;
  final DBusRemoteObject _object;
  final Future<String> Function()? _appNameGetter;
  DBusObjectPath? _requestHandle;

  Future<String> get _appName =>
      _appNameGetter?.call() ??
      PackageInfo.fromPlatform().then((info) => info.appName);

  @override
  Future<void> toggle({required bool enable}) async {
    if (enable) {
      final appName = await _appName;
      _requestHandle = await _object
          .callMethod(
            'org.freedesktop.portal.Inhibit',
            'Inhibit',
            [
              const DBusString(''),
              const DBusUint32(8),
              DBusDict.stringVariant({
                'reason': DBusString('$appName: wakelock active'),
              }),
            ],
            replySignature: DBusSignature('o'),
          )
          .then((response) => response.returnValues.single.asObjectPath());
    } else if (_requestHandle != null) {
      final requestObject = DBusRemoteObject(
        _client,
        name: 'org.freedesktop.portal.Desktop',
        path: _requestHandle!,
      );
      await requestObject.callMethod(
        'org.freedesktop.portal.Request',
        'Close',
        [],
        replySignature: DBusSignature.empty,
      );
      _requestHandle = null;
    }
  }

  @override
  Future<bool> get enabled async => _requestHandle != null;
}
