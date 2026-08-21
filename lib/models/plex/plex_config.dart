import 'package:package_info_plus/package_info_plus.dart';

import '../../utils/device_identity.dart';

class PlexConfig {
  final String baseUrl;
  final String? token;
  final String clientIdentifier;
  final String product;
  final String version;
  final String platform;
  final String? device;

  /// Friendly device name — Plex dashboards and Tautulli show it as the
  /// session's "Player".
  final String? deviceName;
  final bool acceptJson;
  final String? machineIdentifier;
  final String? languageCode;

  PlexConfig({
    required this.baseUrl,
    this.token,
    required this.clientIdentifier,
    required this.product,
    required this.version,
    this.platform = 'Flutter',
    this.device,
    this.deviceName,
    this.acceptJson = true,
    this.machineIdentifier,
    this.languageCode,
  });

  static Future<PlexConfig> create({
    required String baseUrl,
    String? token,
    required String clientIdentifier,
    String? product,
    String? platform,
    String? device,
    bool acceptJson = true,
    String? machineIdentifier,
    String? languageCode,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final identity = await DeviceIdentityService.resolve();
    return PlexConfig(
      baseUrl: baseUrl,
      token: token,
      clientIdentifier: clientIdentifier,
      product: product ?? 'Plezy',
      version: packageInfo.version,
      platform: platform ?? identity.platform,
      device: device ?? sanitizeHeaderValue(identity.deviceModel),
      deviceName: sanitizeHeaderValue(identity.deviceName),
      acceptJson: acceptJson,
      machineIdentifier: machineIdentifier,
      languageCode: languageCode,
    );
  }

  Map<String, String> get headers {
    final headers = {
      'X-Plex-Client-Identifier': clientIdentifier,
      'X-Plex-Product': product,
      'X-Plex-Version': version,
      'X-Plex-Platform': platform,
      'X-Plex-Client-Profile-Name': 'Generic',
      'X-Plex-Device': ?device,
      'X-Plex-Device-Name': ?deviceName,
      if (acceptJson) 'Accept': 'application/json',
      'Accept-Charset': 'utf-8',
      'Accept-Language': ?_normalizedLanguageCode,
      'X-Plex-Language': ?_normalizedLanguageCode,
    };

    if (token != null) {
      headers['X-Plex-Token'] = token!;
    }

    return headers;
  }

  String? get _normalizedLanguageCode {
    final value = languageCode?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  PlexConfig copyWith({
    String? baseUrl,
    String? token,
    String? clientIdentifier,
    String? product,
    String? version,
    String? platform,
    String? device,
    String? deviceName,
    bool? acceptJson,
    String? machineIdentifier,
    String? languageCode,
  }) {
    return PlexConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      clientIdentifier: clientIdentifier ?? this.clientIdentifier,
      product: product ?? this.product,
      version: version ?? this.version,
      platform: platform ?? this.platform,
      device: device ?? this.device,
      deviceName: deviceName ?? this.deviceName,
      acceptJson: acceptJson ?? this.acceptJson,
      machineIdentifier: machineIdentifier ?? this.machineIdentifier,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
