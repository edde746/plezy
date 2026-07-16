// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibrarySort {

 String get field; LibrarySortDirection get direction;
/// Create a copy of LibrarySort
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibrarySortCopyWith<LibrarySort> get copyWith => _$LibrarySortCopyWithImpl<LibrarySort>(this as LibrarySort, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibrarySort&&(identical(other.field, field) || other.field == field)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,field,direction);

@override
String toString() {
  return 'LibrarySort(field: $field, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $LibrarySortCopyWith<$Res>  {
  factory $LibrarySortCopyWith(LibrarySort value, $Res Function(LibrarySort) _then) = _$LibrarySortCopyWithImpl;
@useResult
$Res call({
 String field, LibrarySortDirection direction
});




}
/// @nodoc
class _$LibrarySortCopyWithImpl<$Res>
    implements $LibrarySortCopyWith<$Res> {
  _$LibrarySortCopyWithImpl(this._self, this._then);

  final LibrarySort _self;
  final $Res Function(LibrarySort) _then;

/// Create a copy of LibrarySort
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? direction = null,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as LibrarySortDirection,
  ));
}

}


/// Adds pattern-matching-related methods to [LibrarySort].
extension LibrarySortPatterns on LibrarySort {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibrarySort value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibrarySort() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibrarySort value)  $default,){
final _that = this;
switch (_that) {
case _LibrarySort():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibrarySort value)?  $default,){
final _that = this;
switch (_that) {
case _LibrarySort() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String field,  LibrarySortDirection direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibrarySort() when $default != null:
return $default(_that.field,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String field,  LibrarySortDirection direction)  $default,) {final _that = this;
switch (_that) {
case _LibrarySort():
return $default(_that.field,_that.direction);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String field,  LibrarySortDirection direction)?  $default,) {final _that = this;
switch (_that) {
case _LibrarySort() when $default != null:
return $default(_that.field,_that.direction);case _:
  return null;

}
}

}

/// @nodoc


class _LibrarySort implements LibrarySort {
  const _LibrarySort({required this.field, this.direction = LibrarySortDirection.descending});
  

@override final  String field;
@override@JsonKey() final  LibrarySortDirection direction;

/// Create a copy of LibrarySort
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibrarySortCopyWith<_LibrarySort> get copyWith => __$LibrarySortCopyWithImpl<_LibrarySort>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibrarySort&&(identical(other.field, field) || other.field == field)&&(identical(other.direction, direction) || other.direction == direction));
}


@override
int get hashCode => Object.hash(runtimeType,field,direction);

@override
String toString() {
  return 'LibrarySort(field: $field, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$LibrarySortCopyWith<$Res> implements $LibrarySortCopyWith<$Res> {
  factory _$LibrarySortCopyWith(_LibrarySort value, $Res Function(_LibrarySort) _then) = __$LibrarySortCopyWithImpl;
@override @useResult
$Res call({
 String field, LibrarySortDirection direction
});




}
/// @nodoc
class __$LibrarySortCopyWithImpl<$Res>
    implements _$LibrarySortCopyWith<$Res> {
  __$LibrarySortCopyWithImpl(this._self, this._then);

  final _LibrarySort _self;
  final $Res Function(_LibrarySort) _then;

/// Create a copy of LibrarySort
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? direction = null,}) {
  return _then(_LibrarySort(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as LibrarySortDirection,
  ));
}


}

/// @nodoc
mixin _$LibraryFilter {

 String get field; String get op; List<String> get values;
/// Create a copy of LibraryFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryFilterCopyWith<LibraryFilter> get copyWith => _$LibraryFilterCopyWithImpl<LibraryFilter>(this as LibraryFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryFilter&&(identical(other.field, field) || other.field == field)&&(identical(other.op, op) || other.op == op)&&const DeepCollectionEquality().equals(other.values, values));
}


@override
int get hashCode => Object.hash(runtimeType,field,op,const DeepCollectionEquality().hash(values));

@override
String toString() {
  return 'LibraryFilter(field: $field, op: $op, values: $values)';
}


}

