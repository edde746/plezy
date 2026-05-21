import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/models/livetv_channel.dart';

void main() {
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

  test('favorite filtering falls back to all channels when no favorites are loaded', () {
    final channels = [LiveTvChannel(key: '101'), LiveTvChannel(key: '102')];

    final filtered = filterLiveTvChannelsForFavorites(
      channels: channels,
      favoritesOnly: true,
      favorites: const [],
      sourceForChannel: (_) => 'server://server-1/provider-a',
    );

    expect(filtered, same(channels));
  });

  test('favorite filtering preserves favorite order and source scope', () {
    final channels = [LiveTvChannel(key: '101'), LiveTvChannel(key: '102'), LiveTvChannel(key: '101')];
    const sourceA = 'server://server-1/provider-a';
    const sourceB = 'server://server-2/provider-a';

    final filtered = filterLiveTvChannelsForFavorites(
      channels: channels,
      favoritesOnly: true,
      favorites: [
        FavoriteChannel(source: sourceB, id: '101'),
        FavoriteChannel(source: sourceA, id: '102'),
      ],
      sourceForChannel: (channel) => identical(channel, channels[2]) ? sourceB : sourceA,
    );

    expect(filtered, [channels[2], channels[1]]);
  });
}
