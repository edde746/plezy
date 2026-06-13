// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MediaItem {

@JsonKey(readValue: readStringField, defaultValue: '') String get id;@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) MediaKind get kind; String? get guid; String? get title; String? get titleSort; String? get summary; String? get tagline; String? get originalTitle; String? get studio;@JsonKey(fromJson: flexibleInt) int? get year; String? get originallyAvailableAt; String? get contentRating; String? get parentId; String? get parentTitle; String? get parentThumbPath;@JsonKey(fromJson: flexibleInt) int? get parentIndex;@JsonKey(fromJson: flexibleInt) int? get index; String? get grandparentId; String? get grandparentTitle; String? get grandparentThumbPath; String? get grandparentArtPath; String? get thumbPath; String? get artPath; String? get clearLogoPath; String? get backgroundSquarePath;@JsonKey(fromJson: flexibleInt) int? get durationMs;@JsonKey(fromJson: flexibleInt) int? get viewOffsetMs;@JsonKey(fromJson: flexibleInt) int? get viewCount;@JsonKey(fromJson: flexibleInt) int? get lastViewedAt;@JsonKey(fromJson: flexibleInt) int? get leafCount;@JsonKey(fromJson: flexibleInt) int? get viewedLeafCount;@JsonKey(fromJson: flexibleInt) int? get childCount;@JsonKey(fromJson: flexibleInt) int? get addedAt;@JsonKey(fromJson: flexibleInt) int? get updatedAt;@JsonKey(fromJson: flexibleDouble) double? get rating;@JsonKey(fromJson: flexibleDouble) double? get userRating;@JsonKey(fromJson: _mediaItemStringList) List<String>? get genres;@JsonKey(fromJson: _mediaItemStringList) List<String>? get directors;@JsonKey(fromJson: _mediaItemStringList) List<String>? get writers;@JsonKey(fromJson: _mediaItemStringList) List<String>? get producers;@JsonKey(fromJson: _mediaItemStringList) List<String>? get countries;@JsonKey(fromJson: _mediaItemStringList) List<String>? get collections;@JsonKey(fromJson: _mediaItemStringList) List<String>? get labels;@JsonKey(fromJson: _mediaItemStringList) List<String>? get styles;@JsonKey(fromJson: _mediaItemStringList) List<String>? get moods;@JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? get roles;@JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? get mediaVersions; String? get libraryId; String? get libraryTitle; String? get audioLanguage;/// Jellyfin playlist entry id used by playlist write endpoints.
@JsonKey(fromJson: flexibleInt) Object? get playlistItemId; String? get serverId; String? get serverName;/// Relative folder key (`/library/sections/{id}/folder?parent=…`) for
/// [MediaKind.folder] rows — what [MediaServerClient.fetchFolderChildren]
/// tunes into. Stamped by the folder fetchers, null elsewhere.
 String? get backendFolderKey;@JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? get raw;
/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaItemCopyWith<MediaItem> get copyWith => _$MediaItemCopyWithImpl<MediaItem>(this as MediaItem, _$identity);





