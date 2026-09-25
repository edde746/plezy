import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/player_setting_scope.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/player_sync_offsets.dart';
import 'package:plezy/services/scoped_player_prefs.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';

void main() {
  late SettingsService settings;
  late _RecordingPlayer player;
  late PlayerSyncOffsets offsets;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
    player = _RecordingPlayer();
    offsets = PlayerSyncOffsets.of(player);
  });

  MediaItem episode(String id, {String series = 'show-1'}) =>
      testMediaItem(id: id, kind: MediaKind.episode, grandparentId: series, serverId: 'server-a');

  test('a "Don\'t save" offset stays with the episode it was set on (#2449)', () async {
    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.off);
    await offsets.applyFor(episode('ep-1'));
    expect(player.writes, isEmpty, reason: 'a new player already applies no delay');

    // What SyncOffsetControl does when the viewer nudges the subtitles.
    await player.setProperty(PlayerSyncOffsets.subtitleProperty, '0.5');
    offsets.recordApplied(PlayerSyncOffsets.subtitleProperty, 500);

    // The next episode reuses the player, whose sub-delay survives the swap.
    await offsets.applyFor(episode('ep-2'));

    expect(player.writes.last, ('sub-delay', '0.0'));
    expect(offsets.subtitleMs, 0);
  });

  test('a per-show offset carries to the next episode without a rewrite and clears for another title', () async {
    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.title);
    await ScopedPlayerPrefs.write(ScopedPlayerPrefs.subtitleSyncOffset, episode('ep-1'), -400);

    await offsets.applyFor(episode('ep-1'));
    expect(player.writes, [('sub-delay', '-0.4')]);

    await offsets.applyFor(episode('ep-2'));
    expect(player.writes, hasLength(1), reason: 'the player already applies this show\'s offset');
    expect(offsets.subtitleMs, -400);

    await offsets.applyFor(testMediaItem(id: 'movie-1', serverId: 'server-a'));
    expect(player.writes.last, ('sub-delay', '0.0'));
    expect(offsets.subtitleMs, 0);
  });
}

class _RecordingPlayer implements Player {
  final List<(String, String)> writes = [];

  @override
  Future<void> setProperty(String name, String value) async => writes.add((name, value));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
