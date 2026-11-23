import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';

void main() {
  test('a favorite resolves every matching DVR row in lineup order', () {
    const source = 'server://plex/provider';
    final first = LiveTvChannel(key: 'station', serverId: 'plex', liveDvrKey: 'dvr-a');
    final second = LiveTvChannel(key: 'station', serverId: 'plex', liveDvrKey: 'dvr-b');
    final unrelated = LiveTvChannel(key: 'other', serverId: 'plex', liveDvrKey: 'dvr-b');
    expect(
      favoriteLiveTvChannels(
        channels: [first, unrelated, second],
        favoritesLoaded: true,
        favorites: [FavoriteChannel(source: source, id: 'station')],
        sourceForChannel: (_) => source,
      ),
      [first, second],
    );
  });

  test('favoriteChannelKey includes source and id', () {
    expect(favoriteChannelKey('server://a/provider', '101'), isNot(favoriteChannelKey('server://b/provider', '101')));
    expect(
      FavoriteChannel(source: 'server://a/provider', id: '101').stableKey,
      favoriteChannelKey('server://a/provider', '101'),
    );
  });

  test('liveTvChannelScopeKey includes server, dvr, and channel key', () {
    final a = LiveTvChannel(key: '101', serverId: 'server-1', liveDvrKey: 'dvr-a');
    final b = LiveTvChannel(key: '101', serverId: 'server-1', liveDvrKey: 'dvr-b');

    expect(liveTvChannelScopeKey(a), isNot(liveTvChannelScopeKey(b)));
  });

  test('favorite ordering returns no rows until favorites load', () {
    final channels = [LiveTvChannel(key: '101'), LiveTvChannel(key: '102')];

    expect(
      favoriteLiveTvChannels(
        channels: channels,
        favoritesLoaded: false,
        favorites: const [],
        sourceForChannel: (_) => 'server://server-1/provider-a',
      ),
      isEmpty,
    );
    expect(
      favoriteLiveTvChannels(
        channels: channels,
        favoritesLoaded: true,
        favorites: const [],
        sourceForChannel: (_) => 'server://server-1/provider-a',
      ),
      isEmpty,
    );
  });

  test('favorite filtering preserves favorite order and source scope', () {
    final channels = [LiveTvChannel(key: '101'), LiveTvChannel(key: '102'), LiveTvChannel(key: '101')];
    const sourceA = 'server://server-1/provider-a';
    const sourceB = 'server://server-2/provider-a';

    final filtered = favoriteLiveTvChannels(
      channels: channels,
      favoritesLoaded: true,
      favorites: [
        FavoriteChannel(source: sourceB, id: '101'),
        FavoriteChannel(source: sourceA, id: '102'),
      ],
      sourceForChannel: (channel) => identical(channel, channels[2]) ? sourceB : sourceA,
    );

    expect(filtered, [channels[2], channels[1]]);
  });
}