@override
String toString() {
  return 'MediaItem(id: $id, kind: $kind, guid: $guid, title: $title, titleSort: $titleSort, summary: $summary, tagline: $tagline, originalTitle: $originalTitle, studio: $studio, year: $year, originallyAvailableAt: $originallyAvailableAt, contentRating: $contentRating, parentId: $parentId, parentTitle: $parentTitle, parentThumbPath: $parentThumbPath, parentIndex: $parentIndex, index: $index, grandparentId: $grandparentId, grandparentTitle: $grandparentTitle, grandparentThumbPath: $grandparentThumbPath, grandparentArtPath: $grandparentArtPath, thumbPath: $thumbPath, artPath: $artPath, clearLogoPath: $clearLogoPath, backgroundSquarePath: $backgroundSquarePath, durationMs: $durationMs, viewOffsetMs: $viewOffsetMs, viewCount: $viewCount, lastViewedAt: $lastViewedAt, leafCount: $leafCount, viewedLeafCount: $viewedLeafCount, childCount: $childCount, addedAt: $addedAt, updatedAt: $updatedAt, rating: $rating, userRating: $userRating, genres: $genres, directors: $directors, writers: $writers, producers: $producers, countries: $countries, collections: $collections, labels: $labels, styles: $styles, moods: $moods, roles: $roles, mediaVersions: $mediaVersions, libraryId: $libraryId, libraryTitle: $libraryTitle, audioLanguage: $audioLanguage, playlistItemId: $playlistItemId, serverId: $serverId, serverName: $serverName, backendFolderKey: $backendFolderKey, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $MediaItemCopyWith<$Res>  {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) _then) = _$MediaItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: readStringField, defaultValue: '') String id,@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) MediaKind kind, String? guid, String? title, String? titleSort, String? summary, String? tagline, String? originalTitle, String? studio,@JsonKey(fromJson: flexibleInt) int? year, String? originallyAvailableAt, String? contentRating, String? parentId, String? parentTitle, String? parentThumbPath,@JsonKey(fromJson: flexibleInt) int? parentIndex,@JsonKey(fromJson: flexibleInt) int? index, String? grandparentId, String? grandparentTitle, String? grandparentThumbPath, String? grandparentArtPath, String? thumbPath, String? artPath, String? clearLogoPath, String? backgroundSquarePath,@JsonKey(fromJson: flexibleInt) int? durationMs,@JsonKey(fromJson: flexibleInt) int? viewOffsetMs,@JsonKey(fromJson: flexibleInt) int? viewCount,@JsonKey(fromJson: flexibleInt) int? lastViewedAt,@JsonKey(fromJson: flexibleInt) int? leafCount,@JsonKey(fromJson: flexibleInt) int? viewedLeafCount,@JsonKey(fromJson: flexibleInt) int? childCount,@JsonKey(fromJson: flexibleInt) int? addedAt,@JsonKey(fromJson: flexibleInt) int? updatedAt,@JsonKey(fromJson: flexibleDouble) double? rating,@JsonKey(fromJson: flexibleDouble) double? userRating,@JsonKey(fromJson: _mediaItemStringList) List<String>? genres,@JsonKey(fromJson: _mediaItemStringList) List<String>? directors,@JsonKey(fromJson: _mediaItemStringList) List<String>? writers,@JsonKey(fromJson: _mediaItemStringList) List<String>? producers,@JsonKey(fromJson: _mediaItemStringList) List<String>? countries,@JsonKey(fromJson: _mediaItemStringList) List<String>? collections,@JsonKey(fromJson: _mediaItemStringList) List<String>? labels,@JsonKey(fromJson: _mediaItemStringList) List<String>? styles,@JsonKey(fromJson: _mediaItemStringList) List<String>? moods,@JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? roles,@JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? mediaVersions, String? libraryId, String? libraryTitle, String? audioLanguage, String? serverId, String? serverName, String? backendFolderKey,@JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? raw
});




}
/// @nodoc
class _$MediaItemCopyWithImpl<$Res>
    implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._self, this._then);

  final MediaItem _self;
  final $Res Function(MediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? guid = freezed,Object? title = freezed,Object? titleSort = freezed,Object? summary = freezed,Object? tagline = freezed,Object? originalTitle = freezed,Object? studio = freezed,Object? year = freezed,Object? originallyAvailableAt = freezed,Object? contentRating = freezed,Object? parentId = freezed,Object? parentTitle = freezed,Object? parentThumbPath = freezed,Object? parentIndex = freezed,Object? index = freezed,Object? grandparentId = freezed,Object? grandparentTitle = freezed,Object? grandparentThumbPath = freezed,Object? grandparentArtPath = freezed,Object? thumbPath = freezed,Object? artPath = freezed,Object? clearLogoPath = freezed,Object? backgroundSquarePath = freezed,Object? durationMs = freezed,Object? viewOffsetMs = freezed,Object? viewCount = freezed,Object? lastViewedAt = freezed,Object? leafCount = freezed,Object? viewedLeafCount = freezed,Object? childCount = freezed,Object? addedAt = freezed,Object? updatedAt = freezed,Object? rating = freezed,Object? userRating = freezed,Object? genres = freezed,Object? directors = freezed,Object? writers = freezed,Object? producers = freezed,Object? countries = freezed,Object? collections = freezed,Object? labels = freezed,Object? styles = freezed,Object? moods = freezed,Object? roles = freezed,Object? mediaVersions = freezed,Object? libraryId = freezed,Object? libraryTitle = freezed,Object? audioLanguage = freezed,Object? serverId = freezed,Object? serverName = freezed,Object? backendFolderKey = freezed,Object? raw = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,guid: freezed == guid ? _self.guid : guid // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,titleSort: freezed == titleSort ? _self.titleSort : titleSort // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,originalTitle: freezed == originalTitle ? _self.originalTitle : originalTitle // ignore: cast_nullable_to_non_nullable
as String?,studio: freezed == studio ? _self.studio : studio // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,originallyAvailableAt: freezed == originallyAvailableAt ? _self.originallyAvailableAt : originallyAvailableAt // ignore: cast_nullable_to_non_nullable
as String?,contentRating: freezed == contentRating ? _self.contentRating : contentRating // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,parentTitle: freezed == parentTitle ? _self.parentTitle : parentTitle // ignore: cast_nullable_to_non_nullable
as String?,parentThumbPath: freezed == parentThumbPath ? _self.parentThumbPath : parentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,parentIndex: freezed == parentIndex ? _self.parentIndex : parentIndex // ignore: cast_nullable_to_non_nullable
as int?,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,grandparentId: freezed == grandparentId ? _self.grandparentId : grandparentId // ignore: cast_nullable_to_non_nullable
as String?,grandparentTitle: freezed == grandparentTitle ? _self.grandparentTitle : grandparentTitle // ignore: cast_nullable_to_non_nullable
as String?,grandparentThumbPath: freezed == grandparentThumbPath ? _self.grandparentThumbPath : grandparentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,grandparentArtPath: freezed == grandparentArtPath ? _self.grandparentArtPath : grandparentArtPath // ignore: cast_nullable_to_non_nullable
as String?,thumbPath: freezed == thumbPath ? _self.thumbPath : thumbPath // ignore: cast_nullable_to_non_nullable
as String?,artPath: freezed == artPath ? _self.artPath : artPath // ignore: cast_nullable_to_non_nullable
as String?,clearLogoPath: freezed == clearLogoPath ? _self.clearLogoPath : clearLogoPath // ignore: cast_nullable_to_non_nullable
as String?,backgroundSquarePath: freezed == backgroundSquarePath ? _self.backgroundSquarePath : backgroundSquarePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,viewOffsetMs: freezed == viewOffsetMs ? _self.viewOffsetMs : viewOffsetMs // ignore: cast_nullable_to_non_nullable
as int?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,lastViewedAt: freezed == lastViewedAt ? _self.lastViewedAt : lastViewedAt // ignore: cast_nullable_to_non_nullable
as int?,leafCount: freezed == leafCount ? _self.leafCount : leafCount // ignore: cast_nullable_to_non_nullable
as int?,viewedLeafCount: freezed == viewedLeafCount ? _self.viewedLeafCount : viewedLeafCount // ignore: cast_nullable_to_non_nullable
as int?,childCount: freezed == childCount ? _self.childCount : childCount // ignore: cast_nullable_to_non_nullable
as int?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as double?,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,directors: freezed == directors ? _self.directors : directors // ignore: cast_nullable_to_non_nullable
as List<String>?,writers: freezed == writers ? _self.writers : writers // ignore: cast_nullable_to_non_nullable
as List<String>?,producers: freezed == producers ? _self.producers : producers // ignore: cast_nullable_to_non_nullable
as List<String>?,countries: freezed == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as List<String>?,collections: freezed == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as List<String>?,labels: freezed == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as List<String>?,styles: freezed == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>?,moods: freezed == moods ? _self.moods : moods // ignore: cast_nullable_to_non_nullable
as List<String>?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<MediaRole>?,mediaVersions: freezed == mediaVersions ? _self.mediaVersions : mediaVersions // ignore: cast_nullable_to_non_nullable
as List<MediaVersion>?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,libraryTitle: freezed == libraryTitle ? _self.libraryTitle : libraryTitle // ignore: cast_nullable_to_non_nullable
as String?,audioLanguage: freezed == audioLanguage ? _self.audioLanguage : audioLanguage // ignore: cast_nullable_to_non_nullable
as String?,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,backendFolderKey: freezed == backendFolderKey ? _self.backendFolderKey : backendFolderKey // ignore: cast_nullable_to_non_nullable
as String?,raw: freezed == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}

}


