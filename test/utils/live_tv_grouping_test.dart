import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/utils/live_tv_grouping.dart';

LiveTvChannel _channel({
  required String key,
  required ServerId serverId,
  required String serverName,
  required String dvrKey,
  required String favoriteSource,
  String? sourceTitle,
}) {
  return LiveTvChannel(
    key: key,
    serverId: serverId,
    serverName: serverName,
    liveDvrKey: dvrKey,
    favoriteSource: favoriteSource,
    liveTvSourceTitle: sourceTitle,
  );
}

void main() {
  test('favorites lead in saved order across sources without duplicate channels', () {
    final a = LiveTvChannel(key: 'same', serverId: 'plex', liveDvrKey: 'one');
    final b = LiveTvChannel(key: 'same', serverId: 'jellyfin');
    final c = LiveTvChannel(key: 'same', serverId: 'emby');
    final d = LiveTvChannel(key: 'other', serverId: 'plex', liveDvrKey: 'one');
    final groups = groupLiveTvGuideChannels(
      [a, b, c, d],
      favorites: [
        c,
        a,
        c,
        LiveTvChannel(key: 'gone'),
      ],
    );
    expect(groups.first.key, liveTvFavoritesGroupKey);
    expect(groups.first.channels, [c, a]);
    expect(groups.skip(1).expand((g) => g.channels), [d, b]);
    expect(groups.expand((g) => g.channels).map(liveTvChannelScopeKey).toSet(), hasLength(4));
  });

  test('no favorites keeps source groups and all favorites leaves just the favorites group', () {
    final channels = [LiveTvChannel(key: 'a', serverId: 'one'), LiveTvChannel(key: 'b', serverId: 'two')];
    final regular = groupLiveTvGuideChannels(channels);
    expect(regular.map((g) => g.key), groupLiveTvChannelsBySource(channels).map((g) => g.key));
    final favorites = groupLiveTvGuideChannels(channels, favorites: channels.reversed.toList());
    expect(favorites, hasLength(1));
    expect(favorites.single.channels, channels.reversed);
  });

  test('groups channels by Live TV source while preserving first source appearance', () {
    final firstHome = _channel(
      key: '101',
      serverId: ServerId('home'),
      serverName: 'Home Plex',
      dvrKey: 'dvr-a',
      favoriteSource: 'server://home/provider-a',
      sourceTitle: 'Seattle OTA',
    );
    final cabin = _channel(
      key: '101',
      serverId: ServerId('cabin'),
      serverName: 'Cabin Plex',
      dvrKey: 'dvr-a',
      favoriteSource: 'server://cabin/provider-b',
      sourceTitle: 'Portland OTA',
    );
    final secondHome = _channel(
      key: '102',
      serverId: ServerId('home'),
      serverName: 'Home Plex',
      dvrKey: 'dvr-a',
      favoriteSource: 'server://home/provider-a',
      sourceTitle: 'Seattle OTA',
    );

    final groups = groupLiveTvChannelsBySource([firstHome, cabin, secondHome]);

    expect(groups.map((group) => group.label), ['Home Plex - Seattle OTA', 'Cabin Plex - Portland OTA']);
    expect(groups.first.channels, [firstHome, secondHome]);
    expect(groups.last.channels, [cabin]);
  });

  test('keeps DVRs on the same server as separate groups', () {
    final channels = [
      _channel(
        key: '101',
        serverId: ServerId('home'),
        serverName: 'Home Plex',
        dvrKey: 'dvr-a',
        favoriteSource: 'server://home/provider-a',
        sourceTitle: 'Seattle OTA',
      ),
      _channel(
        key: '101',
        serverId: ServerId('home'),
        serverName: 'Home Plex',
        dvrKey: 'dvr-b',
        favoriteSource: 'server://home/provider-a',
        sourceTitle: 'Seattle OTA',
      ),
    ];

    final groups = groupLiveTvChannelsBySource(channels);

    expect(groups, hasLength(2));
    expect(groups.map((group) => group.label), ['Home Plex - Seattle OTA - dvr-a', 'Home Plex - Seattle OTA - dvr-b']);
  });
}
