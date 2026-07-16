import 'package:json_annotation/json_annotation.dart';

import 'trakt_images.dart';

part 'trakt_cast_entry.g.dart';

@JsonSerializable(createToJson: false)
class TraktPersonImages {
  final List<String>? headshot;

  const TraktPersonImages({this.headshot});

  String? get primaryHeadshot => TraktImages.firstUrl(headshot);

  factory TraktPersonImages.fromJson(Map<String, dynamic> json) => _$TraktPersonImagesFromJson(json);
}

@JsonSerializable(createToJson: false)
class TraktPerson {
  final String? name;
  final TraktPersonImages? images;

  const TraktPerson({this.name, this.images});

  factory TraktPerson.fromJson(Map<String, dynamic> json) => _$TraktPersonFromJson(json);
}

/// One cast credit from `GET /{movies|shows}/{id}/people`.
@JsonSerializable(createToJson: false)
class TraktCastEntry {
  final List<String>? characters;
  final TraktPerson? person;

  const TraktCastEntry({this.characters, this.person});

  factory TraktCastEntry.fromJson(Map<String, dynamic> json) => _$TraktCastEntryFromJson(json);
}