/// Adds pattern-matching-related methods to [MediaItem].
extension MediaItemPatterns on MediaItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PlexMediaItem value)?  plex,TResult Function( JellyfinMediaItem value)?  jellyfin,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PlexMediaItem() when plex != null:
return plex(_that);case JellyfinMediaItem() when jellyfin != null:
return jellyfin(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PlexMediaItem value)  plex,required TResult Function( JellyfinMediaItem value)  jellyfin,}){
final _that = this;
switch (_that) {
case PlexMediaItem():
return plex(_that);case JellyfinMediaItem():
return jellyfin(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PlexMediaItem value)?  plex,TResult? Function( JellyfinMediaItem value)?  jellyfin,}){
final _that = this;
switch (_that) {
case PlexMediaItem() when plex != null:
return plex(_that);case JellyfinMediaItem() when jellyfin != null:
return jellyfin(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? editionTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? audienceRating, @JsonKey(fromJson: flexibleDouble)  double? userRating,  String? ratingImage,  String? audienceRatingImage, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? subtitleLanguage, @JsonKey(fromJson: flexibleInt)  int? subtitleMode,  String? trailerKey, @JsonKey(fromJson: flexibleInt)  int? playlistItemId, @JsonKey(fromJson: flexibleInt)  int? playQueueItemId,  String? subtype, @JsonKey(fromJson: flexibleInt)  int? extraType,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)?  plex,TResult Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? userRating, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? playlistItemId,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)?  jellyfin,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PlexMediaItem() when plex != null:
return plex(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.editionTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.audienceRating,_that.userRating,_that.ratingImage,_that.audienceRatingImage,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.subtitleLanguage,_that.subtitleMode,_that.trailerKey,_that.playlistItemId,_that.playQueueItemId,_that.subtype,_that.extraType,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);case JellyfinMediaItem() when jellyfin != null:
return jellyfin(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.userRating,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.playlistItemId,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? editionTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? audienceRating, @JsonKey(fromJson: flexibleDouble)  double? userRating,  String? ratingImage,  String? audienceRatingImage, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? subtitleLanguage, @JsonKey(fromJson: flexibleInt)  int? subtitleMode,  String? trailerKey, @JsonKey(fromJson: flexibleInt)  int? playlistItemId, @JsonKey(fromJson: flexibleInt)  int? playQueueItemId,  String? subtype, @JsonKey(fromJson: flexibleInt)  int? extraType,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)  plex,required TResult Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? userRating, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? playlistItemId,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)  jellyfin,}) {final _that = this;
switch (_that) {
case PlexMediaItem():
return plex(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.editionTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.audienceRating,_that.userRating,_that.ratingImage,_that.audienceRatingImage,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.subtitleLanguage,_that.subtitleMode,_that.trailerKey,_that.playlistItemId,_that.playQueueItemId,_that.subtype,_that.extraType,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);case JellyfinMediaItem():
return jellyfin(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.userRating,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.playlistItemId,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? editionTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? audienceRating, @JsonKey(fromJson: flexibleDouble)  double? userRating,  String? ratingImage,  String? audienceRatingImage, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? subtitleLanguage, @JsonKey(fromJson: flexibleInt)  int? subtitleMode,  String? trailerKey, @JsonKey(fromJson: flexibleInt)  int? playlistItemId, @JsonKey(fromJson: flexibleInt)  int? playQueueItemId,  String? subtype, @JsonKey(fromJson: flexibleInt)  int? extraType,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)?  plex,TResult? Function(@JsonKey(readValue: readStringField, defaultValue: '')  String id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson)  MediaKind kind,  String? guid,  String? title,  String? titleSort,  String? summary,  String? tagline,  String? originalTitle,  String? studio, @JsonKey(fromJson: flexibleInt)  int? year,  String? originallyAvailableAt,  String? contentRating,  String? parentId,  String? parentTitle,  String? parentThumbPath, @JsonKey(fromJson: flexibleInt)  int? parentIndex, @JsonKey(fromJson: flexibleInt)  int? index,  String? grandparentId,  String? grandparentTitle,  String? grandparentThumbPath,  String? grandparentArtPath,  String? thumbPath,  String? artPath,  String? clearLogoPath,  String? backgroundSquarePath, @JsonKey(fromJson: flexibleInt)  int? durationMs, @JsonKey(fromJson: flexibleInt)  int? viewOffsetMs, @JsonKey(fromJson: flexibleInt)  int? viewCount, @JsonKey(fromJson: flexibleInt)  int? lastViewedAt, @JsonKey(fromJson: flexibleInt)  int? leafCount, @JsonKey(fromJson: flexibleInt)  int? viewedLeafCount, @JsonKey(fromJson: flexibleInt)  int? childCount, @JsonKey(fromJson: flexibleInt)  int? addedAt, @JsonKey(fromJson: flexibleInt)  int? updatedAt, @JsonKey(fromJson: flexibleDouble)  double? rating, @JsonKey(fromJson: flexibleDouble)  double? userRating, @JsonKey(fromJson: _mediaItemStringList)  List<String>? genres, @JsonKey(fromJson: _mediaItemStringList)  List<String>? directors, @JsonKey(fromJson: _mediaItemStringList)  List<String>? writers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? producers, @JsonKey(fromJson: _mediaItemStringList)  List<String>? countries, @JsonKey(fromJson: _mediaItemStringList)  List<String>? collections, @JsonKey(fromJson: _mediaItemStringList)  List<String>? labels, @JsonKey(fromJson: _mediaItemStringList)  List<String>? styles, @JsonKey(fromJson: _mediaItemStringList)  List<String>? moods, @JsonKey(fromJson: _mediaItemRolesFromJson)  List<MediaRole>? roles, @JsonKey(fromJson: _mediaItemVersionsFromJson)  List<MediaVersion>? mediaVersions,  String? libraryId,  String? libraryTitle,  String? audioLanguage,  String? playlistItemId,  String? serverId,  String? serverName,  String? backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson)  Map<String, Object?>? raw)?  jellyfin,}) {final _that = this;
switch (_that) {
case PlexMediaItem() when plex != null:
return plex(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.editionTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.audienceRating,_that.userRating,_that.ratingImage,_that.audienceRatingImage,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.subtitleLanguage,_that.subtitleMode,_that.trailerKey,_that.playlistItemId,_that.playQueueItemId,_that.subtype,_that.extraType,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);case JellyfinMediaItem() when jellyfin != null:
return jellyfin(_that.id,_that.kind,_that.guid,_that.title,_that.titleSort,_that.summary,_that.tagline,_that.originalTitle,_that.studio,_that.year,_that.originallyAvailableAt,_that.contentRating,_that.parentId,_that.parentTitle,_that.parentThumbPath,_that.parentIndex,_that.index,_that.grandparentId,_that.grandparentTitle,_that.grandparentThumbPath,_that.grandparentArtPath,_that.thumbPath,_that.artPath,_that.clearLogoPath,_that.backgroundSquarePath,_that.durationMs,_that.viewOffsetMs,_that.viewCount,_that.lastViewedAt,_that.leafCount,_that.viewedLeafCount,_that.childCount,_that.addedAt,_that.updatedAt,_that.rating,_that.userRating,_that.genres,_that.directors,_that.writers,_that.producers,_that.countries,_that.collections,_that.labels,_that.styles,_that.moods,_that.roles,_that.mediaVersions,_that.libraryId,_that.libraryTitle,_that.audioLanguage,_that.playlistItemId,_that.serverId,_that.serverName,_that.backendFolderKey,_that.raw);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PlexMediaItem extends MediaItem {
  const PlexMediaItem({@JsonKey(readValue: readStringField, defaultValue: '') required this.id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) required this.kind, this.guid, this.title, this.titleSort, this.summary, this.tagline, this.originalTitle, this.editionTitle, this.studio, @JsonKey(fromJson: flexibleInt) this.year, this.originallyAvailableAt, this.contentRating, this.parentId, this.parentTitle, this.parentThumbPath, @JsonKey(fromJson: flexibleInt) this.parentIndex, @JsonKey(fromJson: flexibleInt) this.index, this.grandparentId, this.grandparentTitle, this.grandparentThumbPath, this.grandparentArtPath, this.thumbPath, this.artPath, this.clearLogoPath, this.backgroundSquarePath, @JsonKey(fromJson: flexibleInt) this.durationMs, @JsonKey(fromJson: flexibleInt) this.viewOffsetMs, @JsonKey(fromJson: flexibleInt) this.viewCount, @JsonKey(fromJson: flexibleInt) this.lastViewedAt, @JsonKey(fromJson: flexibleInt) this.leafCount, @JsonKey(fromJson: flexibleInt) this.viewedLeafCount, @JsonKey(fromJson: flexibleInt) this.childCount, @JsonKey(fromJson: flexibleInt) this.addedAt, @JsonKey(fromJson: flexibleInt) this.updatedAt, @JsonKey(fromJson: flexibleDouble) this.rating, @JsonKey(fromJson: flexibleDouble) this.audienceRating, @JsonKey(fromJson: flexibleDouble) this.userRating, this.ratingImage, this.audienceRatingImage, @JsonKey(fromJson: _mediaItemStringList) this.genres, @JsonKey(fromJson: _mediaItemStringList) this.directors, @JsonKey(fromJson: _mediaItemStringList) this.writers, @JsonKey(fromJson: _mediaItemStringList) this.producers, @JsonKey(fromJson: _mediaItemStringList) this.countries, @JsonKey(fromJson: _mediaItemStringList) this.collections, @JsonKey(fromJson: _mediaItemStringList) this.labels, @JsonKey(fromJson: _mediaItemStringList) this.styles, @JsonKey(fromJson: _mediaItemStringList) this.moods, @JsonKey(fromJson: _mediaItemRolesFromJson) this.roles, @JsonKey(fromJson: _mediaItemVersionsFromJson) this.mediaVersions, this.libraryId, this.libraryTitle, this.audioLanguage, this.subtitleLanguage, @JsonKey(fromJson: flexibleInt) this.subtitleMode, this.trailerKey, @JsonKey(fromJson: flexibleInt) this.playlistItemId, @JsonKey(fromJson: flexibleInt) this.playQueueItemId, this.subtype, @JsonKey(fromJson: flexibleInt) this.extraType, this.serverId, this.serverName, this.backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson) this.raw}): super._();
  

@override@JsonKey(readValue: readStringField, defaultValue: '') final  String id;
@override@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) final  MediaKind kind;
@override final  String? guid;
@override final  String? title;
@override final  String? titleSort;
@override final  String? summary;
@override final  String? tagline;
@override final  String? originalTitle;
/// Plex `editionTitle` distinguishes versions of the same movie.
 final  String? editionTitle;
