import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/hotkey_model.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';
import 'package:plezy/utils/platform_detector.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

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

  group('SettingsService keyboard shortcut defaults', () {
    test('includes Ctrl+S screenshot shortcut', () {
      expect(SettingsService.defaultKeyboardShortcuts()['screenshot'], 'Ctrl+S');

      final hotkey = SettingsService.defaultKeyboardHotkeys()['screenshot'];
      expect(hotkey, isNotNull);
      expect(hotkey!.key, PhysicalKeyboardKey.keyS);
      expect(hotkey.modifiers, [HotKeyModifier.control]);
    });
  });

  group('SettingsService TV card defaults', () {
    test('full card layout starts disabled', () async {
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.tvFullCardLayout), isFalse);
    });
  });

  group('SettingsService episode action', () {
    test('defaults to play and resets to play', () async {
      final settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.episodeAction), EpisodeAction.play);

      await settings.write(SettingsService.episodeAction, EpisodeAction.details);
      expect(settings.read(SettingsService.episodeAction), EpisodeAction.details);

      await settings.resetAllSettings();
      expect(settings.read(SettingsService.episodeAction), EpisodeAction.play);
    });
  });

  group('SettingsService platform gates', () {
    test('audio passthrough stays available on desktop but not Apple TV', () {
      expect(PlatformDetector.supportsAudioPassthrough(), isTrue);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(PlatformDetector.supportsAudioPassthrough(), isFalse);
    });

    test('forces external player off on Apple TV even when stored enabled', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.useExternalPlayer, true);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(settings.read(SettingsService.useExternalPlayer), isFalse);
    });

    test('forces auto PiP off on Apple TV even when stored enabled', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.autoPip, true);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(settings.read(SettingsService.autoPip), isFalse);
    });
  });

  group('SettingsService companion remote prefs', () {
    test('last manual host address trims whitespace and drops blanks', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.companionRemoteLastHostAddress, '  192.168.1.10:48632  ');
      expect(settings.read(SettingsService.companionRemoteLastHostAddress), '192.168.1.10:48632');

      await settings.write(SettingsService.companionRemoteLastHostAddress, '   ');
      expect(settings.read(SettingsService.companionRemoteLastHostAddress), isNull);
    });

    test('resetAllSettings clears the last manual host address', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.companionRemoteLastHostAddress, '192.168.1.10:48632');
      expect(settings.read(SettingsService.companionRemoteLastHostAddress), isNotNull);

      await settings.resetAllSettings();

      expect(settings.read(SettingsService.companionRemoteLastHostAddress), isNull);
    });
  });

  group('SettingsService listenables', () {
    test('refreshListenables updates active prefs outside the resettable surface', () async {
      final settings = await SettingsService.getInstance();
      final crashReporting = settings.listenable(SettingsService.crashReporting);

      expect(crashReporting.value, isTrue);

      await settings.prefs.setBool(SettingsService.crashReporting.key, false);
      expect(crashReporting.value, isTrue);

      settings.refreshListenables();

      expect(crashReporting.value, isFalse);
    });

    test('resetAllSettings refreshes active dynamic tracker prefs', () async {
      final settings = await SettingsService.getInstance();
      final modePref = SettingsService.trackerFilterModePref(TrackerService.trakt);
      final idsPref = SettingsService.trackerFilterIdsPref(TrackerService.trakt);

      await settings.write(modePref, TrackerLibraryFilterMode.whitelist);
      await settings.write(idsPref, ['library-1']);
      final mode = settings.listenable(modePref);
      final ids = settings.listenable(idsPref);

      expect(mode.value, TrackerLibraryFilterMode.whitelist);
      expect(ids.value, ['library-1']);

      await settings.resetAllSettings();

      expect(mode.value, TrackerLibraryFilterMode.blacklist);
      expect(ids.value, isEmpty);
    });

    test('tracker library filter only allows unknown libraries when no filter is configured', () async {
      final settings = await SettingsService.getInstance();
      final modePref = SettingsService.trackerFilterModePref(TrackerService.trakt);
      final idsPref = SettingsService.trackerFilterIdsPref(TrackerService.trakt);

      expect(settings.isLibraryAllowedForTracker(TrackerService.trakt, null), isTrue);

      await settings.write(idsPref, ['server:blocked']);
      expect(settings.isLibraryAllowedForTracker(TrackerService.trakt, null), isFalse);

      await settings.write(modePref, TrackerLibraryFilterMode.whitelist);
      await settings.write(idsPref, ['server:allowed']);
      expect(settings.isLibraryAllowedForTracker(TrackerService.trakt, null), isFalse);
      expect(settings.isLibraryAllowedForTracker(TrackerService.trakt, 'server:allowed'), isTrue);
    });
  });
}
