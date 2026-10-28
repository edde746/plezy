import 'package:battery_plus/battery_plus.dart';

/// Reads whether the device is connected to external power.
///
/// `null` means the platform cannot report a reliable battery state. Motion
/// processing uses that as unknown and does not block playback on platforms
/// such as TV builds that do not expose the battery plugin.
abstract final class PowerSourceService {
  static final Battery _battery = Battery();

  static Future<bool?> isConnected() async {
    try {
      return _toExternalPower(await _battery.batteryState);
    } on Object {
      return null;
    }
  }

  static Stream<bool?> get changes => _battery.onBatteryStateChanged.map(_toExternalPower).distinct();

  static bool? _toExternalPower(BatteryState state) => switch (state) {
    BatteryState.full || BatteryState.charging || BatteryState.connectedNotCharging => true,
    BatteryState.discharging => false,
    BatteryState.unknown => null,
  };
}