@override final  String? studio;
@override@JsonKey(fromJson: flexibleInt) final  int? year;
@override final  String? originallyAvailableAt;
@override final  String? contentRating;
@override final  String? parentId;
@override final  String? parentTitle;
@override final  String? parentThumbPath;
@override@JsonKey(fromJson: flexibleInt) final  int? parentIndex;
@override@JsonKey(fromJson: flexibleInt) final  int? index;
@override final  String? grandparentId;
@override final  String? grandparentTitle;
@override final  String? grandparentThumbPath;
@override final  String? grandparentArtPath;
@override final  String? thumbPath;
@override final  String? artPath;
@override final  String? clearLogoPath;
@override final  String? backgroundSquarePath;
@override@JsonKey(fromJson: flexibleInt) final  int? durationMs;
@override@JsonKey(fromJson: flexibleInt) final  int? viewOffsetMs;
@override@JsonKey(fromJson: flexibleInt) final  int? viewCount;
@override@JsonKey(fromJson: flexibleInt) final  int? lastViewedAt;
@override@JsonKey(fromJson: flexibleInt) final  int? leafCount;
@override@JsonKey(fromJson: flexibleInt) final  int? viewedLeafCount;
@override@JsonKey(fromJson: flexibleInt) final  int? childCount;
@override@JsonKey(fromJson: flexibleInt) final  int? addedAt;
@override@JsonKey(fromJson: flexibleInt) final  int? updatedAt;
@override@JsonKey(fromJson: flexibleDouble) final  double? rating;
@JsonKey(fromJson: flexibleDouble) final  double? audienceRating;
@override@JsonKey(fromJson: flexibleDouble) final  double? userRating;
 final  String? ratingImage;
 final  String? audienceRatingImage;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? genres;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? directors;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? writers;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? producers;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? countries;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? collections;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? labels;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? styles;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? moods;
@override@JsonKey(fromJson: _mediaItemRolesFromJson) final  List<MediaRole>? roles;
@override@JsonKey(fromJson: _mediaItemVersionsFromJson) final  List<MediaVersion>? mediaVersions;
@override final  String? libraryId;
@override final  String? libraryTitle;
@override final  String? audioLanguage;
 final  String? subtitleLanguage;
@JsonKey(fromJson: flexibleInt) final  int? subtitleMode;
 final  String? trailerKey;
@override@JsonKey(fromJson: flexibleInt) final  int? playlistItemId;
@JsonKey(fromJson: flexibleInt) final  int? playQueueItemId;
 final  String? subtype;
@JsonKey(fromJson: flexibleInt) final  int? extraType;
@override final  String? serverId;
@override final  String? serverName;
/// Relative folder key (`/library/sections/{id}/folder?parent=…`) for
/// [MediaKind.folder] rows — what [MediaServerClient.fetchFolderChildren]
/// tunes into. Stamped by the folder fetchers, null elsewhere.
@override final  String? backendFolderKey;
@override@JsonKey(fromJson: _mediaItemRawFromJson) final  Map<String, Object?>? raw;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlexMediaItemCopyWith<PlexMediaItem> get copyWith => _$PlexMediaItemCopyWithImpl<PlexMediaItem>(this, _$identity);





