import 'package:json_annotation/json_annotation.dart';

part 'trakt_title_variant.g.dart';

/// One row of `GET /{movies|shows}/{id}/aliases` or
/// `GET /{movies|shows}/{id}/translations/{language}`: a title as some
/// region or language knows it. [country] is Trakt's lowercase ISO 3166-1
/// alpha-2 code; translations also carry [language].
@JsonSerializable(createToJson: false)
class TraktTitleVariant {
  final String? title;
  final String? country;
  final String? language;

  const TraktTitleVariant({this.title, this.country, this.language});

  factory TraktTitleVariant.fromJson(Map<String, dynamic> json) => _$TraktTitleVariantFromJson(json);
}
