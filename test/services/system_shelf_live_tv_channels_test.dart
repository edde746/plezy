import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/services/system_shelf_live_tv_channels.dart';

void main() {
  group('SystemShelfLiveTvChannels', () {
    test('favorites lead then channel number', () {
      final a = LiveTvChannel(key: 'a', title: 'Alpha', number: '20', serverId: 's1');
      final b = LiveTvChannel(key: 'b', title: 'Beta', number: '5', serverId: 's1');
      final c = LiveTvChannel(key: 'c', title: 'Fav', number: '99', serverId: 's1');

      final selected = SystemShelfLiveTvChannels.select(
        [a, b, c],
        favoriteScopeKeys: {liveTvChannelScopeKey(c)},
      );

      expect(selected.map((channel) => channel.key), ['c', 'b', 'a']);
    });

    test('dedupes scoped channel keys', () {
      final one = LiveTvChannel(key: '1', title: 'One', number: '1', serverId: 's1', liveDvrKey: 'dvr');
      final dup = LiveTvChannel(key: '1', title: 'One Dup', number: '1', serverId: 's1', liveDvrKey: 'dvr');

      final selected = SystemShelfLiveTvChannels.select([one, dup]);
      expect(selected, hasLength(1));
      expect(selected.single.title, 'One');
    });
  });
}