@override
String toString() {
  return 'MediaItem.plex(id: $id, kind: $kind, guid: $guid, title: $title, titleSort: $titleSort, summary: $summary, tagline: $tagline, originalTitle: $originalTitle, editionTitle: $editionTitle, studio: $studio, year: $year, originallyAvailableAt: $originallyAvailableAt, contentRating: $contentRating, parentId: $parentId, parentTitle: $parentTitle, parentThumbPath: $parentThumbPath, parentIndex: $parentIndex, index: $index, grandparentId: $grandparentId, grandparentTitle: $grandparentTitle, grandparentThumbPath: $grandparentThumbPath, grandparentArtPath: $grandparentArtPath, thumbPath: $thumbPath, artPath: $artPath, clearLogoPath: $clearLogoPath, backgroundSquarePath: $backgroundSquarePath, durationMs: $durationMs, viewOffsetMs: $viewOffsetMs, viewCount: $viewCount, lastViewedAt: $lastViewedAt, leafCount: $leafCount, viewedLeafCount: $viewedLeafCount, childCount: $childCount, addedAt: $addedAt, updatedAt: $updatedAt, rating: $rating, audienceRating: $audienceRating, userRating: $userRating, ratingImage: $ratingImage, audienceRatingImage: $audienceRatingImage, genres: $genres, directors: $directors, writers: $writers, producers: $producers, countries: $countries, collections: $collections, labels: $labels, styles: $styles, moods: $moods, roles: $roles, mediaVersions: $mediaVersions, libraryId: $libraryId, libraryTitle: $libraryTitle, audioLanguage: $audioLanguage, subtitleLanguage: $subtitleLanguage, subtitleMode: $subtitleMode, trailerKey: $trailerKey, playlistItemId: $playlistItemId, playQueueItemId: $playQueueItemId, subtype: $subtype, extraType: $extraType, serverId: $serverId, serverName: $serverName, backendFolderKey: $backendFolderKey, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $PlexMediaItemCopyWith<$Res> implements $MediaItemCopyWith<$Res> {
  factory $PlexMediaItemCopyWith(PlexMediaItem value, $Res Function(PlexMediaItem) _then) = _$PlexMediaItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: readStringField, defaultValue: '') String id,@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) MediaKind kind, String? guid, String? title, String? titleSort, String? summary, String? tagline, String? originalTitle, String? editionTitle, String? studio,@JsonKey(fromJson: flexibleInt) int? year, String? originallyAvailableAt, String? contentRating, String? parentId, String? parentTitle, String? parentThumbPath,@JsonKey(fromJson: flexibleInt) int? parentIndex,@JsonKey(fromJson: flexibleInt) int? index, String? grandparentId, String? grandparentTitle, String? grandparentThumbPath, String? grandparentArtPath, String? thumbPath, String? artPath, String? clearLogoPath, String? backgroundSquarePath,@JsonKey(fromJson: flexibleInt) int? durationMs,@JsonKey(fromJson: flexibleInt) int? viewOffsetMs,@JsonKey(fromJson: flexibleInt) int? viewCount,@JsonKey(fromJson: flexibleInt) int? lastViewedAt,@JsonKey(fromJson: flexibleInt) int? leafCount,@JsonKey(fromJson: flexibleInt) int? viewedLeafCount,@JsonKey(fromJson: flexibleInt) int? childCount,@JsonKey(fromJson: flexibleInt) int? addedAt,@JsonKey(fromJson: flexibleInt) int? updatedAt,@JsonKey(fromJson: flexibleDouble) double? rating,@JsonKey(fromJson: flexibleDouble) double? audienceRating,@JsonKey(fromJson: flexibleDouble) double? userRating, String? ratingImage, String? audienceRatingImage,@JsonKey(fromJson: _mediaItemStringList) List<String>? genres,@JsonKey(fromJson: _mediaItemStringList) List<String>? directors,@JsonKey(fromJson: _mediaItemStringList) List<String>? writers,@JsonKey(fromJson: _mediaItemStringList) List<String>? producers,@JsonKey(fromJson: _mediaItemStringList) List<String>? countries,@JsonKey(fromJson: _mediaItemStringList) List<String>? collections,@JsonKey(fromJson: _mediaItemStringList) List<String>? labels,@JsonKey(fromJson: _mediaItemStringList) List<String>? styles,@JsonKey(fromJson: _mediaItemStringList) List<String>? moods,@JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? roles,@JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? mediaVersions, String? libraryId, String? libraryTitle, String? audioLanguage, String? subtitleLanguage,@JsonKey(fromJson: flexibleInt) int? subtitleMode, String? trailerKey,@JsonKey(fromJson: flexibleInt) int? playlistItemId,@JsonKey(fromJson: flexibleInt) int? playQueueItemId, String? subtype,@JsonKey(fromJson: flexibleInt) int? extraType, String? serverId, String? serverName, String? backendFolderKey,@JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? raw
});




}
/// @nodoc
class _$PlexMediaItemCopyWithImpl<$Res>
    implements $PlexMediaItemCopyWith<$Res> {
  _$PlexMediaItemCopyWithImpl(this._self, this._then);

  final PlexMediaItem _self;
  final $Res Function(PlexMediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? guid = freezed,Object? title = freezed,Object? titleSort = freezed,Object? summary = freezed,Object? tagline = freezed,Object? originalTitle = freezed,Object? editionTitle = freezed,Object? studio = freezed,Object? year = freezed,Object? originallyAvailableAt = freezed,Object? contentRating = freezed,Object? parentId = freezed,Object? parentTitle = freezed,Object? parentThumbPath = freezed,Object? parentIndex = freezed,Object? index = freezed,Object? grandparentId = freezed,Object? grandparentTitle = freezed,Object? grandparentThumbPath = freezed,Object? grandparentArtPath = freezed,Object? thumbPath = freezed,Object? artPath = freezed,Object? clearLogoPath = freezed,Object? backgroundSquarePath = freezed,Object? durationMs = freezed,Object? viewOffsetMs = freezed,Object? viewCount = freezed,Object? lastViewedAt = freezed,Object? leafCount = freezed,Object? viewedLeafCount = freezed,Object? childCount = freezed,Object? addedAt = freezed,Object? updatedAt = freezed,Object? rating = freezed,Object? audienceRating = freezed,Object? userRating = freezed,Object? ratingImage = freezed,Object? audienceRatingImage = freezed,Object? genres = freezed,Object? directors = freezed,Object? writers = freezed,Object? producers = freezed,Object? countries = freezed,Object? collections = freezed,Object? labels = freezed,Object? styles = freezed,Object? moods = freezed,Object? roles = freezed,Object? mediaVersions = freezed,Object? libraryId = freezed,Object? libraryTitle = freezed,Object? audioLanguage = freezed,Object? subtitleLanguage = freezed,Object? subtitleMode = freezed,Object? trailerKey = freezed,Object? playlistItemId = freezed,Object? playQueueItemId = freezed,Object? subtype = freezed,Object? extraType = freezed,Object? serverId = freezed,Object? serverName = freezed,Object? backendFolderKey = freezed,Object? raw = freezed,}) {
  return _then(PlexMediaItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,guid: freezed == guid ? _self.guid : guid // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,titleSort: freezed == titleSort ? _self.titleSort : titleSort // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,originalTitle: freezed == originalTitle ? _self.originalTitle : originalTitle // ignore: cast_nullable_to_non_nullable
as String?,editionTitle: freezed == editionTitle ? _self.editionTitle : editionTitle // ignore: cast_nullable_to_non_nullable
as String?,studio: freezed == studio ? _self.studio : studio // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,originallyAvailableAt: freezed == originallyAvailableAt ? _self.originallyAvailableAt : originallyAvailableAt // ignore: cast_nullable_to_non_nullable
as String?,contentRating: freezed == contentRating ? _self.contentRating : contentRating // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,parentTitle: freezed == parentTitle ? _self.parentTitle : parentTitle // ignore: cast_nullable_to_non_nullable
as String?,parentThumbPath: freezed == parentThumbPath ? _self.parentThumbPath : parentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,parentIndex: freezed == parentIndex ? _self.parentIndex : parentIndex // ignore: cast_nullable_to_non_nullable
as int?,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,grandparentId: freezed == grandparentId ? _self.grandparentId : grandparentId // ignore: cast_nullable_to_non_nullable
as String?,grandparentTitle: freezed == grandparentTitle ? _self.grandparentTitle : grandparentTitle // ignore: cast_nullable_to_non_nullable
as String?,grandparentThumbPath: freezed == grandparentThumbPath ? _self.grandparentThumbPath : grandparentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,grandparentArtPath: freezed == grandparentArtPath ? _self.grandparentArtPath : grandparentArtPath // ignore: cast_nullable_to_non_nullable
as String?,thumbPath: freezed == thumbPath ? _self.thumbPath : thumbPath // ignore: cast_nullable_to_non_nullable
as String?,artPath: freezed == artPath ? _self.artPath : artPath // ignore: cast_nullable_to_non_nullable
as String?,clearLogoPath: freezed == clearLogoPath ? _self.clearLogoPath : clearLogoPath // ignore: cast_nullable_to_non_nullable
as String?,backgroundSquarePath: freezed == backgroundSquarePath ? _self.backgroundSquarePath : backgroundSquarePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,viewOffsetMs: freezed == viewOffsetMs ? _self.viewOffsetMs : viewOffsetMs // ignore: cast_nullable_to_non_nullable
as int?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,lastViewedAt: freezed == lastViewedAt ? _self.lastViewedAt : lastViewedAt // ignore: cast_nullable_to_non_nullable
as int?,leafCount: freezed == leafCount ? _self.leafCount : leafCount // ignore: cast_nullable_to_non_nullable
as int?,viewedLeafCount: freezed == viewedLeafCount ? _self.viewedLeafCount : viewedLeafCount // ignore: cast_nullable_to_non_nullable
as int?,childCount: freezed == childCount ? _self.childCount : childCount // ignore: cast_nullable_to_non_nullable
as int?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,audienceRating: freezed == audienceRating ? _self.audienceRating : audienceRating // ignore: cast_nullable_to_non_nullable
as double?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as double?,ratingImage: freezed == ratingImage ? _self.ratingImage : ratingImage // ignore: cast_nullable_to_non_nullable
as String?,audienceRatingImage: freezed == audienceRatingImage ? _self.audienceRatingImage : audienceRatingImage // ignore: cast_nullable_to_non_nullable
as String?,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,directors: freezed == directors ? _self.directors : directors // ignore: cast_nullable_to_non_nullable
as List<String>?,writers: freezed == writers ? _self.writers : writers // ignore: cast_nullable_to_non_nullable
as List<String>?,producers: freezed == producers ? _self.producers : producers // ignore: cast_nullable_to_non_nullable
as List<String>?,countries: freezed == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as List<String>?,collections: freezed == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as List<String>?,labels: freezed == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as List<String>?,styles: freezed == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>?,moods: freezed == moods ? _self.moods : moods // ignore: cast_nullable_to_non_nullable
as List<String>?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<MediaRole>?,mediaVersions: freezed == mediaVersions ? _self.mediaVersions : mediaVersions // ignore: cast_nullable_to_non_nullable
as List<MediaVersion>?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,libraryTitle: freezed == libraryTitle ? _self.libraryTitle : libraryTitle // ignore: cast_nullable_to_non_nullable
as String?,audioLanguage: freezed == audioLanguage ? _self.audioLanguage : audioLanguage // ignore: cast_nullable_to_non_nullable
as String?,subtitleLanguage: freezed == subtitleLanguage ? _self.subtitleLanguage : subtitleLanguage // ignore: cast_nullable_to_non_nullable
as String?,subtitleMode: freezed == subtitleMode ? _self.subtitleMode : subtitleMode // ignore: cast_nullable_to_non_nullable
as int?,trailerKey: freezed == trailerKey ? _self.trailerKey : trailerKey // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as int?,playQueueItemId: freezed == playQueueItemId ? _self.playQueueItemId : playQueueItemId // ignore: cast_nullable_to_non_nullable
as int?,subtype: freezed == subtype ? _self.subtype : subtype // ignore: cast_nullable_to_non_nullable
as String?,extraType: freezed == extraType ? _self.extraType : extraType // ignore: cast_nullable_to_non_nullable
as int?,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,backendFolderKey: freezed == backendFolderKey ? _self.backendFolderKey : backendFolderKey // ignore: cast_nullable_to_non_nullable
as String?,raw: freezed == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

/// @nodoc

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class JellyfinMediaItem extends MediaItem {
  const JellyfinMediaItem({@JsonKey(readValue: readStringField, defaultValue: '') required this.id, @JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) required this.kind, this.guid, this.title, this.titleSort, this.summary, this.tagline, this.originalTitle, this.studio, @JsonKey(fromJson: flexibleInt) this.year, this.originallyAvailableAt, this.contentRating, this.parentId, this.parentTitle, this.parentThumbPath, @JsonKey(fromJson: flexibleInt) this.parentIndex, @JsonKey(fromJson: flexibleInt) this.index, this.grandparentId, this.grandparentTitle, this.grandparentThumbPath, this.grandparentArtPath, this.thumbPath, this.artPath, this.clearLogoPath, this.backgroundSquarePath, @JsonKey(fromJson: flexibleInt) this.durationMs, @JsonKey(fromJson: flexibleInt) this.viewOffsetMs, @JsonKey(fromJson: flexibleInt) this.viewCount, @JsonKey(fromJson: flexibleInt) this.lastViewedAt, @JsonKey(fromJson: flexibleInt) this.leafCount, @JsonKey(fromJson: flexibleInt) this.viewedLeafCount, @JsonKey(fromJson: flexibleInt) this.childCount, @JsonKey(fromJson: flexibleInt) this.addedAt, @JsonKey(fromJson: flexibleInt) this.updatedAt, @JsonKey(fromJson: flexibleDouble) this.rating, @JsonKey(fromJson: flexibleDouble) this.userRating, @JsonKey(fromJson: _mediaItemStringList) this.genres, @JsonKey(fromJson: _mediaItemStringList) this.directors, @JsonKey(fromJson: _mediaItemStringList) this.writers, @JsonKey(fromJson: _mediaItemStringList) this.producers, @JsonKey(fromJson: _mediaItemStringList) this.countries, @JsonKey(fromJson: _mediaItemStringList) this.collections, @JsonKey(fromJson: _mediaItemStringList) this.labels, @JsonKey(fromJson: _mediaItemStringList) this.styles, @JsonKey(fromJson: _mediaItemStringList) this.moods, @JsonKey(fromJson: _mediaItemRolesFromJson) this.roles, @JsonKey(fromJson: _mediaItemVersionsFromJson) this.mediaVersions, this.libraryId, this.libraryTitle, this.audioLanguage, this.playlistItemId, this.serverId, this.serverName, this.backendFolderKey, @JsonKey(fromJson: _mediaItemRawFromJson) this.raw}): super._();
  

@override@JsonKey(readValue: readStringField, defaultValue: '') final  String id;
@override@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) final  MediaKind kind;
@override final  String? guid;
@override final  String? title;
@override final  String? titleSort;
@override final  String? summary;
@override final  String? tagline;
@override final  String? originalTitle;
@override final  String? studio;
@override@JsonKey(fromJson: flexibleInt) final  int? year;
@override final  String? originallyAvailableAt;
@override final  String? contentRating;
@override final  String? parentId;
@override final  String? parentTitle;
@override final  String? parentThumbPath;
@override@JsonKey(fromJson: flexibleInt) final  int? parentIndex;
@override@JsonKey(fromJson: flexibleInt) final  int? index;
@override final  String? grandparentId;
@override final  String? grandparentTitle;
@override final  String? grandparentThumbPath;
@override final  String? grandparentArtPath;
@override final  String? thumbPath;
@override final  String? artPath;
@override final  String? clearLogoPath;
@override final  String? backgroundSquarePath;
@override@JsonKey(fromJson: flexibleInt) final  int? durationMs;
@override@JsonKey(fromJson: flexibleInt) final  int? viewOffsetMs;
@override@JsonKey(fromJson: flexibleInt) final  int? viewCount;
@override@JsonKey(fromJson: flexibleInt) final  int? lastViewedAt;
@override@JsonKey(fromJson: flexibleInt) final  int? leafCount;
@override@JsonKey(fromJson: flexibleInt) final  int? viewedLeafCount;
@override@JsonKey(fromJson: flexibleInt) final  int? childCount;
@override@JsonKey(fromJson: flexibleInt) final  int? addedAt;
@override@JsonKey(fromJson: flexibleInt) final  int? updatedAt;
@override@JsonKey(fromJson: flexibleDouble) final  double? rating;
@override@JsonKey(fromJson: flexibleDouble) final  double? userRating;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? genres;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? directors;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? writers;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? producers;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? countries;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? collections;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? labels;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? styles;
@override@JsonKey(fromJson: _mediaItemStringList) final  List<String>? moods;
@override@JsonKey(fromJson: _mediaItemRolesFromJson) final  List<MediaRole>? roles;
@override@JsonKey(fromJson: _mediaItemVersionsFromJson) final  List<MediaVersion>? mediaVersions;
@override final  String? libraryId;
@override final  String? libraryTitle;
@override final  String? audioLanguage;
/// Jellyfin playlist entry id used by playlist write endpoints.
@override final  String? playlistItemId;
@override final  String? serverId;
@override final  String? serverName;
/// Always null on Jellyfin — folder children are fetched by [id]. Exists
/// on both variants so the union exposes one neutral getter.
@override final  String? backendFolderKey;
@override@JsonKey(fromJson: _mediaItemRawFromJson) final  Map<String, Object?>? raw;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JellyfinMediaItemCopyWith<JellyfinMediaItem> get copyWith => _$JellyfinMediaItemCopyWithImpl<JellyfinMediaItem>(this, _$identity);





@override
String toString() {
  return 'MediaItem.jellyfin(id: $id, kind: $kind, guid: $guid, title: $title, titleSort: $titleSort, summary: $summary, tagline: $tagline, originalTitle: $originalTitle, studio: $studio, year: $year, originallyAvailableAt: $originallyAvailableAt, contentRating: $contentRating, parentId: $parentId, parentTitle: $parentTitle, parentThumbPath: $parentThumbPath, parentIndex: $parentIndex, index: $index, grandparentId: $grandparentId, grandparentTitle: $grandparentTitle, grandparentThumbPath: $grandparentThumbPath, grandparentArtPath: $grandparentArtPath, thumbPath: $thumbPath, artPath: $artPath, clearLogoPath: $clearLogoPath, backgroundSquarePath: $backgroundSquarePath, durationMs: $durationMs, viewOffsetMs: $viewOffsetMs, viewCount: $viewCount, lastViewedAt: $lastViewedAt, leafCount: $leafCount, viewedLeafCount: $viewedLeafCount, childCount: $childCount, addedAt: $addedAt, updatedAt: $updatedAt, rating: $rating, userRating: $userRating, genres: $genres, directors: $directors, writers: $writers, producers: $producers, countries: $countries, collections: $collections, labels: $labels, styles: $styles, moods: $moods, roles: $roles, mediaVersions: $mediaVersions, libraryId: $libraryId, libraryTitle: $libraryTitle, audioLanguage: $audioLanguage, playlistItemId: $playlistItemId, serverId: $serverId, serverName: $serverName, backendFolderKey: $backendFolderKey, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $JellyfinMediaItemCopyWith<$Res> implements $MediaItemCopyWith<$Res> {
  factory $JellyfinMediaItemCopyWith(JellyfinMediaItem value, $Res Function(JellyfinMediaItem) _then) = _$JellyfinMediaItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: readStringField, defaultValue: '') String id,@JsonKey(fromJson: _mediaKindFromJson, toJson: _mediaKindToJson) MediaKind kind, String? guid, String? title, String? titleSort, String? summary, String? tagline, String? originalTitle, String? studio,@JsonKey(fromJson: flexibleInt) int? year, String? originallyAvailableAt, String? contentRating, String? parentId, String? parentTitle, String? parentThumbPath,@JsonKey(fromJson: flexibleInt) int? parentIndex,@JsonKey(fromJson: flexibleInt) int? index, String? grandparentId, String? grandparentTitle, String? grandparentThumbPath, String? grandparentArtPath, String? thumbPath, String? artPath, String? clearLogoPath, String? backgroundSquarePath,@JsonKey(fromJson: flexibleInt) int? durationMs,@JsonKey(fromJson: flexibleInt) int? viewOffsetMs,@JsonKey(fromJson: flexibleInt) int? viewCount,@JsonKey(fromJson: flexibleInt) int? lastViewedAt,@JsonKey(fromJson: flexibleInt) int? leafCount,@JsonKey(fromJson: flexibleInt) int? viewedLeafCount,@JsonKey(fromJson: flexibleInt) int? childCount,@JsonKey(fromJson: flexibleInt) int? addedAt,@JsonKey(fromJson: flexibleInt) int? updatedAt,@JsonKey(fromJson: flexibleDouble) double? rating,@JsonKey(fromJson: flexibleDouble) double? userRating,@JsonKey(fromJson: _mediaItemStringList) List<String>? genres,@JsonKey(fromJson: _mediaItemStringList) List<String>? directors,@JsonKey(fromJson: _mediaItemStringList) List<String>? writers,@JsonKey(fromJson: _mediaItemStringList) List<String>? producers,@JsonKey(fromJson: _mediaItemStringList) List<String>? countries,@JsonKey(fromJson: _mediaItemStringList) List<String>? collections,@JsonKey(fromJson: _mediaItemStringList) List<String>? labels,@JsonKey(fromJson: _mediaItemStringList) List<String>? styles,@JsonKey(fromJson: _mediaItemStringList) List<String>? moods,@JsonKey(fromJson: _mediaItemRolesFromJson) List<MediaRole>? roles,@JsonKey(fromJson: _mediaItemVersionsFromJson) List<MediaVersion>? mediaVersions, String? libraryId, String? libraryTitle, String? audioLanguage, String? playlistItemId, String? serverId, String? serverName, String? backendFolderKey,@JsonKey(fromJson: _mediaItemRawFromJson) Map<String, Object?>? raw
});




}
/// @nodoc
class _$JellyfinMediaItemCopyWithImpl<$Res>
    implements $JellyfinMediaItemCopyWith<$Res> {
  _$JellyfinMediaItemCopyWithImpl(this._self, this._then);

  final JellyfinMediaItem _self;
  final $Res Function(JellyfinMediaItem) _then;

/// Create a copy of MediaItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? guid = freezed,Object? title = freezed,Object? titleSort = freezed,Object? summary = freezed,Object? tagline = freezed,Object? originalTitle = freezed,Object? studio = freezed,Object? year = freezed,Object? originallyAvailableAt = freezed,Object? contentRating = freezed,Object? parentId = freezed,Object? parentTitle = freezed,Object? parentThumbPath = freezed,Object? parentIndex = freezed,Object? index = freezed,Object? grandparentId = freezed,Object? grandparentTitle = freezed,Object? grandparentThumbPath = freezed,Object? grandparentArtPath = freezed,Object? thumbPath = freezed,Object? artPath = freezed,Object? clearLogoPath = freezed,Object? backgroundSquarePath = freezed,Object? durationMs = freezed,Object? viewOffsetMs = freezed,Object? viewCount = freezed,Object? lastViewedAt = freezed,Object? leafCount = freezed,Object? viewedLeafCount = freezed,Object? childCount = freezed,Object? addedAt = freezed,Object? updatedAt = freezed,Object? rating = freezed,Object? userRating = freezed,Object? genres = freezed,Object? directors = freezed,Object? writers = freezed,Object? producers = freezed,Object? countries = freezed,Object? collections = freezed,Object? labels = freezed,Object? styles = freezed,Object? moods = freezed,Object? roles = freezed,Object? mediaVersions = freezed,Object? libraryId = freezed,Object? libraryTitle = freezed,Object? audioLanguage = freezed,Object? playlistItemId = freezed,Object? serverId = freezed,Object? serverName = freezed,Object? backendFolderKey = freezed,Object? raw = freezed,}) {
  return _then(JellyfinMediaItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind,guid: freezed == guid ? _self.guid : guid // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,titleSort: freezed == titleSort ? _self.titleSort : titleSort // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,tagline: freezed == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String?,originalTitle: freezed == originalTitle ? _self.originalTitle : originalTitle // ignore: cast_nullable_to_non_nullable
as String?,studio: freezed == studio ? _self.studio : studio // ignore: cast_nullable_to_non_nullable
as String?,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,originallyAvailableAt: freezed == originallyAvailableAt ? _self.originallyAvailableAt : originallyAvailableAt // ignore: cast_nullable_to_non_nullable
as String?,contentRating: freezed == contentRating ? _self.contentRating : contentRating // ignore: cast_nullable_to_non_nullable
as String?,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,parentTitle: freezed == parentTitle ? _self.parentTitle : parentTitle // ignore: cast_nullable_to_non_nullable
as String?,parentThumbPath: freezed == parentThumbPath ? _self.parentThumbPath : parentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,parentIndex: freezed == parentIndex ? _self.parentIndex : parentIndex // ignore: cast_nullable_to_non_nullable
as int?,index: freezed == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int?,grandparentId: freezed == grandparentId ? _self.grandparentId : grandparentId // ignore: cast_nullable_to_non_nullable
as String?,grandparentTitle: freezed == grandparentTitle ? _self.grandparentTitle : grandparentTitle // ignore: cast_nullable_to_non_nullable
as String?,grandparentThumbPath: freezed == grandparentThumbPath ? _self.grandparentThumbPath : grandparentThumbPath // ignore: cast_nullable_to_non_nullable
as String?,grandparentArtPath: freezed == grandparentArtPath ? _self.grandparentArtPath : grandparentArtPath // ignore: cast_nullable_to_non_nullable
as String?,thumbPath: freezed == thumbPath ? _self.thumbPath : thumbPath // ignore: cast_nullable_to_non_nullable
as String?,artPath: freezed == artPath ? _self.artPath : artPath // ignore: cast_nullable_to_non_nullable
as String?,clearLogoPath: freezed == clearLogoPath ? _self.clearLogoPath : clearLogoPath // ignore: cast_nullable_to_non_nullable
as String?,backgroundSquarePath: freezed == backgroundSquarePath ? _self.backgroundSquarePath : backgroundSquarePath // ignore: cast_nullable_to_non_nullable
as String?,durationMs: freezed == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int?,viewOffsetMs: freezed == viewOffsetMs ? _self.viewOffsetMs : viewOffsetMs // ignore: cast_nullable_to_non_nullable
as int?,viewCount: freezed == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int?,lastViewedAt: freezed == lastViewedAt ? _self.lastViewedAt : lastViewedAt // ignore: cast_nullable_to_non_nullable
as int?,leafCount: freezed == leafCount ? _self.leafCount : leafCount // ignore: cast_nullable_to_non_nullable
as int?,viewedLeafCount: freezed == viewedLeafCount ? _self.viewedLeafCount : viewedLeafCount // ignore: cast_nullable_to_non_nullable
as int?,childCount: freezed == childCount ? _self.childCount : childCount // ignore: cast_nullable_to_non_nullable
as int?,addedAt: freezed == addedAt ? _self.addedAt : addedAt // ignore: cast_nullable_to_non_nullable
as int?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,userRating: freezed == userRating ? _self.userRating : userRating // ignore: cast_nullable_to_non_nullable
as double?,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,directors: freezed == directors ? _self.directors : directors // ignore: cast_nullable_to_non_nullable
as List<String>?,writers: freezed == writers ? _self.writers : writers // ignore: cast_nullable_to_non_nullable
as List<String>?,producers: freezed == producers ? _self.producers : producers // ignore: cast_nullable_to_non_nullable
as List<String>?,countries: freezed == countries ? _self.countries : countries // ignore: cast_nullable_to_non_nullable
as List<String>?,collections: freezed == collections ? _self.collections : collections // ignore: cast_nullable_to_non_nullable
as List<String>?,labels: freezed == labels ? _self.labels : labels // ignore: cast_nullable_to_non_nullable
as List<String>?,styles: freezed == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>?,moods: freezed == moods ? _self.moods : moods // ignore: cast_nullable_to_non_nullable
as List<String>?,roles: freezed == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<MediaRole>?,mediaVersions: freezed == mediaVersions ? _self.mediaVersions : mediaVersions // ignore: cast_nullable_to_non_nullable
as List<MediaVersion>?,libraryId: freezed == libraryId ? _self.libraryId : libraryId // ignore: cast_nullable_to_non_nullable
as String?,libraryTitle: freezed == libraryTitle ? _self.libraryTitle : libraryTitle // ignore: cast_nullable_to_non_nullable
as String?,audioLanguage: freezed == audioLanguage ? _self.audioLanguage : audioLanguage // ignore: cast_nullable_to_non_nullable
as String?,playlistItemId: freezed == playlistItemId ? _self.playlistItemId : playlistItemId // ignore: cast_nullable_to_non_nullable
as String?,serverId: freezed == serverId ? _self.serverId : serverId // ignore: cast_nullable_to_non_nullable
as String?,serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,backendFolderKey: freezed == backendFolderKey ? _self.backendFolderKey : backendFolderKey // ignore: cast_nullable_to_non_nullable
as String?,raw: freezed == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,
  ));
}


}

// dart format on