/// @nodoc
abstract mixin class $LibraryFilterCopyWith<$Res>  {
  factory $LibraryFilterCopyWith(LibraryFilter value, $Res Function(LibraryFilter) _then) = _$LibraryFilterCopyWithImpl;
@useResult
$Res call({
 String field, String op, List<String> values
});




}
/// @nodoc
class _$LibraryFilterCopyWithImpl<$Res>
    implements $LibraryFilterCopyWith<$Res> {
  _$LibraryFilterCopyWithImpl(this._self, this._then);

  final LibraryFilter _self;
  final $Res Function(LibraryFilter) _then;

/// Create a copy of LibraryFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? op = null,Object? values = null,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self.values : values // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryFilter].
extension LibraryFilterPatterns on LibraryFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryFilter() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryFilter value)  $default,){
final _that = this;
switch (_that) {
case _LibraryFilter():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryFilter value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryFilter() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String field,  String op,  List<String> values)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryFilter() when $default != null:
return $default(_that.field,_that.op,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String field,  String op,  List<String> values)  $default,) {final _that = this;
switch (_that) {
case _LibraryFilter():
return $default(_that.field,_that.op,_that.values);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String field,  String op,  List<String> values)?  $default,) {final _that = this;
switch (_that) {
case _LibraryFilter() when $default != null:
return $default(_that.field,_that.op,_that.values);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryFilter implements LibraryFilter {
  const _LibraryFilter({required this.field, this.op = '=', required final  List<String> values}): _values = values;
  

@override final  String field;
@override@JsonKey() final  String op;
 final  List<String> _values;
@override List<String> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of LibraryFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryFilterCopyWith<_LibraryFilter> get copyWith => __$LibraryFilterCopyWithImpl<_LibraryFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryFilter&&(identical(other.field, field) || other.field == field)&&(identical(other.op, op) || other.op == op)&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,field,op,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'LibraryFilter(field: $field, op: $op, values: $values)';
}


}

/// @nodoc
abstract mixin class _$LibraryFilterCopyWith<$Res> implements $LibraryFilterCopyWith<$Res> {
  factory _$LibraryFilterCopyWith(_LibraryFilter value, $Res Function(_LibraryFilter) _then) = __$LibraryFilterCopyWithImpl;
@override @useResult
$Res call({
 String field, String op, List<String> values
});




}
/// @nodoc
class __$LibraryFilterCopyWithImpl<$Res>
    implements _$LibraryFilterCopyWith<$Res> {
  __$LibraryFilterCopyWithImpl(this._self, this._then);

  final _LibraryFilter _self;
  final $Res Function(_LibraryFilter) _then;

/// Create a copy of LibraryFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? op = null,Object? values = null,}) {
  return _then(_LibraryFilter(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,op: null == op ? _self.op : op // ignore: cast_nullable_to_non_nullable
as String,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$LibraryQuery {

/// Restrict to a single kind (e.g. `MediaKind.movie`). Null = library default.
 MediaKind? get kind;/// Pagination — zero-based offset.
 int get offset; int get limit; LibrarySort? get sort; List<LibraryFilter> get filters;/// Free-text search restricted to this library. Distinct from the global
/// search endpoint.
 String? get search;/// Whether to include items the active user has already watched.
 bool get includeWatched;/// Restrict to items the user marked favorite (Jellyfin `Filters=IsFavorite`).
/// Plex has no equivalent; its translator ignores the flag.
 bool get favoritesOnly;/// Restrict the result to items whose sort name starts with this string —
/// the alpha-jump bar's filter UX. The literal `#` is a sentinel for
/// "non-alphabetic" and translates to a `NameLessThan=A` query for backends
/// that support it.
 String? get nameStartsWith;/// Genre filter — used by the per-library filter sheet. Backends that
/// take multiple values (Jellyfin) AND/intersect; those that take one
/// (Plex's existing flow) consult `filters` instead.
 List<String>? get genres; List<String>? get officialRatings; List<int>? get years; List<String>? get tags;
/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryQueryCopyWith<LibraryQuery> get copyWith => _$LibraryQueryCopyWithImpl<LibraryQuery>(this as LibraryQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryQuery&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other.filters, filters)&&(identical(other.search, search) || other.search == search)&&(identical(other.includeWatched, includeWatched) || other.includeWatched == includeWatched)&&(identical(other.favoritesOnly, favoritesOnly) || other.favoritesOnly == favoritesOnly)&&(identical(other.nameStartsWith, nameStartsWith) || other.nameStartsWith == nameStartsWith)&&const DeepCollectionEquality().equals(other.genres, genres)&&const DeepCollectionEquality().equals(other.officialRatings, officialRatings)&&const DeepCollectionEquality().equals(other.years, years)&&const DeepCollectionEquality().equals(other.tags, tags));
}


@override
int get hashCode => Object.hash(runtimeType,kind,offset,limit,sort,const DeepCollectionEquality().hash(filters),search,includeWatched,favoritesOnly,nameStartsWith,const DeepCollectionEquality().hash(genres),const DeepCollectionEquality().hash(officialRatings),const DeepCollectionEquality().hash(years),const DeepCollectionEquality().hash(tags));

@override
String toString() {
  return 'LibraryQuery(kind: $kind, offset: $offset, limit: $limit, sort: $sort, filters: $filters, search: $search, includeWatched: $includeWatched, favoritesOnly: $favoritesOnly, nameStartsWith: $nameStartsWith, genres: $genres, officialRatings: $officialRatings, years: $years, tags: $tags)';
}


}

/// @nodoc
abstract mixin class $LibraryQueryCopyWith<$Res>  {
  factory $LibraryQueryCopyWith(LibraryQuery value, $Res Function(LibraryQuery) _then) = _$LibraryQueryCopyWithImpl;
@useResult
$Res call({
 MediaKind? kind, int offset, int limit, LibrarySort? sort, List<LibraryFilter> filters, String? search, bool includeWatched, bool favoritesOnly, String? nameStartsWith, List<String>? genres, List<String>? officialRatings, List<int>? years, List<String>? tags
});


$LibrarySortCopyWith<$Res>? get sort;

}
/// @nodoc
class _$LibraryQueryCopyWithImpl<$Res>
    implements $LibraryQueryCopyWith<$Res> {
  _$LibraryQueryCopyWithImpl(this._self, this._then);

  final LibraryQuery _self;
  final $Res Function(LibraryQuery) _then;

/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = freezed,Object? offset = null,Object? limit = null,Object? sort = freezed,Object? filters = null,Object? search = freezed,Object? includeWatched = null,Object? favoritesOnly = null,Object? nameStartsWith = freezed,Object? genres = freezed,Object? officialRatings = freezed,Object? years = freezed,Object? tags = freezed,}) {
  return _then(_self.copyWith(
kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind?,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as LibrarySort?,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as List<LibraryFilter>,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,includeWatched: null == includeWatched ? _self.includeWatched : includeWatched // ignore: cast_nullable_to_non_nullable
as bool,favoritesOnly: null == favoritesOnly ? _self.favoritesOnly : favoritesOnly // ignore: cast_nullable_to_non_nullable
as bool,nameStartsWith: freezed == nameStartsWith ? _self.nameStartsWith : nameStartsWith // ignore: cast_nullable_to_non_nullable
as String?,genres: freezed == genres ? _self.genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,officialRatings: freezed == officialRatings ? _self.officialRatings : officialRatings // ignore: cast_nullable_to_non_nullable
as List<String>?,years: freezed == years ? _self.years : years // ignore: cast_nullable_to_non_nullable
as List<int>?,tags: freezed == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibrarySortCopyWith<$Res>? get sort {
    if (_self.sort == null) {
    return null;
  }

  return $LibrarySortCopyWith<$Res>(_self.sort!, (value) {
    return _then(_self.copyWith(sort: value));
  });
}
}


/// Adds pattern-matching-related methods to [LibraryQuery].
extension LibraryQueryPatterns on LibraryQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryQuery() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryQuery value)  $default,){
final _that = this;
switch (_that) {
case _LibraryQuery():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryQuery value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryQuery() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MediaKind? kind,  int offset,  int limit,  LibrarySort? sort,  List<LibraryFilter> filters,  String? search,  bool includeWatched,  bool favoritesOnly,  String? nameStartsWith,  List<String>? genres,  List<String>? officialRatings,  List<int>? years,  List<String>? tags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryQuery() when $default != null:
return $default(_that.kind,_that.offset,_that.limit,_that.sort,_that.filters,_that.search,_that.includeWatched,_that.favoritesOnly,_that.nameStartsWith,_that.genres,_that.officialRatings,_that.years,_that.tags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MediaKind? kind,  int offset,  int limit,  LibrarySort? sort,  List<LibraryFilter> filters,  String? search,  bool includeWatched,  bool favoritesOnly,  String? nameStartsWith,  List<String>? genres,  List<String>? officialRatings,  List<int>? years,  List<String>? tags)  $default,) {final _that = this;
switch (_that) {
case _LibraryQuery():
return $default(_that.kind,_that.offset,_that.limit,_that.sort,_that.filters,_that.search,_that.includeWatched,_that.favoritesOnly,_that.nameStartsWith,_that.genres,_that.officialRatings,_that.years,_that.tags);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MediaKind? kind,  int offset,  int limit,  LibrarySort? sort,  List<LibraryFilter> filters,  String? search,  bool includeWatched,  bool favoritesOnly,  String? nameStartsWith,  List<String>? genres,  List<String>? officialRatings,  List<int>? years,  List<String>? tags)?  $default,) {final _that = this;
switch (_that) {
case _LibraryQuery() when $default != null:
return $default(_that.kind,_that.offset,_that.limit,_that.sort,_that.filters,_that.search,_that.includeWatched,_that.favoritesOnly,_that.nameStartsWith,_that.genres,_that.officialRatings,_that.years,_that.tags);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryQuery implements LibraryQuery {
  const _LibraryQuery({this.kind, this.offset = 0, this.limit = 50, this.sort, final  List<LibraryFilter> filters = const <LibraryFilter>[], this.search, this.includeWatched = true, this.favoritesOnly = false, this.nameStartsWith, final  List<String>? genres, final  List<String>? officialRatings, final  List<int>? years, final  List<String>? tags}): _filters = filters,_genres = genres,_officialRatings = officialRatings,_years = years,_tags = tags;
  

/// Restrict to a single kind (e.g. `MediaKind.movie`). Null = library default.
@override final  MediaKind? kind;
/// Pagination — zero-based offset.
@override@JsonKey() final  int offset;
@override@JsonKey() final  int limit;
@override final  LibrarySort? sort;
 final  List<LibraryFilter> _filters;
@override@JsonKey() List<LibraryFilter> get filters {
  if (_filters is EqualUnmodifiableListView) return _filters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filters);
}

/// Free-text search restricted to this library. Distinct from the global
/// search endpoint.
@override final  String? search;
/// Whether to include items the active user has already watched.
@override@JsonKey() final  bool includeWatched;
/// Restrict to items the user marked favorite (Jellyfin `Filters=IsFavorite`).
/// Plex has no equivalent; its translator ignores the flag.
@override@JsonKey() final  bool favoritesOnly;
/// Restrict the result to items whose sort name starts with this string —
/// the alpha-jump bar's filter UX. The literal `#` is a sentinel for
/// "non-alphabetic" and translates to a `NameLessThan=A` query for backends
/// that support it.
@override final  String? nameStartsWith;
/// Genre filter — used by the per-library filter sheet. Backends that
/// take multiple values (Jellyfin) AND/intersect; those that take one
/// (Plex's existing flow) consult `filters` instead.
 final  List<String>? _genres;
/// Genre filter — used by the per-library filter sheet. Backends that
/// take multiple values (Jellyfin) AND/intersect; those that take one
/// (Plex's existing flow) consult `filters` instead.
@override List<String>? get genres {
  final value = _genres;
  if (value == null) return null;
  if (_genres is EqualUnmodifiableListView) return _genres;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _officialRatings;
@override List<String>? get officialRatings {
  final value = _officialRatings;
  if (value == null) return null;
  if (_officialRatings is EqualUnmodifiableListView) return _officialRatings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<int>? _years;
@override List<int>? get years {
  final value = _years;
  if (value == null) return null;
  if (_years is EqualUnmodifiableListView) return _years;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _tags;
@override List<String>? get tags {
  final value = _tags;
  if (value == null) return null;
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryQueryCopyWith<_LibraryQuery> get copyWith => __$LibraryQueryCopyWithImpl<_LibraryQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryQuery&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.offset, offset) || other.offset == offset)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.sort, sort) || other.sort == sort)&&const DeepCollectionEquality().equals(other._filters, _filters)&&(identical(other.search, search) || other.search == search)&&(identical(other.includeWatched, includeWatched) || other.includeWatched == includeWatched)&&(identical(other.favoritesOnly, favoritesOnly) || other.favoritesOnly == favoritesOnly)&&(identical(other.nameStartsWith, nameStartsWith) || other.nameStartsWith == nameStartsWith)&&const DeepCollectionEquality().equals(other._genres, _genres)&&const DeepCollectionEquality().equals(other._officialRatings, _officialRatings)&&const DeepCollectionEquality().equals(other._years, _years)&&const DeepCollectionEquality().equals(other._tags, _tags));
}


@override
int get hashCode => Object.hash(runtimeType,kind,offset,limit,sort,const DeepCollectionEquality().hash(_filters),search,includeWatched,favoritesOnly,nameStartsWith,const DeepCollectionEquality().hash(_genres),const DeepCollectionEquality().hash(_officialRatings),const DeepCollectionEquality().hash(_years),const DeepCollectionEquality().hash(_tags));

@override
String toString() {
  return 'LibraryQuery(kind: $kind, offset: $offset, limit: $limit, sort: $sort, filters: $filters, search: $search, includeWatched: $includeWatched, favoritesOnly: $favoritesOnly, nameStartsWith: $nameStartsWith, genres: $genres, officialRatings: $officialRatings, years: $years, tags: $tags)';
}


}

/// @nodoc
abstract mixin class _$LibraryQueryCopyWith<$Res> implements $LibraryQueryCopyWith<$Res> {
  factory _$LibraryQueryCopyWith(_LibraryQuery value, $Res Function(_LibraryQuery) _then) = __$LibraryQueryCopyWithImpl;
@override @useResult
$Res call({
 MediaKind? kind, int offset, int limit, LibrarySort? sort, List<LibraryFilter> filters, String? search, bool includeWatched, bool favoritesOnly, String? nameStartsWith, List<String>? genres, List<String>? officialRatings, List<int>? years, List<String>? tags
});


@override $LibrarySortCopyWith<$Res>? get sort;

}
/// @nodoc
class __$LibraryQueryCopyWithImpl<$Res>
    implements _$LibraryQueryCopyWith<$Res> {
  __$LibraryQueryCopyWithImpl(this._self, this._then);

  final _LibraryQuery _self;
  final $Res Function(_LibraryQuery) _then;

/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = freezed,Object? offset = null,Object? limit = null,Object? sort = freezed,Object? filters = null,Object? search = freezed,Object? includeWatched = null,Object? favoritesOnly = null,Object? nameStartsWith = freezed,Object? genres = freezed,Object? officialRatings = freezed,Object? years = freezed,Object? tags = freezed,}) {
  return _then(_LibraryQuery(
kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MediaKind?,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as LibrarySort?,filters: null == filters ? _self._filters : filters // ignore: cast_nullable_to_non_nullable
as List<LibraryFilter>,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,includeWatched: null == includeWatched ? _self.includeWatched : includeWatched // ignore: cast_nullable_to_non_nullable
as bool,favoritesOnly: null == favoritesOnly ? _self.favoritesOnly : favoritesOnly // ignore: cast_nullable_to_non_nullable
as bool,nameStartsWith: freezed == nameStartsWith ? _self.nameStartsWith : nameStartsWith // ignore: cast_nullable_to_non_nullable
as String?,genres: freezed == genres ? _self._genres : genres // ignore: cast_nullable_to_non_nullable
as List<String>?,officialRatings: freezed == officialRatings ? _self._officialRatings : officialRatings // ignore: cast_nullable_to_non_nullable
as List<String>?,years: freezed == years ? _self._years : years // ignore: cast_nullable_to_non_nullable
as List<int>?,tags: freezed == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of LibraryQuery
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibrarySortCopyWith<$Res>? get sort {
    if (_self.sort == null) {
    return null;
  }

  return $LibrarySortCopyWith<$Res>(_self.sort!, (value) {
    return _then(_self.copyWith(sort: value));
  });
}
}

/// @nodoc
mixin _$LibraryPage<T> {

 List<T> get items; int get totalCount; int get offset;
/// Create a copy of LibraryPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryPageCopyWith<T, LibraryPage<T>> get copyWith => _$LibraryPageCopyWithImpl<T, LibraryPage<T>>(this as LibraryPage<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryPage<T>&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,offset);

@override
String toString() {
  return 'LibraryPage<$T>(items: $items, totalCount: $totalCount, offset: $offset)';
}


}

/// @nodoc
abstract mixin class $LibraryPageCopyWith<T,$Res>  {
  factory $LibraryPageCopyWith(LibraryPage<T> value, $Res Function(LibraryPage<T>) _then) = _$LibraryPageCopyWithImpl;
@useResult
$Res call({
 List<T> items, int totalCount, int offset
});




}
/// @nodoc
class _$LibraryPageCopyWithImpl<T,$Res>
    implements $LibraryPageCopyWith<T, $Res> {
  _$LibraryPageCopyWithImpl(this._self, this._then);

  final LibraryPage<T> _self;
  final $Res Function(LibraryPage<T>) _then;

/// Create a copy of LibraryPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? offset = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<T>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryPage].
extension LibraryPagePatterns<T> on LibraryPage<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryPage<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryPage() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryPage<T> value)  $default,){
final _that = this;
switch (_that) {
case _LibraryPage():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryPage<T> value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryPage() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<T> items,  int totalCount,  int offset)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryPage() when $default != null:
return $default(_that.items,_that.totalCount,_that.offset);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<T> items,  int totalCount,  int offset)  $default,) {final _that = this;
switch (_that) {
case _LibraryPage():
return $default(_that.items,_that.totalCount,_that.offset);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<T> items,  int totalCount,  int offset)?  $default,) {final _that = this;
switch (_that) {
case _LibraryPage() when $default != null:
return $default(_that.items,_that.totalCount,_that.offset);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryPage<T> implements LibraryPage<T> {
  const _LibraryPage({required final  List<T> items, required this.totalCount, this.offset = 0}): _items = items;
  

 final  List<T> _items;
@override List<T> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  int totalCount;
@override@JsonKey() final  int offset;

/// Create a copy of LibraryPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryPageCopyWith<T, _LibraryPage<T>> get copyWith => __$LibraryPageCopyWithImpl<T, _LibraryPage<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryPage<T>&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.offset, offset) || other.offset == offset));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,offset);

@override
String toString() {
  return 'LibraryPage<$T>(items: $items, totalCount: $totalCount, offset: $offset)';
}


}

/// @nodoc
abstract mixin class _$LibraryPageCopyWith<T,$Res> implements $LibraryPageCopyWith<T, $Res> {
  factory _$LibraryPageCopyWith(_LibraryPage<T> value, $Res Function(_LibraryPage<T>) _then) = __$LibraryPageCopyWithImpl;
@override @useResult
$Res call({
 List<T> items, int totalCount, int offset
});




}
/// @nodoc
class __$LibraryPageCopyWithImpl<T,$Res>
    implements _$LibraryPageCopyWith<T, $Res> {
  __$LibraryPageCopyWithImpl(this._self, this._then);

  final _LibraryPage<T> _self;
  final $Res Function(_LibraryPage<T>) _then;

/// Create a copy of LibraryPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? offset = null,}) {
  return _then(_LibraryPage<T>(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<T>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,offset: null == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
