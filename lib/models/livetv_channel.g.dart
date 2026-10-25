// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livetv_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveTvChannel _$LiveTvChannelFromJson(Map<String, dynamic> json) =>
    LiveTvChannel(
      key: _readChannelKey(json, 'key') as String,
      identifier: _readChannelIdentifier(json, 'identifier') as String?,
      callSign: json['callSign'] as String?,
      title: _readChannelTitle(json, 'title') as String?,
      thumb: json['thumb'] as String?,
      art: json['art'] as String?,
      number: _readChannelNumber(json, 'number') as String?,
      hd: json['hd'] == null ? false : flexibleBool(json['hd']),
      lineup: json['lineup'] as String?,
      slug: json['slug'] as String?,
      drm: flexibleBool(json['drm']),
    );

FavoriteChannel _$FavoriteChannelFromJson(Map<String, dynamic> json) =>
    FavoriteChannel(
      source: json['source'] as String? ?? '',
      id: _readFavoriteChannelId(json, 'id') as String,
      title: json['title'] as String?,
      thumb: json['thumb'] as String?,
      vcn: json['vcn'] as String?,
    );
