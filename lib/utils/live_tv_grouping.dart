import '../models/livetv_channel.dart';
import 'live_tv_matching.dart';

class LiveTvChannelGroup {
  final String key;
  final String label;
  final List<LiveTvChannel> channels;

  const LiveTvChannelGroup({required this.key, required this.label, required this.channels});

  LiveTvChannelGroup copyWith({String? label}) {
    return LiveTvChannelGroup(key: key, label: label ?? this.label, channels: channels);
  }
}

List<LiveTvChannelGroup> groupLiveTvChannelsBySource(List<LiveTvChannel> channels) {
  final order = <String>[];
  final bySource = <String, List<LiveTvChannel>>{};
  final labels = <String, String>{};

  for (final channel in channels) {
    final key = liveTvChannelSourceKey(channel);
    if (!bySource.containsKey(key)) {
      order.add(key);
      bySource[key] = [];
      labels[key] = liveTvChannelSourceLabel(channel);
    }
    bySource[key]!.add(channel);
  }

  final groups = [
    for (final key in order)
      LiveTvChannelGroup(key: key, label: labels[key]!, channels: List.unmodifiable(bySource[key]!)),
  ];

  final labelCounts = <String, int>{};
  for (final group in groups) {
    labelCounts[group.label] = (labelCounts[group.label] ?? 0) + 1;
  }

  return [
    for (final group in groups)
      if ((labelCounts[group.label] ?? 0) > 1) group.copyWith(label: _deduplicatedLabel(group)) else group,
  ];
}

String liveTvChannelSourceKey(LiveTvChannel channel) {
  final serverId = liveTvNonEmpty(channel.serverId) ?? '';
  final providerSource = liveTvNonEmpty(channel.favoriteSource) ?? liveTvNonEmpty(channel.lineup) ?? '';
  final dvrSource = liveTvNonEmpty(channel.liveDvrKey) ?? '';
  return '$serverId\u0000$providerSource\u0000$dvrSource';
}

String liveTvChannelSourceLabel(LiveTvChannel channel) {
  final serverLabel = liveTvNonEmpty(channel.serverName) ?? liveTvNonEmpty(channel.serverId) ?? 'Live TV';
  final sourceTitle = liveTvNonEmpty(channel.liveTvSourceTitle);
  if (sourceTitle == null || sourceTitle == serverLabel) return serverLabel;
  return '$serverLabel - $sourceTitle';
}

String _deduplicatedLabel(LiveTvChannelGroup group) {
  if (group.channels.isEmpty) return group.label;
  final first = group.channels.first;
  final suffixes = [
    liveTvNonEmpty(first.liveTvSourceTitle),
    liveTvNonEmpty(first.liveDvrKey),
    liveTvProviderIdentifierForChannel(first),
  ];
  String? suffix;
  for (final value in suffixes) {
    if (value != null && !group.label.contains(value)) {
      suffix = value;
      break;
    }
  }
  if (suffix == null || group.label.contains(suffix)) return group.label;
  return '${group.label} - $suffix';
}
