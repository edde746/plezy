import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../mixins/disposable_change_notifier_mixin.dart';
import '../../utils/app_logger.dart';
import '../supporter/supporter_mode.dart';
import '../supporter/supporter_service.dart';
import 'app_icon_catalog.dart';

/// Why the platform refused an icon change. [code] is the channel error code:
/// `unsupported`, `unknown_icon` or `failed`.
class AppIconException implements Exception {
  const AppIconException(this.code, [this.message]);

  final String code;
  final String? message;

  @override
  String toString() => 'AppIconException($code${message == null ? '' : ': $message'})';
}

/// The home-screen icon over `com.plezy/app_icon`: iOS, iPadOS and tvOS
/// alternate icons, Android launcher aliases. Provided at the root scope
/// because the icon belongs to the device, like the Supporter entitlement it
/// follows.
///
/// The platform persists the choice; this service only mirrors it. A confirmed
/// revocation of the entitlement (a [SupporterService.isUnlocked] true->false
/// transition) puts the default icon back.
class AppIconService extends ChangeNotifier with DisposableChangeNotifierMixin {
  AppIconService({required SupporterService supporter, @visibleForTesting bool? platformHasAlternateIcons})
    : _supporter = supporter,
      _platformHasAlternateIcons = platformHasAlternateIcons ?? _defaultPlatformHasAlternateIcons,
      _wasUnlocked = supporter.isUnlocked {
    supporter.addListener(_onSupporterChanged);
  }

  static const channel = MethodChannel('com.plezy/app_icon');

  /// Alternate icons ship on iOS/iPadOS, tvOS (reported as iOS) and Android,
  /// and only in builds that offer the Supporter perks. The native side still
  /// answers whether this device's launcher can switch.
  static bool get _defaultPlatformHasAlternateIcons =>
      supporterBuildMode != SupporterMode.off && (Platform.isIOS || Platform.isAndroid);

  final SupporterService _supporter;
  final bool _platformHasAlternateIcons;
  bool _wasUnlocked;

  bool _isSupported = false;
  String _currentId = defaultAppIconId;
  Future<void>? _loading;

  /// Whether this device can switch its icon; false until [refresh] completes.
  bool get isSupported => _isSupported;

  /// The id of the icon the home screen shows now.
  String get currentId => _currentId;

  /// Reads support and the current icon from the platform. Concurrent calls
  /// share one platform round trip.
  Future<void> refresh() => _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    if (!_platformHasAlternateIcons) return;
    var supported = false;
    var current = defaultAppIconId;
    try {
      supported = await channel.invokeMethod<bool>('isSupported') ?? false;
      if (supported) current = await channel.invokeMethod<String>('getCurrent') ?? defaultAppIconId;
    } on PlatformException catch (e, stackTrace) {
      appLogger.w('App icon state unavailable', error: e, stackTrace: stackTrace);
      supported = false;
    } on MissingPluginException {
      supported = false;
    }
    if (isDisposed || (supported == _isSupported && current == _currentId)) return;
    _isSupported = supported;
    _currentId = current;
    safeNotifyListeners();
  }

  /// Shows [id] on the home screen. Throws [AppIconException] when the
  /// platform refuses; the current icon is unchanged then.
  Future<void> setIcon(String id) async {
    if (!_isSupported) throw const AppIconException('unsupported');
    try {
      await channel.invokeMethod<void>('setIcon', {'id': id});
    } on PlatformException catch (e) {
      throw AppIconException(e.code, e.message);
    }
    if (isDisposed || _currentId == id) return;
    _currentId = id;
    safeNotifyListeners();
  }

  void _onSupporterChanged() {
    final unlocked = _supporter.isUnlocked;
    final revoked = _wasUnlocked && !unlocked;
    _wasUnlocked = unlocked;
    if (revoked) unawaited(_restoreDefaultIcon());
  }

  Future<void> _restoreDefaultIcon() async {
    await refresh();
    if (isDisposed || !_isSupported || _currentId == defaultAppIconId) return;
    try {
      await setIcon(defaultAppIconId);
    } on AppIconException catch (e, stackTrace) {
      appLogger.w('Could not restore the default app icon after a revocation', error: e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _supporter.removeListener(_onSupporterChanged);
    super.dispose();
  }
}
