import 'package:json_annotation/json_annotation.dart';

part 'trakt_images.g.dart';

/// Image URL arrays returned by Trakt's `?extended=images`.
///
/// URLs are protocol-less (`walter-r2.trakt.tv/...`) and must be prefixed
/// with `https://`. Trakt requires clients to cache these images; loading
/// them through [PlexImageCacheManager]'s disk cache satisfies that.
@JsonSerializable(createToJson: false)
class TraktImages {
  final List<String>? poster;
  final List<String>? fanart;
  final List<String>? logo;
  final List<String>? banner;
  final List<String>? thumb;

  const TraktImages({this.poster, this.fanart, this.logo, this.banner, this.thumb});

  String? get primaryPoster => firstUrl(poster);

  String? get primaryBackdrop => firstUrl(fanart) ?? firstUrl(thumb);

  /// First URL of a Trakt image array, https-prefixed (Trakt serves
  /// protocol-less URLs). Shared with person headshots.
  static String? firstUrl(List<String>? urls) {
    final url = urls?.firstOrNull;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('http') ? url : 'https://$url';
  }

  factory TraktImages.fromJson(Map<String, dynamic> json) => _$TraktImagesFromJson(json);
}
