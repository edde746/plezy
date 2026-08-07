import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/preroll_service.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  group('prerollsEnabled', () {
    test('returns false before SettingsService is initialized', () {
      expect(prerollsEnabled(), isFalse);
    });

    test('returns false when the pref has never been set', () async {
      await SettingsService.getInstance();
      expect(prerollsEnabled(), isFalse);
    });

    test('returns true once the pref is enabled', () async {
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.playPrerollsBeforeMovies, true);
      expect(prerollsEnabled(), isTrue);
    });
  });

  group('prerollShouldPlayFor', () {
    setUp(() async {
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.playPrerollsBeforeMovies, true);
    });

    test('plays for a fresh movie', () {
      final movie = testMediaItem(kind: MediaKind.movie);
      expect(
        prerollShouldPlayFor(movie, skipPreroll: false, isOffline: false, usePushReplacement: false),
        isTrue,
      );
    });

    test('does not play for an episode', () {
      final episode = testMediaItem(kind: MediaKind.episode);
      expect(
        prerollShouldPlayFor(episode, skipPreroll: false, isOffline: false, usePushReplacement: false),
        isFalse,
      );
    });

    test('does not play for a movie already in progress', () {
      final inProgress = testMediaItem(kind: MediaKind.movie, durationMs: 100000, viewOffsetMs: 5000);
      expect(
        prerollShouldPlayFor(inProgress, skipPreroll: false, isOffline: false, usePushReplacement: false),
        isFalse,
      );
    });

    test('does not play when offline', () {
      final movie = testMediaItem(kind: MediaKind.movie);
      expect(
        prerollShouldPlayFor(movie, skipPreroll: false, isOffline: true, usePushReplacement: false),
        isFalse,
      );
    });

    test('does not play when the preroll flag itself requests skipping it', () {
      final movie = testMediaItem(kind: MediaKind.movie);
      expect(
        prerollShouldPlayFor(movie, skipPreroll: true, isOffline: false, usePushReplacement: false),
        isFalse,
      );
    });

    test('does not play when the pref is off, regardless of other conditions', () async {
      final svc = await SettingsService.getInstance();
      await svc.write(SettingsService.playPrerollsBeforeMovies, false);
      final movie = testMediaItem(kind: MediaKind.movie);
      expect(
        prerollShouldPlayFor(movie, skipPreroll: false, isOffline: false, usePushReplacement: false),
        isFalse,
      );
    });
  });
}