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
  @JsonKey(name: 'episode_count')
  final int? episodeCount;
  final List<String>? jobs;
  final String? job;
  final TraktPerson? person;

  const TraktCastEntry({this.characters, this.episodeCount, this.jobs, this.job, this.person});

  factory TraktCastEntry.fromJson(Map<String, dynamic> json) => _$TraktCastEntryFromJson(json);
}

/// Cast, guest stars and flattened crew returned by a people endpoint.
///
/// Crew is flattened from Trakt's department-keyed object by [TraktClient].
class TraktPeople {
  final List<TraktCastEntry> cast;
  final List<TraktCastEntry> guestStars;
  final List<TraktCastEntry> crew;

  const TraktPeople({this.cast = const [], this.guestStars = const [], this.crew = const []});
}
