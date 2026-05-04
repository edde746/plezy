import 'package:json_annotation/json_annotation.dart';

import '../utils/json_utils.dart';
import 'mixins/multi_server_fields.dart';

part 'livetv_channel.g.dart';

Object? _readChannelKey(Map json, String _) =>
    json['key'] as String? ??
    json['ratingKey'] as String? ??
    json['identifier'] as String? ??
    json['id'] as String? ??
    json['channelIdentifier'] as String? ??
    '';

Object? _readChannelIdentifier(Map json, String _) =>
    json['identifier'] as String? ?? json['id'] as String? ?? json['channelIdentifier'] as String?;

Object? _readChannelTitle(Map json, String _) => json['title'] as String? ?? json['callSign'] as String?;

Object? _readChannelNumber(Map json, String _) =>
    json['number'] as String? ??
    json['channelNumber'] as String? ??
    json['channelVcn']?.toString() ??
    json['vcn']?.toString();

Object? _readFavoriteChannelId(Map json, String _) => json['id'] as String? ?? json['key'] as String? ?? '';

String favoriteChannelKey(String source, String id) => '$source\u0000$id';

String liveTvChannelScopeKey(LiveTvChannel channel) =>
    '${channel.serverId ?? ''}\u0000${channel.liveDvrKey ?? ''}\u0000${channel.key}';

@JsonSerializable(createToJson: false)
class LiveTvChannel with MultiServerFields {
  @JsonKey(readValue: _readChannelKey)
  final String key;
  @JsonKey(readValue: _readChannelIdentifier)
  final String? identifier;
  final String? callSign;
  @JsonKey(readValue: _readChannelTitle)
  final String? title;
  final String? thumb;
  final String? art;
  @JsonKey(readValue: _readChannelNumber)
  final String? number;
  @JsonKey(fromJson: flexibleBool)
  final bool hd;
  final String? lineup;
  final String? slug;
  @JsonKey(fromJson: flexibleBool)
  final bool? drm;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverId;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? serverName;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? liveDvrKey;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? favoriteSource;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? favoriteStoreKey;

  LiveTvChannel({
    required this.key,
    this.identifier,
    this.callSign,
    this.title,
    this.thumb,
    this.art,
    this.number,
    this.hd = false,
    this.lineup,
    this.slug,
    this.drm,
    this.serverId,
    this.serverName,
    this.liveDvrKey,
    this.favoriteSource,
    this.favoriteStoreKey,
  });

  factory LiveTvChannel.fromJson(Map<String, dynamic> json) => _$LiveTvChannelFromJson(json);

  LiveTvChannel copyWith({
    String? serverId,
    String? serverName,
    String? liveDvrKey,
    String? favoriteSource,
    String? favoriteStoreKey,
  }) {
    return LiveTvChannel(
      key: key,
      identifier: identifier,
      callSign: callSign,
      title: title,
      thumb: thumb,
      art: art,
      number: number,
      hd: hd,
      lineup: lineup,
      slug: slug,
      drm: drm,
      serverId: serverId ?? this.serverId,
      serverName: serverName ?? this.serverName,
      liveDvrKey: liveDvrKey ?? this.liveDvrKey,
      favoriteSource: favoriteSource ?? this.favoriteSource,
      favoriteStoreKey: favoriteStoreKey ?? this.favoriteStoreKey,
    );
  }

  /// Display name: prefer callSign, fallback to title
  String get displayName => callSign ?? title ?? 'Channel $number';
}

/// A channel entry in the Plex cloud favorites list.
/// Stored at `https://epg.provider.plex.tv/settings/favoriteChannels`.
@JsonSerializable(createToJson: false)
class FavoriteChannel {
  @JsonKey(defaultValue: '')
  final String source;
  @JsonKey(readValue: _readFavoriteChannelId)
  final String id;
  final String? title;
  final String? thumb;
  final String? vcn;

  FavoriteChannel({required this.source, required this.id, this.title, this.thumb, this.vcn});

  factory FavoriteChannel.fromJson(Map<String, dynamic> json) => _$FavoriteChannelFromJson(json);

  String get stableKey => favoriteChannelKey(source, id);

  Map<String, dynamic> toJson() => {
    'source': source,
    'id': id,
    if (title != null) 'title': title,
    if (thumb != null) 'thumb': thumb,
    if (vcn != null) 'vcn': vcn,
  };

  /// Create from a [LiveTvChannel] and a source URI.
  factory FavoriteChannel.fromLiveTvChannel(LiveTvChannel channel, String source) {
    return FavoriteChannel(
      source: source,
      id: channel.key,
      title: channel.title ?? channel.callSign,
      thumb: channel.thumb,
      vcn: channel.number,
    );
  }
}
