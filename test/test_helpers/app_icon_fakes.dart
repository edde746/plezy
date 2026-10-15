import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/app_icon/app_icon_catalog.dart';
import 'package:plezy/services/app_icon/app_icon_service.dart';
import 'package:plezy/services/supporter/supporter_mode.dart';
import 'package:plezy/services/supporter/supporter_service.dart';

/// The native side of `com.plezy/app_icon`, as a scoped binary-messenger
/// handler: a launcher that can switch (or not) and remembers its icon.
class FakeAppIconPlatform {
  bool supported = true;
  String current = defaultAppIconId;

  /// Thrown from every call while set.
  PlatformException? failWith;

  /// `isSupported`, `getCurrent` and `setIcon:<id>`, in order.
  final List<String> calls = [];

  TestDefaultBinaryMessenger get _messenger => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void install() => _messenger.setMockMethodCallHandler(AppIconService.channel, _handle);

  void uninstall() => _messenger.setMockMethodCallHandler(AppIconService.channel, null);

  /// Lets fire-and-forget platform round trips finish.
  Future<void> idle() => pumpEventQueue();

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call.method == 'setIcon' ? 'setIcon:${(call.arguments as Map)['id']}' : call.method);
    final failure = failWith;
    if (failure != null) throw failure;
    switch (call.method) {
      case 'isSupported':
        return supported;
      case 'getCurrent':
        return current;
      case 'setIcon':
        current = (call.arguments as Map)['id'] as String;
        return null;
    }
    throw MissingPluginException(call.method);
  }
}

/// A purchasable Supporter entitlement the test turns on and off, the way a
/// purchase or a confirmed refund would.
class ToggleSupporter extends SupporterService {
  ToggleSupporter({required this._unlocked}) : super.forTesting(availability: SupporterAvailability.purchasable);

  bool _unlocked;

  @override
  bool get isUnlocked => _unlocked;

  set unlocked(bool value) {
    _unlocked = value;
    notifyListeners();
  }

  /// A change notification that leaves the entitlement as it was.
  void notifyAgain() => notifyListeners();
}
