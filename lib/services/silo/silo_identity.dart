import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/app_logger.dart';
import '../../utils/device_identity.dart';
import '../storage_service.dart';
import 'silo_api.dart';

SiloClientIdentity? _cached;

/// Identity headers for Silo requests: app name and version, and a stable
/// per-installation device id (Plezy's client identifier).
Future<SiloClientIdentity> resolveSiloClientIdentity() async {
  final cached = _cached;
  if (cached != null) return cached;
  final storage = await StorageService.getInstance();
  final clientId = await storage.getOrCreateClientIdentifier();
  final device = await DeviceIdentityService.resolve();
  var version = '1.0';
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.trim().isNotEmpty) version = info.version.trim();
  } catch (e) {
    appLogger.w('Silo: package version unavailable', error: e);
  }
  return _cached = SiloClientIdentity(
    appName: 'Plezy',
    appVersion: version,
    deviceId: 'plezy-$clientId',
    deviceName: device.deviceName ?? device.deviceModel ?? device.platform,
    platform: device.platform,
  );
}
