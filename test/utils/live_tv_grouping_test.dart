import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/models/livetv_channel.dart';
import 'package:vibe_stream/utils/live_tv_grouping.dart';

LiveTvChannel _channel({
  required String key,
  required String serverId,
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
  test('groups channels by Live TV source while preserving first source appearance', () {
    final firstHome = _channel(
      key: '101',
      serverId: 'home',
      serverName: 'Home Plex',
      dvrKey: 'dvr-a',
      favoriteSource: 'server://home/provider-a',
      sourceTitle: 'Seattle OTA',
    );
    final cabin = _channel(
      key: '101',
      serverId: 'cabin',
      serverName: 'Cabin Plex',
      dvrKey: 'dvr-a',
      favoriteSource: 'server://cabin/provider-b',
      sourceTitle: 'Portland OTA',
    );
    final secondHome = _channel(
      key: '102',
      serverId: 'home',
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
        serverId: 'home',
        serverName: 'Home Plex',
        dvrKey: 'dvr-a',
        favoriteSource: 'server://home/provider-a',
        sourceTitle: 'Seattle OTA',
      ),
      _channel(
        key: '101',
        serverId: 'home',
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
