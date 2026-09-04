import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/audio_quality_preset.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
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
    TvDetectionService.debugSetAutomotiveOverride(null);
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

    test('strips one pair of matching single quotes around the value (#2025)', () {
      final out = SettingsService.parseMpvConfigText("sub-font = 'NetflixSans-Bold'");
      expect(out, {'sub-font': 'NetflixSans-Bold'});
    });

    test('strips one pair of matching double quotes around the value', () {
      final out = SettingsService.parseMpvConfigText('sub-font = "Netflix Sans"');
      expect(out, {'sub-font': 'Netflix Sans'});
    });

    test('strips quotes from numeric values so the property API can parse them', () {
      final out = SettingsService.parseMpvConfigText("sub-pos = '85'\nsub-blur = '0.2'");
      expect(out, {'sub-pos': '85', 'sub-blur': '0.2'});
    });

    test('keeps an unmatched leading quote verbatim', () {
      final out = SettingsService.parseMpvConfigText("k='abc");
      expect(out, {'k': "'abc"});
    });

    test('keeps mismatched quote kinds verbatim', () {
      final out = SettingsService.parseMpvConfigText('k=\'abc"');
      expect(out, {'k': '\'abc"'});
    });

    test('keeps interior quotes', () {
      final out = SettingsService.parseMpvConfigText("k=it's");
      expect(out, {'k': "it's"});
    });

    test('empty quoted value yields empty string', () {
      final out = SettingsService.parseMpvConfigText("flag=''");
      expect(out, {'flag': ''});
    });

    test('strips only the outer quote pair', () {
      final out = SettingsService.parseMpvConfigText('k="\'a\'"');
      expect(out, {'k': "'a'"});
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

  group('SettingsService music quality', () {
    test('defaults to original and persists changes by enum name', () async {
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.original);

      await settings.write(SettingsService.musicQualityPreset, AudioQualityPreset.medium);
      expect(settings.prefs.getString(SettingsService.musicQualityPreset.key), 'medium');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.medium);
    });
  });

  group('SettingsService Plex download quality', () {
    test('defaults to Original, persists, and resets independently of playback quality', () async {
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.defaultDownloadQualityPreset), TranscodeQualityPreset.original);

      await settings.write(SettingsService.defaultDownloadQualityPreset, TranscodeQualityPreset.p720_3mbps);
      expect(settings.prefs.getString(SettingsService.defaultDownloadQualityPreset.key), 'p720_3mbps');
      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.defaultDownloadQualityPreset), TranscodeQualityPreset.p720_3mbps);

      await settings.resetAllSettings();
      expect(settings.read(SettingsService.defaultDownloadQualityPreset), TranscodeQualityPreset.original);
    });
  });

  group('SettingsService cellular quality', () {
    test('defaults to null (follow the general default) and persists by enum name', () async {
      var settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.cellularQualityPreset), isNull);

      await settings.write(SettingsService.cellularQualityPreset, TranscodeQualityPreset.p720_2mbps);
      expect(settings.prefs.getString(SettingsService.cellularQualityPreset.key), 'p720_2mbps');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.cellularQualityPreset), TranscodeQualityPreset.p720_2mbps);
    });

    test('writing null removes the key', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.cellularQualityPreset, TranscodeQualityPreset.p1080_8mbps);
      await settings.write(SettingsService.cellularQualityPreset, null);

      expect(settings.prefs.containsKey(SettingsService.cellularQualityPreset.key), isFalse);
      expect(settings.read(SettingsService.cellularQualityPreset), isNull);
    });

    test('an unrecognized stored value reads as null, not a fallback preset', () async {
      final settings = await SettingsService.getInstance();

      await settings.prefs.setString(SettingsService.cellularQualityPreset.key, 'p9999_removed');

      expect(settings.read(SettingsService.cellularQualityPreset), isNull);
    });
  });

  group('SettingsService app locale', () {
    test('persists script-specific locales by enum name', () async {
      var settings = await SettingsService.getInstance();

      await settings.write(SettingsService.appLocale, AppLocale.zhHant);
      expect(settings.prefs.getString(SettingsService.appLocale.key), 'zhHant');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.appLocale), AppLocale.zhHant);
    });

    test('continues to read legacy language-code values', () async {
      var settings = await SettingsService.getInstance();
      await settings.prefs.setString(SettingsService.appLocale.key, 'zh');

      BaseSharedPreferencesService.resetForTesting();
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(settings.read(SettingsService.appLocale), AppLocale.zh);
    });
  });

  group('SettingsService platform gates', () {
    test('audio passthrough stays available on Apple TV and non-macOS desktop, never macOS', () {
      // Platform.is* is unmockable, so the desktop expectation follows the
      // test host: hidden on a macOS host (#1964), available elsewhere.
      expect(PlatformDetector.supportsAudioPassthrough(), Platform.isMacOS ? isFalse : isTrue);

      TvDetectionService.debugSetAppleTVOverride(true);

      expect(PlatformDetector.supportsAudioPassthrough(), isTrue);
    });

    test('audio passthrough defaults off on a non-Android-TV host and honors explicit writes', () async {
      final settings = await SettingsService.getInstance();
      // The Android-TV-on-ExoPlayer default-on branch depends on Platform.isAndroid,
      // which is false (and unmockable) on the test host, so the default is off here.
      expect(settings.read(SettingsService.audioPassthrough), isFalse);

      await settings.write(SettingsService.audioPassthrough, true);
      expect(settings.read(SettingsService.audioPassthrough), isTrue);

      await settings.write(SettingsService.audioPassthrough, false);
      expect(settings.read(SettingsService.audioPassthrough), isFalse);
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

    test('forces auto PiP off on automotive while honoring the stored value elsewhere', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.autoPip, true);

      // The pref can only surface a stored true where the host itself supports
      // PiP. That term is Platform.isAndroid/isIOS/isMacOS, unmockable and false
      // on the Linux and Windows CI hosts, where the gate pins the pref off no
      // matter what is stored. pictureInPictureAllowed covers the automotive
      // veto itself on every host.
      final hostSupportsPip = PlatformDetector.supportsPictureInPicture();
      expect(settings.read(SettingsService.autoPip), hostSupportsPip ? isTrue : isFalse);

      TvDetectionService.debugSetAutomotiveOverride(true);

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

  group('SettingsService Watch Together relay', () {
    test('typed writes canonicalize valid bases and reject invalid replacement', () async {
      final settings = await SettingsService.getInstance();

      await settings.write(SettingsService.customRelayUrl, '  HTTPS://Relay.Example.Test/path///  ');
      expect(settings.read(SettingsService.customRelayUrl), 'https://relay.example.test/path');

      await expectLater(
        settings.write(SettingsService.customRelayUrl, 'ws://relay.example.test'),
        throwsFormatException,
      );
      expect(settings.read(SettingsService.customRelayUrl), 'https://relay.example.test/path');

      await settings.write(SettingsService.customRelayUrl, '   ');
      expect(settings.read(SettingsService.customRelayUrl), isNull);
    });

    test('startup canonicalizes valid history and removes invalid history', () async {
      resetSharedPreferencesForTest(
        initialAsync: {SettingsService.customRelayUrl.key: '  http://Relay.Example.Test:8080/prefix// '},
      );
      SettingsService.resetForTesting();
      var settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customRelayUrl), 'http://relay.example.test:8080/prefix');

      resetSharedPreferencesForTest(
        initialAsync: {SettingsService.customRelayUrl.key: 'https://relay.example.test/path?wrong=route'},
      );
      SettingsService.resetForTesting();
      settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.customRelayUrl), isNull);
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
  group('BaseSharedPreferencesService initialization generations', () {
    test('a reset-raced initialization resolves to the replacement backend', () async {
      resetSharedPreferencesForTest(initialAsync: const {'generation_marker': 'old'});
      final firstOnInit = Completer<void>();
      final firstStarted = Completer<void>();
      var constructions = 0;

      final raced = BaseSharedPreferencesService.initializeInstance<_GenerationTestPreferences>(() {
        final construction = constructions++;
        return _GenerationTestPreferences(
          construction,
          onInitStarted: construction == 0 ? firstStarted : null,
          onInitGate: construction == 0 ? firstOnInit : null,
        );
      });
      await firstStarted.future;

      resetSharedPreferencesForTest(initialAsync: const {'generation_marker': 'new'});
      final replacement = await BaseSharedPreferencesService.initializeInstance<_GenerationTestPreferences>(
        () => _GenerationTestPreferences(constructions++),
      );
      firstOnInit.complete();
      final recovered = await raced;

      expect(recovered, same(replacement));
      expect(recovered.construction, 1);
      expect(recovered.readString('generation_marker'), 'new');
      expect(constructions, 2);
    });
  });
}

class _GenerationTestPreferences extends BaseSharedPreferencesService {
  _GenerationTestPreferences(this.construction, {this.onInitStarted, this.onInitGate});

  final int construction;
  final Completer<void>? onInitStarted;
  final Completer<void>? onInitGate;

  @override
  Future<void> onInit() async {
    onInitStarted?.complete();
    await onInitGate?.future;
  }
}
