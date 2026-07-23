import 'package:pigeon/pigeon.dart';

/// Message for toggling the wakelock on the platform side.
class ToggleMessage {
  bool? enable;
}

/// Message for reporting the wakelock state from the platform side.
class IsEnabledMessage {
  bool? enabled;
}

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'wakelock_plus_platform_interface',
    objcHeaderOut:
        'ios/wakelock_plus/Sources/wakelock_plus/include/wakelock_plus/messages.g.h',
    objcSourceOut: 'ios/wakelock_plus/Sources/wakelock_plus/messages.g.m',
    objcOptions: ObjcOptions(
      prefix: 'WAKELOCKPLUS',
      headerIncludePath: './include/wakelock_plus/messages.g.h',
    ),
    kotlinOptions: KotlinOptions(
      errorClassName: 'WakelockPlusFlutterError',
    ),
    kotlinOut:
        'android/src/main/kotlin/dev/fluttercommunity/plus/wakelock/WakelockPlusMessages.g.kt',
  ),
)
@HostApi(dartHostTestHandler: 'TestWakelockPlusApi')
abstract class WakelockPlusApi {
  void toggle(ToggleMessage msg);

  IsEnabledMessage isEnabled();
}
