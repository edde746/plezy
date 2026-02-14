import 'package:flutter/foundation.dart' show kIsWeb;

/// Service for webOS-specific functionality and feature detection.
///
/// Provides methods to interact with webOS Luna Service Bus APIs
/// and detect TV capabilities.
class WebOSService {
  static WebOSService? _instance;

  WebOSService._();

  static WebOSService get instance {
    _instance ??= WebOSService._();
    return _instance!;
  }

  /// Whether the app is running on webOS.
  bool get isWebOS => kIsWeb && _detectWebOS();

  bool? _webOSCached;

  bool _detectWebOS() {
    if (_webOSCached != null) return _webOSCached!;
    // Detection happens via JS interop in platform_helper_web.dart
    // This is a higher-level check
    _webOSCached = kIsWeb; // On web build, assume webOS for TV build
    return _webOSCached!;
  }

  /// webOS device info (populated on init).
  String? modelName;
  String? sdkVersion;
  String? firmwareVersion;
  String? uhd; // '4K' or null

  /// Initialize webOS service and detect device capabilities.
  Future<void> initialize() async {
    if (!kIsWeb) return;
    // On actual webOS, we'd use JS interop to call:
    // webOS.deviceInfo((info) => ...)
    // For now, set reasonable defaults for TV
  }
}
