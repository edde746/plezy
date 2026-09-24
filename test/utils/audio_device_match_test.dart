import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/utils/audio_device_match.dart';

const _devices = [
  AudioDevice(name: 'auto', description: 'Autoselect device'),
  AudioDevice(name: 'wasapi/{0.0.0.111}', description: 'Speakers (Realtek(R) Audio)'),
  AudioDevice(name: 'wasapi/{0.0.0.222}', description: 'LG TV (NVIDIA High Definition Audio)'),
  AudioDevice(name: 'wasapi/{0.0.0.333}', description: 'Headphones (Arctis 7)'),
];

void main() {
  group('matchAudioDevice', () {
    test('matches the human-readable description, which is what a person says', () {
      expect(matchAudioDevice('tv', _devices), _devices[2]);
      expect(matchAudioDevice('headphones', _devices), _devices[3]);
      expect(matchAudioDevice('speakers', _devices), _devices[1]);
    });

    test('matches multi-word and mixed-case queries', () {
      expect(matchAudioDevice('LG TV', _devices), _devices[2]);
      expect(matchAudioDevice('  ArCtIs  ', _devices), _devices[3]);
    });

    test('matches the raw device name too, so an exact id always works', () {
      expect(matchAudioDevice('wasapi/{0.0.0.222}', _devices), _devices[2]);
      expect(matchAudioDevice('auto', _devices), _devices[0]);
    });

    test('returns the first match so repeated calls are stable', () {
      const ambiguous = [
        AudioDevice(name: 'a', description: 'Living Room TV'),
        AudioDevice(name: 'b', description: 'Bedroom TV'),
      ];
      expect(matchAudioDevice('tv', ambiguous), ambiguous[0]);
    });

    test('returns null rather than guessing', () {
      expect(matchAudioDevice('soundbar', _devices), isNull);
      expect(matchAudioDevice('', _devices), isNull);
      expect(matchAudioDevice('   ', _devices), isNull);
      expect(matchAudioDevice('tv', const []), isNull);
    });
  });
}
