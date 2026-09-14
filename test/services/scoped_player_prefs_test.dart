import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/player_setting_scope.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/scoped_player_prefs.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  late SettingsService settings;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
  });

  MediaItem episode({String series = 'show-1', String id = 'ep-1', String? library = 'lib-1'}) =>
      testMediaItem(id: id, kind: MediaKind.episode, grandparentId: series, libraryId: library, serverId: 'server-a');

  MediaItem movie({String id = 'movie-1', String? library = 'lib-1', String? serverId = 'server-a'}) =>
      testMediaItem(id: id, libraryId: library, serverId: serverId);

  group('global scope (default)', () {
    test('write updates the global pref and resolve reads it back', () async {
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(), 1.5);

      expect(settings.read(SettingsService.defaultPlaybackSpeed), 1.5);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie(id: 'other')), 1.5);
      expect(settings.read(SettingsService.scopedPlayerPrefValues), isEmpty);
    });
  });

  group('title scope', () {
    setUp(() async {
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
    });

    test('episodes of one show share a value; other titles fall back to global', () async {
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, episode(id: 'ep-1'), 1.25);

      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, episode(id: 'ep-2')), 1.25);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, episode(series: 'show-2')), 1.0);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie()), 1.0);
      // The global default stays untouched.
      expect(settings.read(SettingsService.defaultPlaybackSpeed), 1.0);
    });

    test('a movie keys by its own id', () async {
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-1'), 2.0);

      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-1')), 2.0);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-2')), 1.0);
    });

    test('the same rating key on another server is a different title', () async {
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-1'), 2.0);

      final otherServer = testMediaItem(id: 'movie-1', serverId: 'server-b');
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, otherServer), 1.0);
    });

    test('an item without a server id falls back to the global pref', () async {
      final synthetic = movie(serverId: null);
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, synthetic, 1.75);

      expect(settings.read(SettingsService.defaultPlaybackSpeed), 1.75);
      expect(settings.read(SettingsService.scopedPlayerPrefValues), isEmpty);
    });
  });

  group('library scope', () {
    setUp(() async {
      await settings.write(SettingsService.shaderPresetScope, PlayerSettingScope.library);
    });

    test('items in one library share a preset; other libraries fall back to global', () async {
      await settings.write(SettingsService.globalShaderPreset, 'nvscaler');
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.shaderPreset, episode(library: 'anime'), 'anime4k_fast_modeA');

      expect(
        ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, movie(id: 'other', library: 'anime')),
        'anime4k_fast_modeA',
      );
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.shaderPreset, movie(library: 'live-action')), 'nvscaler');
      expect(settings.read(SettingsService.globalShaderPreset), 'nvscaler');
    });

    test('an item without a library falls back to the global pref', () async {
      // Jellyfin/Emby downloads never get a library stamped.
      final offline = testMediaItem(backend: MediaBackend.jellyfin, id: 'ep-1', serverId: 'server-a');
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.shaderPreset, offline, 'nvscaler');

      expect(settings.read(SettingsService.globalShaderPreset), 'nvscaler');
      expect(settings.read(SettingsService.scopedPlayerPrefValues), isEmpty);
    });
  });

  group('off scope', () {
    test('write is a no-op and resolve returns the stored global', () async {
      await settings.write(SettingsService.defaultPlaybackSpeed, 1.5);
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.off);

      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(), 3.0);

      expect(settings.read(SettingsService.defaultPlaybackSpeed), 1.5);
      expect(settings.read(SettingsService.scopedPlayerPrefValues), isEmpty);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie()), 1.5);
    });
  });

  group('scope switching', () {
    test('entries from another scope are inert and resurrect when switching back', () async {
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(), 2.0);

      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.library);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie()), 1.0);

      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie()), 2.0);
    });
  });

  group('sync offsets', () {
    test('audio and subtitle offsets share one scope but store separately', () async {
      await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.title);
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.audioSyncOffset, episode(), 150);
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.subtitleSyncOffset, episode(), -400);

      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, episode(id: 'ep-2')), 150);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, episode(id: 'ep-2')), -400);
      expect(settings.read(SettingsService.audioSyncOffset), 0);
      expect(settings.read(SettingsService.subtitleSyncOffset), 0);
    });
  });

  group('stored-value hygiene', () {
    test('a corrupt entry falls back to the global pref', () async {
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
      await settings.write(SettingsService.scopedPlayerPrefValues, {
        'playback_speed': {
          'title:server-a:movie-1': {'v': 'not-a-number', 't': 1},
        },
      });

      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-1')), 1.0);
    });

    test('values persist across a service restart', () async {
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(), 1.25);

      // Reset only the cached singletons, NOT SharedPreferences — values survive.
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
      settings = await SettingsService.getInstance();

      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie()), 1.25);
    });

    test('oldest entries are evicted past the per-property cap', () async {
      await settings.write(SettingsService.playbackSpeedScope, PlayerSettingScope.title);
      final seeded = <String, dynamic>{
        for (var i = 0; i < ScopedPlayerPrefs.maxEntriesPerProperty; i++) 'title:server-a:movie-$i': {'v': 2.0, 't': i},
      };
      await settings.write(SettingsService.scopedPlayerPrefValues, {'playback_speed': seeded});

      await ScopedPlayerPrefs.write(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-new'), 3.0);

      final entries = settings.read(SettingsService.scopedPlayerPrefValues)['playback_speed'] as Map;
      expect(entries.length, ScopedPlayerPrefs.maxEntriesPerProperty);
      expect(entries.containsKey('title:server-a:movie-new'), isTrue);
      // The oldest seeded entry (t == 0) was evicted.
      expect(entries.containsKey('title:server-a:movie-0'), isFalse);
      expect(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, movie(id: 'movie-new')), 3.0);
    });
  });
}
