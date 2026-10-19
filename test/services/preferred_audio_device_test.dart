import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player.dart';
import 'package:plezy/services/preferred_audio_device.dart';

/// mpv answers a string read of a node property with JSON, which is what the
/// native getProperty bridges hand back.
const _linuxDevices =
    '[{"name":"auto","description":"Autoselect device"},'
    '{"name":"pipewire","description":"Default (pipewire)"},'
    '{"name":"alsa","description":"Default (alsa)"}]';

void main() {
  test('moves a new core onto the remembered output when the core lists it', () async {
    final player = _DeviceListPlayer(deviceList: () async => _linuxDevices);

    await applyPreferredAudioDevice(player, 'alsa');

    expect(player.applied, ['alsa']);
  });

  // mpv does not fall back from a forced audio-device: an unplugged device
  // would leave the core on the null output and end playback.
  test('leaves a new core on automatic selection when the remembered output is gone', () async {
    final player = _DeviceListPlayer(deviceList: () async => _linuxDevices);

    await applyPreferredAudioDevice(player, 'alsa/hw:CARD=DAC,DEV=0');

    expect(player.applied, isEmpty);
  });

  test('an unreadable output list leaves automatic selection without failing player setup', () async {
    final player = _DeviceListPlayer(deviceList: () async => throw StateError('core gone'));

    await applyPreferredAudioDevice(player, 'alsa');

    expect(player.applied, isEmpty);
  });
}

class _DeviceListPlayer implements Player {
  _DeviceListPlayer({required this.deviceList});

  final Future<String?> Function() deviceList;
  final applied = <String>[];

  @override
  Future<String?> getProperty(String name) {
    if (name != 'audio-device-list') throw UnsupportedError(name);
    return deviceList();
  }

  @override
  Future<void> setAudioDevice(AudioDevice device) async => applied.add(device.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
