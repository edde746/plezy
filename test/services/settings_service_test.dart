import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';

void main() {
  group('SettingsService.parseMpvConfigText', () {
    test('parses plain key=value lines', () {
      final out = SettingsService.parseMpvConfigText('hwdec=auto\nvolume=100');
      expect(out, {'hwdec': 'auto', 'volume': '100'});
    });

    test('trims whitespace around key and value', () {
      final out = SettingsService.parseMpvConfigText('  hwdec   =   auto  ');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips blank lines', () {
      final out = SettingsService.parseMpvConfigText('\n\nhwdec=auto\n\n');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips # comment lines (even with leading whitespace)', () {
      final out = SettingsService.parseMpvConfigText('# this is a comment\n  # indented comment\nhwdec=auto');
      expect(out, {'hwdec': 'auto'});
    });

    test('skips lines without an = sign', () {
      final out = SettingsService.parseMpvConfigText('justakey\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('skips lines starting with = (empty key)', () {
      final out = SettingsService.parseMpvConfigText('=value\nfoo=bar');
      expect(out, {'foo': 'bar'});
    });

    test('preserves = signs in value (splits on first only)', () {
      final out = SettingsService.parseMpvConfigText('params=a=1,b=2');
      expect(out, {'params': 'a=1,b=2'});
    });

    test('allows empty value', () {
      final out = SettingsService.parseMpvConfigText('flag=');
      expect(out, {'flag': ''});
    });

    test('later duplicate key overrides earlier', () {
      final out = SettingsService.parseMpvConfigText('k=1\nk=2');
      expect(out, {'k': '2'});
    });

    test('empty input yields empty map', () {
      expect(SettingsService.parseMpvConfigText(''), isEmpty);
    });
  });
}
