import '../models/livetv_channel.dart';

/// Picks Live TV channels for the Android Preview Channel row.
///
/// Favorites (when known) lead; remaining channels follow channel number then
/// title. Cross-server duplicates collapse on [liveTvChannelScopeKey].
class SystemShelfLiveTvChannels {
  SystemShelfLiveTvChannels._();

  static const int maxItems = 20;

  static List<LiveTvChannel> select(
    List<LiveTvChannel> channels, {
    Set<String> favoriteScopeKeys = const {},
    int limit = maxItems,
  }) {
    final ranked = List<LiveTvChannel>.of(channels)
      ..sort((a, b) {
        final aFav = favoriteScopeKeys.contains(liveTvChannelScopeKey(a));
        final bFav = favoriteScopeKeys.contains(liveTvChannelScopeKey(b));
        if (aFav != bFav) return aFav ? -1 : 1;
        final byNumber = _channelNumber(a).compareTo(_channelNumber(b));
        if (byNumber != 0) return byNumber;
        final aTitle = (a.title ?? a.callSign ?? a.key).toLowerCase();
        final bTitle = (b.title ?? b.callSign ?? b.key).toLowerCase();
        return aTitle.compareTo(bTitle);
      });

    final seen = <String>{};
    final out = <LiveTvChannel>[];
    for (final channel in ranked) {
      if (!seen.add(liveTvChannelScopeKey(channel))) continue;
      out.add(channel);
      if (out.length >= limit) break;
    }
    return out;
  }

  static double _channelNumber(LiveTvChannel channel) =>
      double.tryParse(channel.number ?? '') ?? 999999;
}
