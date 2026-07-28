import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import '../utils/platform_detector.dart';

/// Reads the active Apple TV *system* user via a native channel so the app
/// can auto-activate the matching Plezy profile.
///
/// tvOS only. Backed by `TvUserPlugin` (channel `com.plezy/tv_user`). On
/// other platforms every call is a safe no-op (returns null / does nothing).
///
/// See also: [StorageService.getProfileIdForTvosUser] for the persisted
/// Apple-TV-user → Plezy-profile mapping this service resolves against.
class TvosUserProfileService {
  static const MethodChannel _channel = MethodChannel('com.plezy/tv_user');
  static const bool _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

  static final TvosUserProfileService _instance = TvosUserProfileService._internal();
  factory TvosUserProfileService() => _instance;

  TvosUserProfileService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Fired when the Apple TV system user changes while the app is alive.
  /// The argument is the new tvOS user identifier (may be null). On most
  /// tvOS versions a user switch relaunches the app, so the startup path is
  /// the primary trigger; this covers the cases where the process survives
  /// the switch (foreground resume).
  ValueChanged<String?>? onUserChanged;

  bool get _isTvos => Platform.isIOS && (_tvosBuild || PlatformDetector.isAppleTV());

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onUserChanged') {
      final args = call.arguments;
      final userId = args is Map ? args['userId'] as String? : null;
      onUserChanged?.call(userId);
    }
  }

  /// The identifier of the currently-active Apple TV system user, or null if
  /// unavailable (non-tvOS, entitlement missing, or the default user).
  Future<String?> getCurrentUser() async {
    if (!_isTvos) return null;
    try {
      return await _channel.invokeMethod<String>('getCurrentUser');
    } on MissingPluginException catch (e) {
      appLogger.w('tvOS current user unavailable: native channel missing', error: e);
      return null;
    } on PlatformException catch (e) {
      appLogger.w('tvOS current user unavailable: native platform error', error: e);
      return null;
    } catch (e) {
      appLogger.w('Failed to read tvOS current user', error: e);
      return null;
    }
  }
}
