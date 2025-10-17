import 'package:json_annotation/json_annotation.dart';
import 'plex_metadata.dart';
import 'plex_library.dart';

part 'media_container.g.dart';

@JsonSerializable()
class MediaContainer<T> {
  final int? size;
  final int? totalSize;
  final int? offset;
  final String? identifier;
  @JsonKey(name: 'Directory')
  final List<PlexLibrary>? directories;
  @JsonKey(name: 'Metadata')
  final List<PlexMetadata>? metadata;

  MediaContainer({
    this.size,
    this.totalSize,
    this.offset,
    this.identifier,
    this.directories,
    this.metadata,
  });

  factory MediaContainer.fromJson(Map<String, dynamic> json) =>
      _$MediaContainerFromJson(json);

  Map<String, dynamic> toJson() => _$MediaContainerToJson(this);
}
