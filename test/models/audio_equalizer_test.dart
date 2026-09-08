import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/audio_equalizer.dart';
import 'package:plezy/mpv/filters/equalizer_filter.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  test('legacy bands become finite doubles without creating absent profiles', () {
    final values = EqualizerSettings.fromJson({
      'global': [0, 2, -30, 99, double.nan, 'invalid'],
      'eac3': 'bad',
    });
    expect(values.profiles.keys, [EqualizerAudioType.global]);
    expect(values.resolve(EqualizerAudioType.global).gains, [0.0, 2.0, -12.0, 12.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);
    expect(() => values.resolve(EqualizerAudioType.global).gains[0] = 3, throwsUnsupportedError);
    expect(EqualizerSettings.fromJson(values.toJson()), values);
  });
  test('codec aliases, stereo downmix, unknown channels classify consistently', () {
    expect(AudioEqualizer.audioType(codec: 'e-ac-3', channels: 6), EqualizerAudioType.eac3);
    expect(AudioEqualizer.audioType(codec: 'eac3', channels: 6, downmix: true), EqualizerAudioType.stereo);
    expect(AudioEqualizer.audioType(codec: 'dts-hd', channels: 8), EqualizerAudioType.dts);
    expect(AudioEqualizer.audioType(codec: 'aac', channels: 2), EqualizerAudioType.stereo);
    expect(AudioEqualizer.audioType(codec: 'flac', channels: 6), EqualizerAudioType.surround);
    expect(AudioEqualizer.audioType(channels: -1), EqualizerAudioType.global);
  });
  test('inheritance preserves dormant custom profiles and the device default', () {
    final global = EqualizerProfile(gains: AudioEqualizer.presetGains[EqualizerPreset.bass]!);
    var values = EqualizerSettings({EqualizerAudioType.global: global});
    expect(values.resolve(EqualizerAudioType.eac3), global);
    values = values.withProfile(EqualizerAudioType.eac3, EqualizerProfile(preampDb: -3));
    values = values.setInheritance(EqualizerAudioType.eac3, true);
    expect(values.resolve(EqualizerAudioType.eac3), global);
    values = values.setInheritance(EqualizerAudioType.eac3, false);
    expect(values.resolve(EqualizerAudioType.eac3).preampDb, -3);
    expect(values.resolve(EqualizerAudioType.global), global);
  });
  test('preamp and Bass are independent of band values', () {
    final filter = buildEqualizerFilter(EqualizerProfile(preampDb: -4, bassDb: 3));
    expect(filter, contains('volume=-4.0dB'));
    expect(filter, contains('equalizer=f=80:t=q:w=0.5:g=3.0'));
    expect('equalizer=f='.allMatches(filter), hasLength(1));
    expect(buildEqualizerFilter(EqualizerProfile.flat), isEmpty);
  });
  test('migrates old independent controls once without overwriting newer values', () async {
    resetSharedPreferencesForTest(
      initialAsync: {
        'audio_equalizer': jsonEncode({
          'global': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          'eac3': [1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        }),
        'audio_equalizer_amp': -2.0,
        'audio_equalizer_bass': 3.0,
      },
    );
    final settings = await SettingsService.getInstance();
    final eq = settings.read(SettingsService.audioEqualizer);
    expect(eq.resolve(EqualizerAudioType.global).preampDb, -2);
    expect(eq.resolve(EqualizerAudioType.global).bassDb, 3);
    expect(eq.resolve(EqualizerAudioType.eac3).gains.first, 1);
    expect(settings.prefs.get('audio_equalizer_amp'), isNull);
    expect(jsonDecode(settings.prefs.getString('audio_equalizer')!)['version'], 1);
  });
}
