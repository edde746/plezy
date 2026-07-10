import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'app_logger.dart';
import 'platform_detector.dart';

/// What this install should call itself when talking to media servers and
/// companion peers: a real platform name, the hardware model, and the
/// user-facing device name (Plex dashboards show it as the "Player";
/// Jellyfin as the "Device").
class DeviceIdentity {
  /// 'Android' | 'iOS' | 'tvOS' | 'macOS' | 'Windows' | 'Linux', falling back
  /// to [Platform.operatingSystem] when detection fails.
  final String platform;

  /// Hardware model for `X-Plex-Device`, e.g. 'AFTKM' (Fire TV), 'iPhone',
  /// 'Apple TV'. Null when unresolvable.
  final String? deviceModel;

  /// Friendly, usually user-assigned name (Settings > About > Device name on
  /// Android, computer name on desktop). Null when unresolvable — callers
  /// pick their own fallback. May contain characters that are not valid in
  /// HTTP headers; pass through [sanitizeHeaderValue] before sending.
  final String? deviceName;

  final bool isTv;

  const DeviceIdentity({required this.platform, this.deviceModel, this.deviceName, this.isTv = false});
}

/// Resolves the device identity once per process and memoizes it. Never
/// throws — platform-channel failures (tests, exotic platforms) degrade to
/// [Platform.operatingSystem] with null name/model.
class DeviceIdentityService {
  DeviceIdentityService._();

  static Future<DeviceIdentity>? _cached;

  static Future<DeviceIdentity> resolve() => _cached ??= _resolve();

  @visibleForTesting
  static void debugOverride(DeviceIdentity? identity) {
    _cached = identity == null ? null : Future.value(identity);
  }

  static Future<DeviceIdentity> _resolve() async {
    final deviceInfo = DeviceInfoPlugin();
    final isTv = TvDetectionService.isTVSync();

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final assignedName = await TvDetectionService.getAndroidDeviceName();
        return DeviceIdentity(
          platform: 'Android',
          deviceModel: androidInfo.model,
          deviceName: assignedName ?? '${androidInfo.brand} ${androidInfo.model}',
          isTv: isTv,
        );
      }
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        if (TvDetectionService.isAppleTVSync()) {
          return DeviceIdentity(platform: 'tvOS', deviceModel: 'Apple TV', deviceName: iosInfo.name, isTv: true);
        }
        return DeviceIdentity(platform: 'iOS', deviceModel: iosInfo.model, deviceName: iosInfo.name, isTv: isTv);
      }
      if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return DeviceIdentity(
          platform: 'macOS',
          deviceModel: macInfo.model,
          deviceName: macInfo.computerName,
          isTv: isTv,
        );
      }
      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return DeviceIdentity(
          platform: 'Windows',
          deviceModel: 'Windows',
          deviceName: windowsInfo.computerName,
          isTv: isTv,
        );
      }
      if (Platform.isLinux) {
        final host = Platform.localHostname.trim();
        final name = (host.isNotEmpty && host != 'localhost') ? host : (await deviceInfo.linuxInfo).name;
        return DeviceIdentity(platform: 'Linux', deviceModel: 'Linux', deviceName: name, isTv: isTv);
      }
    } catch (e) {
      appLogger.w('DeviceIdentity: failed to resolve device info', error: e);
    }

    return DeviceIdentity(platform: Platform.operatingSystem, isTv: isTv);
  }
}

/// Makes a free-form device name safe to send as an HTTP header value:
/// drops CR/LF and any code unit above 0xFF (dart:io's HttpHeaders throws a
/// FormatException on non-latin-1 — an emoji in an iPhone name would
/// otherwise kill every request), trims, and returns null when nothing
/// usable remains.
String? sanitizeHeaderValue(String? value) {
  if (value == null) return null;
  final filtered = String.fromCharCodes(value.codeUnits.where((unit) => unit != 0x0D && unit != 0x0A && unit <= 0xFF));
  final trimmed = filtered.trim();
  return trimmed.isEmpty ? null : trimmed;
}
