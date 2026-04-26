import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';

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
}
