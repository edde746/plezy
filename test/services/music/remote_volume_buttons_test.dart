import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/device_adjustment_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_output_controller.dart';
import 'package:plezy/services/music/remote_volume_buttons.dart';

import '../../test_helpers/stub_music_playback_service.dart';

const _speaker = MusicOutput(
  id: 'srv|RINCON_1',
  name: 'Dining Room',
  serverId: 'srv',
  playerId: 'RINCON_1',
  available: true,
);

const _speakerNoVolume = MusicOutput(
  id: 'srv|RINCON_2',
  name: 'Old Speaker',
  serverId: 'srv',
  playerId: 'RINCON_2',
  available: true,
  supportsVolume: false,
);

class _FakeOutputs extends MusicOutputController {
  _FakeOutputs(this._selected) : super(serverManager: MultiServerManager());

  MusicOutput _selected;

  @override
  MusicOutput get selected => _selected;

  void choose(MusicOutput output) {
    _selected = output;
    notifyListeners();
  }

  @override
  Future<void> refresh() async {}
}

/// Stands in for the platform channel, recording what was asked of it.
class _FakeDevice extends DeviceAdjustmentService {
  _FakeDevice() : super(channel: const MethodChannel('test/none'));

  bool watching = false;
  final List<double> pinned = [];

  /// False models iOS before the app has a window: the slider is missing and
  /// the system volume stays wherever it was.
  bool pinWorks = true;
  double current = 0.8;

  @override
  Future<double?> getMediaVolume() async => current;

  @override
  Future<void> startVolumeButtonWatch() async => watching = true;

  @override
  Future<void> stopVolumeButtonWatch() async => watching = false;

  /// iOS quantizes the system volume to sixteenths, so the value that comes
  /// back is not always the one that was asked for — and it arrives through
  /// the same callback a button press does.
  @override
  Future<bool> setMediaVolume(double value) async {
    pinned.add(value);
    if (!pinWorks) return false;
    final quantized = (value * 16).round() / 16 + 0.0625;
    onSystemVolumeChanged?.call(quantized);
    return true;
  }

  /// Push a system volume reading, as the hardware buttons would.
  void press(double value) {
    current = value;
    onSystemVolumeChanged?.call(value);
  }
}

class _FakePlayback extends StubMusicPlaybackService {
  double _volume = 40;
  final List<double> sent = [];

  /// When set, a sent level is not reflected in [volume] — a speaker that has
  /// not reported back yet.
  bool lagging = false;

  @override
  double get volume => _volume;

  @override
  Future<void> setVolume(double value, {bool persist = true}) async {
    sent.add(value);
    if (!lagging) _volume = value;
  }
}

void main() {
  late _FakeDevice device;
  late _FakePlayback playback;

  setUp(() {
    device = _FakeDevice();
    playback = _FakePlayback();
  });

  RemoteVolumeButtons build(MusicOutputController outputs) =>
      RemoteVolumeButtons(outputs: outputs, playback: playback, device: device)..start();

  test('only watches while the buttons cannot reach the output themselves', () async {
    final outputs = _FakeOutputs(MusicOutput.thisDevice);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);

    expect(device.watching, isFalse, reason: 'on the phone the buttons already do the right thing');

    outputs.choose(_speaker);
    await Future<void>.delayed(Duration.zero);
    expect(device.watching, isTrue);

    outputs.choose(MusicOutput.thisDevice);
    await Future<void>.delayed(Duration.zero);
    expect(device.watching, isFalse, reason: 'pinning the system volume is a real side effect; stop when unneeded');
  });

  test('a speaker that cannot be turned down is left alone', () async {
    final outputs = _FakeOutputs(_speakerNoVolume);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);

    expect(device.watching, isFalse);
  });

  test('a press moves the speaker by how far it was pressed, in that direction', () async {
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);

    // Up a step: iOS reports about 1/16 above the pin.
    device.press(RemoteVolumeButtons.pinnedSystemVolume + 0.0625);
    await Future<void>.delayed(Duration.zero);
    expect(playback.volume, closeTo(46.25, 0.01));

    device.press(RemoteVolumeButtons.pinnedSystemVolume - 0.0625);
    await Future<void>.delayed(Duration.zero);
    expect(playback.volume, closeTo(40, 0.01), reason: 'down the same distance returns where it started');
  });

  test('restoring the pin is not read as another press', () async {
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);

    device.press(RemoteVolumeButtons.pinnedSystemVolume + 0.0625);
    await Future<void>.delayed(Duration.zero);

    // One press, one step. The pin restored afterwards comes back through the
    // same callback and — because the device rounds it — does not land on the
    // pinned value, so counting it would make every press run away.
    expect(playback.volume, closeTo(46.25, 0.01));
  });

  test('the speaker never goes past either end', () async {
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);

    for (var i = 0; i < 30; i++) {
      device.press(RemoteVolumeButtons.pinnedSystemVolume + 0.0625);
      await Future<void>.delayed(Duration.zero);
    }
    expect(playback.volume, 100);

    for (var i = 0; i < 40; i++) {
      device.press(RemoteVolumeButtons.pinnedSystemVolume - 0.0625);
      await Future<void>.delayed(Duration.zero);
    }
    expect(playback.volume, 0);
  });

  test('a quick run of presses adds up before the speaker reports back', () async {
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);
    playback.lagging = true;

    for (var i = 0; i < 3; i++) {
      device.press(RemoteVolumeButtons.pinnedSystemVolume + 0.0625);
      await Future<void>.delayed(Duration.zero);
    }

    expect(playback.sent.last, closeTo(58.75, 0.01), reason: 'three steps up from 40, not one step three times');
  });

  test('each press is published with the speaker name and the level sent', () async {
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);
    final seen = <RemoteVolumePress?>[];
    buttons.lastPress.addListener(() => seen.add(buttons.lastPress.value));

    device.press(RemoteVolumeButtons.pinnedSystemVolume - 0.0625);
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1));
    expect(seen.single!.outputName, 'Dining Room');
    expect(seen.single!.level, closeTo(33.75, 0.01));
  });

  test('when the pin cannot be set, a press is measured from where the phone was', () async {
    device.pinWorks = false;
    device.current = 0.8;
    final outputs = _FakeOutputs(_speaker);
    final buttons = build(outputs);
    addTearDown(buttons.dispose);
    await Future<void>.delayed(Duration.zero);

    device.press(0.8625);
    await Future<void>.delayed(Duration.zero);

    expect(playback.volume, closeTo(46.25, 0.01), reason: 'one step, not the 36 points between mid-scale and 0.86');
  });
}
