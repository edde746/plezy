// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BufferRange {

 Duration get start; Duration get end;
/// Create a copy of BufferRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BufferRangeCopyWith<BufferRange> get copyWith => _$BufferRangeCopyWithImpl<BufferRange>(this as BufferRange, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BufferRange&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}


@override
int get hashCode => Object.hash(runtimeType,start,end);

@override
String toString() {
  return 'BufferRange(start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class $BufferRangeCopyWith<$Res>  {
  factory $BufferRangeCopyWith(BufferRange value, $Res Function(BufferRange) _then) = _$BufferRangeCopyWithImpl;
@useResult
$Res call({
 Duration start, Duration end
});




}
/// @nodoc
class _$BufferRangeCopyWithImpl<$Res>
    implements $BufferRangeCopyWith<$Res> {
  _$BufferRangeCopyWithImpl(this._self, this._then);

  final BufferRange _self;
  final $Res Function(BufferRange) _then;

/// Create a copy of BufferRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,}) {
  return _then(_self.copyWith(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [BufferRange].
extension BufferRangePatterns on BufferRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BufferRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BufferRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BufferRange value)  $default,){
final _that = this;
switch (_that) {
case _BufferRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BufferRange value)?  $default,){
final _that = this;
switch (_that) {
case _BufferRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration start,  Duration end)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BufferRange() when $default != null:
return $default(_that.start,_that.end);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration start,  Duration end)  $default,) {final _that = this;
switch (_that) {
case _BufferRange():
return $default(_that.start,_that.end);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration start,  Duration end)?  $default,) {final _that = this;
switch (_that) {
case _BufferRange() when $default != null:
return $default(_that.start,_that.end);case _:
  return null;

}
}

}

/// @nodoc


class _BufferRange implements BufferRange {
  const _BufferRange({required this.start, required this.end});
  

@override final  Duration start;
@override final  Duration end;

/// Create a copy of BufferRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BufferRangeCopyWith<_BufferRange> get copyWith => __$BufferRangeCopyWithImpl<_BufferRange>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BufferRange&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end));
}


@override
int get hashCode => Object.hash(runtimeType,start,end);

@override
String toString() {
  return 'BufferRange(start: $start, end: $end)';
}


}

/// @nodoc
abstract mixin class _$BufferRangeCopyWith<$Res> implements $BufferRangeCopyWith<$Res> {
  factory _$BufferRangeCopyWith(_BufferRange value, $Res Function(_BufferRange) _then) = __$BufferRangeCopyWithImpl;
@override @useResult
$Res call({
 Duration start, Duration end
});




}
/// @nodoc
class __$BufferRangeCopyWithImpl<$Res>
    implements _$BufferRangeCopyWith<$Res> {
  __$BufferRangeCopyWithImpl(this._self, this._then);

  final _BufferRange _self;
  final $Res Function(_BufferRange) _then;

/// Create a copy of BufferRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,}) {
  return _then(_BufferRange(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

/// @nodoc
mixin _$PlayerError {

 String get message; String? get cause;
/// Create a copy of PlayerError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerErrorCopyWith<PlayerError> get copyWith => _$PlayerErrorCopyWithImpl<PlayerError>(this as PlayerError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerError&&(identical(other.message, message) || other.message == message)&&(identical(other.cause, cause) || other.cause == cause));
}


@override
int get hashCode => Object.hash(runtimeType,message,cause);



}

/// @nodoc
abstract mixin class $PlayerErrorCopyWith<$Res>  {
  factory $PlayerErrorCopyWith(PlayerError value, $Res Function(PlayerError) _then) = _$PlayerErrorCopyWithImpl;
@useResult
$Res call({
 String message, String? cause
});




}
/// @nodoc
class _$PlayerErrorCopyWithImpl<$Res>
    implements $PlayerErrorCopyWith<$Res> {
  _$PlayerErrorCopyWithImpl(this._self, this._then);

  final PlayerError _self;
  final $Res Function(PlayerError) _then;

/// Create a copy of PlayerError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerError].
extension PlayerErrorPatterns on PlayerError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerError value)  $default,){
final _that = this;
switch (_that) {
case _PlayerError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerError value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  String? cause)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerError() when $default != null:
return $default(_that.message,_that.cause);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  String? cause)  $default,) {final _that = this;
switch (_that) {
case _PlayerError():
return $default(_that.message,_that.cause);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  String? cause)?  $default,) {final _that = this;
switch (_that) {
case _PlayerError() when $default != null:
return $default(_that.message,_that.cause);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerError extends PlayerError {
  const _PlayerError(this.message, {this.cause}): super._();
  

@override final  String message;
@override final  String? cause;

/// Create a copy of PlayerError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerErrorCopyWith<_PlayerError> get copyWith => __$PlayerErrorCopyWithImpl<_PlayerError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerError&&(identical(other.message, message) || other.message == message)&&(identical(other.cause, cause) || other.cause == cause));
}


@override
int get hashCode => Object.hash(runtimeType,message,cause);



}

/// @nodoc
abstract mixin class _$PlayerErrorCopyWith<$Res> implements $PlayerErrorCopyWith<$Res> {
  factory _$PlayerErrorCopyWith(_PlayerError value, $Res Function(_PlayerError) _then) = __$PlayerErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, String? cause
});




}
/// @nodoc
class __$PlayerErrorCopyWithImpl<$Res>
    implements _$PlayerErrorCopyWith<$Res> {
  __$PlayerErrorCopyWithImpl(this._self, this._then);

  final _PlayerError _self;
  final $Res Function(_PlayerError) _then;

/// Create a copy of PlayerError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? cause = freezed,}) {
  return _then(_PlayerError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,cause: freezed == cause ? _self.cause : cause // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AudioTrack {

 String get id; String? get title; String? get language; String? get codec; int? get channels; int? get sampleRate; int? get bitrate; bool get isDefault; bool get isForced;
/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioTrackCopyWith<AudioTrack> get copyWith => _$AudioTrackCopyWithImpl<AudioTrack>(this as AudioTrack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.isForced, isForced) || other.isForced == isForced));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,language,codec,channels,sampleRate,bitrate,isDefault,isForced);

@override
String toString() {
  return 'AudioTrack(id: $id, title: $title, language: $language, codec: $codec, channels: $channels, sampleRate: $sampleRate, bitrate: $bitrate, isDefault: $isDefault, isForced: $isForced)';
}


}

/// @nodoc
abstract mixin class $AudioTrackCopyWith<$Res>  {
  factory $AudioTrackCopyWith(AudioTrack value, $Res Function(AudioTrack) _then) = _$AudioTrackCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? language, String? codec, int? channels, int? sampleRate, int? bitrate, bool isDefault, bool isForced
});




}
/// @nodoc
class _$AudioTrackCopyWithImpl<$Res>
    implements $AudioTrackCopyWith<$Res> {
  _$AudioTrackCopyWithImpl(this._self, this._then);

  final AudioTrack _self;
  final $Res Function(AudioTrack) _then;

/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? language = freezed,Object? codec = freezed,Object? channels = freezed,Object? sampleRate = freezed,Object? bitrate = freezed,Object? isDefault = null,Object? isForced = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,isForced: null == isForced ? _self.isForced : isForced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioTrack].
extension AudioTrackPatterns on AudioTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioTrack value)  $default,){
final _that = this;
switch (_that) {
case _AudioTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioTrack value)?  $default,){
final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? language,  String? codec,  int? channels,  int? sampleRate,  int? bitrate,  bool isDefault,  bool isForced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
return $default(_that.id,_that.title,_that.language,_that.codec,_that.channels,_that.sampleRate,_that.bitrate,_that.isDefault,_that.isForced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? language,  String? codec,  int? channels,  int? sampleRate,  int? bitrate,  bool isDefault,  bool isForced)  $default,) {final _that = this;
switch (_that) {
case _AudioTrack():
return $default(_that.id,_that.title,_that.language,_that.codec,_that.channels,_that.sampleRate,_that.bitrate,_that.isDefault,_that.isForced);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? language,  String? codec,  int? channels,  int? sampleRate,  int? bitrate,  bool isDefault,  bool isForced)?  $default,) {final _that = this;
switch (_that) {
case _AudioTrack() when $default != null:
return $default(_that.id,_that.title,_that.language,_that.codec,_that.channels,_that.sampleRate,_that.bitrate,_that.isDefault,_that.isForced);case _:
  return null;

}
}

}

/// @nodoc


class _AudioTrack extends AudioTrack {
  const _AudioTrack({required this.id, this.title, this.language, this.codec, this.channels, this.sampleRate, this.bitrate, this.isDefault = false, this.isForced = false}): super._();
  

@override final  String id;
@override final  String? title;
@override final  String? language;
@override final  String? codec;
@override final  int? channels;
@override final  int? sampleRate;
@override final  int? bitrate;
@override@JsonKey() final  bool isDefault;
@override@JsonKey() final  bool isForced;

/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioTrackCopyWith<_AudioTrack> get copyWith => __$AudioTrackCopyWithImpl<_AudioTrack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.channels, channels) || other.channels == channels)&&(identical(other.sampleRate, sampleRate) || other.sampleRate == sampleRate)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.isForced, isForced) || other.isForced == isForced));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,language,codec,channels,sampleRate,bitrate,isDefault,isForced);

@override
String toString() {
  return 'AudioTrack(id: $id, title: $title, language: $language, codec: $codec, channels: $channels, sampleRate: $sampleRate, bitrate: $bitrate, isDefault: $isDefault, isForced: $isForced)';
}


}

/// @nodoc
abstract mixin class _$AudioTrackCopyWith<$Res> implements $AudioTrackCopyWith<$Res> {
  factory _$AudioTrackCopyWith(_AudioTrack value, $Res Function(_AudioTrack) _then) = __$AudioTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? language, String? codec, int? channels, int? sampleRate, int? bitrate, bool isDefault, bool isForced
});




}
/// @nodoc
class __$AudioTrackCopyWithImpl<$Res>
    implements _$AudioTrackCopyWith<$Res> {
  __$AudioTrackCopyWithImpl(this._self, this._then);

  final _AudioTrack _self;
  final $Res Function(_AudioTrack) _then;

/// Create a copy of AudioTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? language = freezed,Object? codec = freezed,Object? channels = freezed,Object? sampleRate = freezed,Object? bitrate = freezed,Object? isDefault = null,Object? isForced = null,}) {
  return _then(_AudioTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,channels: freezed == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as int?,sampleRate: freezed == sampleRate ? _self.sampleRate : sampleRate // ignore: cast_nullable_to_non_nullable
as int?,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,isForced: null == isForced ? _self.isForced : isForced // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$SubtitleTrack {

 String get id; String? get title; String? get language; String? get codec; bool get isDefault; bool get isForced; bool get isExternal; bool get isContainer; String? get uri;
/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<SubtitleTrack> get copyWith => _$SubtitleTrackCopyWithImpl<SubtitleTrack>(this as SubtitleTrack, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.isForced, isForced) || other.isForced == isForced)&&(identical(other.isExternal, isExternal) || other.isExternal == isExternal)&&(identical(other.isContainer, isContainer) || other.isContainer == isContainer)&&(identical(other.uri, uri) || other.uri == uri));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,language,codec,isDefault,isForced,isExternal,isContainer,uri);

@override
String toString() {
  return 'SubtitleTrack(id: $id, title: $title, language: $language, codec: $codec, isDefault: $isDefault, isForced: $isForced, isExternal: $isExternal, isContainer: $isContainer, uri: $uri)';
}


}

/// @nodoc
abstract mixin class $SubtitleTrackCopyWith<$Res>  {
  factory $SubtitleTrackCopyWith(SubtitleTrack value, $Res Function(SubtitleTrack) _then) = _$SubtitleTrackCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? language, String? codec, bool isDefault, bool isForced, bool isExternal, bool isContainer, String? uri
});




}
/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._self, this._then);

  final SubtitleTrack _self;
  final $Res Function(SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? language = freezed,Object? codec = freezed,Object? isDefault = null,Object? isForced = null,Object? isExternal = null,Object? isContainer = null,Object? uri = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,isForced: null == isForced ? _self.isForced : isForced // ignore: cast_nullable_to_non_nullable
as bool,isExternal: null == isExternal ? _self.isExternal : isExternal // ignore: cast_nullable_to_non_nullable
as bool,isContainer: null == isContainer ? _self.isContainer : isContainer // ignore: cast_nullable_to_non_nullable
as bool,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleTrack].
extension SubtitleTrackPatterns on SubtitleTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleTrack value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleTrack value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? language,  String? codec,  bool isDefault,  bool isForced,  bool isExternal,  bool isContainer,  String? uri)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.title,_that.language,_that.codec,_that.isDefault,_that.isForced,_that.isExternal,_that.isContainer,_that.uri);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? language,  String? codec,  bool isDefault,  bool isForced,  bool isExternal,  bool isContainer,  String? uri)  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack():
return $default(_that.id,_that.title,_that.language,_that.codec,_that.isDefault,_that.isForced,_that.isExternal,_that.isContainer,_that.uri);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? language,  String? codec,  bool isDefault,  bool isForced,  bool isExternal,  bool isContainer,  String? uri)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleTrack() when $default != null:
return $default(_that.id,_that.title,_that.language,_that.codec,_that.isDefault,_that.isForced,_that.isExternal,_that.isContainer,_that.uri);case _:
  return null;

}
}

}

/// @nodoc


class _SubtitleTrack extends SubtitleTrack {
  const _SubtitleTrack({required this.id, this.title, this.language, this.codec, this.isDefault = false, this.isForced = false, this.isExternal = false, this.isContainer = false, this.uri}): super._();
  

@override final  String id;
@override final  String? title;
@override final  String? language;
@override final  String? codec;
@override@JsonKey() final  bool isDefault;
@override@JsonKey() final  bool isForced;
@override@JsonKey() final  bool isExternal;
@override@JsonKey() final  bool isContainer;
@override final  String? uri;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleTrackCopyWith<_SubtitleTrack> get copyWith => __$SubtitleTrackCopyWithImpl<_SubtitleTrack>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleTrack&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.language, language) || other.language == language)&&(identical(other.codec, codec) || other.codec == codec)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.isForced, isForced) || other.isForced == isForced)&&(identical(other.isExternal, isExternal) || other.isExternal == isExternal)&&(identical(other.isContainer, isContainer) || other.isContainer == isContainer)&&(identical(other.uri, uri) || other.uri == uri));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,language,codec,isDefault,isForced,isExternal,isContainer,uri);

@override
String toString() {
  return 'SubtitleTrack(id: $id, title: $title, language: $language, codec: $codec, isDefault: $isDefault, isForced: $isForced, isExternal: $isExternal, isContainer: $isContainer, uri: $uri)';
}


}

/// @nodoc
abstract mixin class _$SubtitleTrackCopyWith<$Res> implements $SubtitleTrackCopyWith<$Res> {
  factory _$SubtitleTrackCopyWith(_SubtitleTrack value, $Res Function(_SubtitleTrack) _then) = __$SubtitleTrackCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? language, String? codec, bool isDefault, bool isForced, bool isExternal, bool isContainer, String? uri
});




}
/// @nodoc
class __$SubtitleTrackCopyWithImpl<$Res>
    implements _$SubtitleTrackCopyWith<$Res> {
  __$SubtitleTrackCopyWithImpl(this._self, this._then);

  final _SubtitleTrack _self;
  final $Res Function(_SubtitleTrack) _then;

/// Create a copy of SubtitleTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? language = freezed,Object? codec = freezed,Object? isDefault = null,Object? isForced = null,Object? isExternal = null,Object? isContainer = null,Object? uri = freezed,}) {
  return _then(_SubtitleTrack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,codec: freezed == codec ? _self.codec : codec // ignore: cast_nullable_to_non_nullable
as String?,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,isForced: null == isForced ? _self.isForced : isForced // ignore: cast_nullable_to_non_nullable
as bool,isExternal: null == isExternal ? _self.isExternal : isExternal // ignore: cast_nullable_to_non_nullable
as bool,isContainer: null == isContainer ? _self.isContainer : isContainer // ignore: cast_nullable_to_non_nullable
as bool,uri: freezed == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Tracks {

 List<AudioTrack> get audio; List<SubtitleTrack> get subtitle;
/// Create a copy of Tracks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TracksCopyWith<Tracks> get copyWith => _$TracksCopyWithImpl<Tracks>(this as Tracks, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tracks&&const DeepCollectionEquality().equals(other.audio, audio)&&const DeepCollectionEquality().equals(other.subtitle, subtitle));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(audio),const DeepCollectionEquality().hash(subtitle));



}

/// @nodoc
abstract mixin class $TracksCopyWith<$Res>  {
  factory $TracksCopyWith(Tracks value, $Res Function(Tracks) _then) = _$TracksCopyWithImpl;
@useResult
$Res call({
 List<AudioTrack> audio, List<SubtitleTrack> subtitle
});




}
/// @nodoc
class _$TracksCopyWithImpl<$Res>
    implements $TracksCopyWith<$Res> {
  _$TracksCopyWithImpl(this._self, this._then);

  final Tracks _self;
  final $Res Function(Tracks) _then;

/// Create a copy of Tracks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audio = null,Object? subtitle = null,}) {
  return _then(_self.copyWith(
audio: null == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}

}


/// Adds pattern-matching-related methods to [Tracks].
extension TracksPatterns on Tracks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tracks value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tracks() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tracks value)  $default,){
final _that = this;
switch (_that) {
case _Tracks():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tracks value)?  $default,){
final _that = this;
switch (_that) {
case _Tracks() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AudioTrack> audio,  List<SubtitleTrack> subtitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tracks() when $default != null:
return $default(_that.audio,_that.subtitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AudioTrack> audio,  List<SubtitleTrack> subtitle)  $default,) {final _that = this;
switch (_that) {
case _Tracks():
return $default(_that.audio,_that.subtitle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AudioTrack> audio,  List<SubtitleTrack> subtitle)?  $default,) {final _that = this;
switch (_that) {
case _Tracks() when $default != null:
return $default(_that.audio,_that.subtitle);case _:
  return null;

}
}

}

/// @nodoc


class _Tracks extends Tracks {
  const _Tracks({final  List<AudioTrack> audio = const <AudioTrack>[], final  List<SubtitleTrack> subtitle = const <SubtitleTrack>[]}): _audio = audio,_subtitle = subtitle,super._();
  

 final  List<AudioTrack> _audio;
@override@JsonKey() List<AudioTrack> get audio {
  if (_audio is EqualUnmodifiableListView) return _audio;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_audio);
}

 final  List<SubtitleTrack> _subtitle;
@override@JsonKey() List<SubtitleTrack> get subtitle {
  if (_subtitle is EqualUnmodifiableListView) return _subtitle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtitle);
}


/// Create a copy of Tracks
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TracksCopyWith<_Tracks> get copyWith => __$TracksCopyWithImpl<_Tracks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tracks&&const DeepCollectionEquality().equals(other._audio, _audio)&&const DeepCollectionEquality().equals(other._subtitle, _subtitle));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_audio),const DeepCollectionEquality().hash(_subtitle));



}

/// @nodoc
abstract mixin class _$TracksCopyWith<$Res> implements $TracksCopyWith<$Res> {
  factory _$TracksCopyWith(_Tracks value, $Res Function(_Tracks) _then) = __$TracksCopyWithImpl;
@override @useResult
$Res call({
 List<AudioTrack> audio, List<SubtitleTrack> subtitle
});




}
/// @nodoc
class __$TracksCopyWithImpl<$Res>
    implements _$TracksCopyWith<$Res> {
  __$TracksCopyWithImpl(this._self, this._then);

  final _Tracks _self;
  final $Res Function(_Tracks) _then;

/// Create a copy of Tracks
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audio = null,Object? subtitle = null,}) {
  return _then(_Tracks(
audio: null == audio ? _self._audio : audio // ignore: cast_nullable_to_non_nullable
as List<AudioTrack>,subtitle: null == subtitle ? _self._subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as List<SubtitleTrack>,
  ));
}


}

/// @nodoc
mixin _$TrackSelection {

 AudioTrack? get audio; SubtitleTrack? get subtitle; SubtitleTrack? get secondarySubtitle;
/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackSelectionCopyWith<TrackSelection> get copyWith => _$TrackSelectionCopyWithImpl<TrackSelection>(this as TrackSelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackSelection&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.secondarySubtitle, secondarySubtitle) || other.secondarySubtitle == secondarySubtitle));
}


@override
int get hashCode => Object.hash(runtimeType,audio,subtitle,secondarySubtitle);

@override
String toString() {
  return 'TrackSelection(audio: $audio, subtitle: $subtitle, secondarySubtitle: $secondarySubtitle)';
}


}

/// @nodoc
abstract mixin class $TrackSelectionCopyWith<$Res>  {
  factory $TrackSelectionCopyWith(TrackSelection value, $Res Function(TrackSelection) _then) = _$TrackSelectionCopyWithImpl;
@useResult
$Res call({
 AudioTrack? audio, SubtitleTrack? subtitle, SubtitleTrack? secondarySubtitle
});


$AudioTrackCopyWith<$Res>? get audio;$SubtitleTrackCopyWith<$Res>? get subtitle;$SubtitleTrackCopyWith<$Res>? get secondarySubtitle;

}
/// @nodoc
class _$TrackSelectionCopyWithImpl<$Res>
    implements $TrackSelectionCopyWith<$Res> {
  _$TrackSelectionCopyWithImpl(this._self, this._then);

  final TrackSelection _self;
  final $Res Function(TrackSelection) _then;

/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? audio = freezed,Object? subtitle = freezed,Object? secondarySubtitle = freezed,}) {
  return _then(_self.copyWith(
audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as AudioTrack?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,secondarySubtitle: freezed == secondarySubtitle ? _self.secondarySubtitle : secondarySubtitle // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,
  ));
}
/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioTrackCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $AudioTrackCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get subtitle {
    if (_self.subtitle == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.subtitle!, (value) {
    return _then(_self.copyWith(subtitle: value));
  });
}/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get secondarySubtitle {
    if (_self.secondarySubtitle == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.secondarySubtitle!, (value) {
    return _then(_self.copyWith(secondarySubtitle: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackSelection].
extension TrackSelectionPatterns on TrackSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackSelection value)  $default,){
final _that = this;
switch (_that) {
case _TrackSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackSelection value)?  $default,){
final _that = this;
switch (_that) {
case _TrackSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AudioTrack? audio,  SubtitleTrack? subtitle,  SubtitleTrack? secondarySubtitle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackSelection() when $default != null:
return $default(_that.audio,_that.subtitle,_that.secondarySubtitle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AudioTrack? audio,  SubtitleTrack? subtitle,  SubtitleTrack? secondarySubtitle)  $default,) {final _that = this;
switch (_that) {
case _TrackSelection():
return $default(_that.audio,_that.subtitle,_that.secondarySubtitle);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AudioTrack? audio,  SubtitleTrack? subtitle,  SubtitleTrack? secondarySubtitle)?  $default,) {final _that = this;
switch (_that) {
case _TrackSelection() when $default != null:
return $default(_that.audio,_that.subtitle,_that.secondarySubtitle);case _:
  return null;

}
}

}

/// @nodoc


class _TrackSelection implements TrackSelection {
  const _TrackSelection({this.audio, this.subtitle, this.secondarySubtitle});
  

@override final  AudioTrack? audio;
@override final  SubtitleTrack? subtitle;
@override final  SubtitleTrack? secondarySubtitle;

/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackSelectionCopyWith<_TrackSelection> get copyWith => __$TrackSelectionCopyWithImpl<_TrackSelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackSelection&&(identical(other.audio, audio) || other.audio == audio)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.secondarySubtitle, secondarySubtitle) || other.secondarySubtitle == secondarySubtitle));
}


@override
int get hashCode => Object.hash(runtimeType,audio,subtitle,secondarySubtitle);

@override
String toString() {
  return 'TrackSelection(audio: $audio, subtitle: $subtitle, secondarySubtitle: $secondarySubtitle)';
}


}

/// @nodoc
abstract mixin class _$TrackSelectionCopyWith<$Res> implements $TrackSelectionCopyWith<$Res> {
  factory _$TrackSelectionCopyWith(_TrackSelection value, $Res Function(_TrackSelection) _then) = __$TrackSelectionCopyWithImpl;
@override @useResult
$Res call({
 AudioTrack? audio, SubtitleTrack? subtitle, SubtitleTrack? secondarySubtitle
});


@override $AudioTrackCopyWith<$Res>? get audio;@override $SubtitleTrackCopyWith<$Res>? get subtitle;@override $SubtitleTrackCopyWith<$Res>? get secondarySubtitle;

}
/// @nodoc
class __$TrackSelectionCopyWithImpl<$Res>
    implements _$TrackSelectionCopyWith<$Res> {
  __$TrackSelectionCopyWithImpl(this._self, this._then);

  final _TrackSelection _self;
  final $Res Function(_TrackSelection) _then;

/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? audio = freezed,Object? subtitle = freezed,Object? secondarySubtitle = freezed,}) {
  return _then(_TrackSelection(
audio: freezed == audio ? _self.audio : audio // ignore: cast_nullable_to_non_nullable
as AudioTrack?,subtitle: freezed == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,secondarySubtitle: freezed == secondarySubtitle ? _self.secondarySubtitle : secondarySubtitle // ignore: cast_nullable_to_non_nullable
as SubtitleTrack?,
  ));
}

/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AudioTrackCopyWith<$Res>? get audio {
    if (_self.audio == null) {
    return null;
  }

  return $AudioTrackCopyWith<$Res>(_self.audio!, (value) {
    return _then(_self.copyWith(audio: value));
  });
}/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get subtitle {
    if (_self.subtitle == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.subtitle!, (value) {
    return _then(_self.copyWith(subtitle: value));
  });
}/// Create a copy of TrackSelection
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubtitleTrackCopyWith<$Res>? get secondarySubtitle {
    if (_self.secondarySubtitle == null) {
    return null;
  }

  return $SubtitleTrackCopyWith<$Res>(_self.secondarySubtitle!, (value) {
    return _then(_self.copyWith(secondarySubtitle: value));
  });
}
}

/// @nodoc
mixin _$AudioDevice {

 String get name; String get description;
/// Create a copy of AudioDevice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AudioDeviceCopyWith<AudioDevice> get copyWith => _$AudioDeviceCopyWithImpl<AudioDevice>(this as AudioDevice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AudioDevice&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'AudioDevice(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class $AudioDeviceCopyWith<$Res>  {
  factory $AudioDeviceCopyWith(AudioDevice value, $Res Function(AudioDevice) _then) = _$AudioDeviceCopyWithImpl;
@useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class _$AudioDeviceCopyWithImpl<$Res>
    implements $AudioDeviceCopyWith<$Res> {
  _$AudioDeviceCopyWithImpl(this._self, this._then);

  final AudioDevice _self;
  final $Res Function(AudioDevice) _then;

/// Create a copy of AudioDevice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AudioDevice].
extension AudioDevicePatterns on AudioDevice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AudioDevice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AudioDevice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AudioDevice value)  $default,){
final _that = this;
switch (_that) {
case _AudioDevice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AudioDevice value)?  $default,){
final _that = this;
switch (_that) {
case _AudioDevice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AudioDevice() when $default != null:
return $default(_that.name,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description)  $default,) {final _that = this;
switch (_that) {
case _AudioDevice():
return $default(_that.name,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description)?  $default,) {final _that = this;
switch (_that) {
case _AudioDevice() when $default != null:
return $default(_that.name,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _AudioDevice implements AudioDevice {
  const _AudioDevice({required this.name, this.description = ''});
  

@override final  String name;
@override@JsonKey() final  String description;

/// Create a copy of AudioDevice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AudioDeviceCopyWith<_AudioDevice> get copyWith => __$AudioDeviceCopyWithImpl<_AudioDevice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AudioDevice&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'AudioDevice(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$AudioDeviceCopyWith<$Res> implements $AudioDeviceCopyWith<$Res> {
  factory _$AudioDeviceCopyWith(_AudioDevice value, $Res Function(_AudioDevice) _then) = __$AudioDeviceCopyWithImpl;
@override @useResult
$Res call({
 String name, String description
});




}
/// @nodoc
class __$AudioDeviceCopyWithImpl<$Res>
    implements _$AudioDeviceCopyWith<$Res> {
  __$AudioDeviceCopyWithImpl(this._self, this._then);

  final _AudioDevice _self;
  final $Res Function(_AudioDevice) _then;

/// Create a copy of AudioDevice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,}) {
  return _then(_AudioDevice(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PlayerLog {

 PlayerLogLevel get level; String get prefix; String get text;
/// Create a copy of PlayerLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerLogCopyWith<PlayerLog> get copyWith => _$PlayerLogCopyWithImpl<PlayerLog>(this as PlayerLog, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerLog&&(identical(other.level, level) || other.level == level)&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,level,prefix,text);



}

/// @nodoc
abstract mixin class $PlayerLogCopyWith<$Res>  {
  factory $PlayerLogCopyWith(PlayerLog value, $Res Function(PlayerLog) _then) = _$PlayerLogCopyWithImpl;
@useResult
$Res call({
 PlayerLogLevel level, String prefix, String text
});




}
/// @nodoc
class _$PlayerLogCopyWithImpl<$Res>
    implements $PlayerLogCopyWith<$Res> {
  _$PlayerLogCopyWithImpl(this._self, this._then);

  final PlayerLog _self;
  final $Res Function(PlayerLog) _then;

/// Create a copy of PlayerLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? level = null,Object? prefix = null,Object? text = null,}) {
  return _then(_self.copyWith(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as PlayerLogLevel,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerLog].
extension PlayerLogPatterns on PlayerLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerLog value)  $default,){
final _that = this;
switch (_that) {
case _PlayerLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerLog value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PlayerLogLevel level,  String prefix,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerLog() when $default != null:
return $default(_that.level,_that.prefix,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PlayerLogLevel level,  String prefix,  String text)  $default,) {final _that = this;
switch (_that) {
case _PlayerLog():
return $default(_that.level,_that.prefix,_that.text);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PlayerLogLevel level,  String prefix,  String text)?  $default,) {final _that = this;
switch (_that) {
case _PlayerLog() when $default != null:
return $default(_that.level,_that.prefix,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _PlayerLog extends PlayerLog {
  const _PlayerLog({required this.level, required this.prefix, required this.text}): super._();
  

@override final  PlayerLogLevel level;
@override final  String prefix;
@override final  String text;

/// Create a copy of PlayerLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerLogCopyWith<_PlayerLog> get copyWith => __$PlayerLogCopyWithImpl<_PlayerLog>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerLog&&(identical(other.level, level) || other.level == level)&&(identical(other.prefix, prefix) || other.prefix == prefix)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,level,prefix,text);



}

/// @nodoc
abstract mixin class _$PlayerLogCopyWith<$Res> implements $PlayerLogCopyWith<$Res> {
  factory _$PlayerLogCopyWith(_PlayerLog value, $Res Function(_PlayerLog) _then) = __$PlayerLogCopyWithImpl;
@override @useResult
$Res call({
 PlayerLogLevel level, String prefix, String text
});




}
/// @nodoc
class __$PlayerLogCopyWithImpl<$Res>
    implements _$PlayerLogCopyWith<$Res> {
  __$PlayerLogCopyWithImpl(this._self, this._then);

  final _PlayerLog _self;
  final $Res Function(_PlayerLog) _then;

/// Create a copy of PlayerLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? level = null,Object? prefix = null,Object? text = null,}) {
  return _then(_PlayerLog(
level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as PlayerLogLevel,prefix: null == prefix ? _self.prefix : prefix // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$Media {

 String get uri; Map<String, String>? get headers; Duration? get start;
/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MediaCopyWith<Media> get copyWith => _$MediaCopyWithImpl<Media>(this as Media, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Media&&(identical(other.uri, uri) || other.uri == uri)&&const DeepCollectionEquality().equals(other.headers, headers)&&(identical(other.start, start) || other.start == start));
}


@override
int get hashCode => Object.hash(runtimeType,uri,const DeepCollectionEquality().hash(headers),start);

@override
String toString() {
  return 'Media(uri: $uri, headers: $headers, start: $start)';
}


}

/// @nodoc
abstract mixin class $MediaCopyWith<$Res>  {
  factory $MediaCopyWith(Media value, $Res Function(Media) _then) = _$MediaCopyWithImpl;
@useResult
$Res call({
 String uri, Map<String, String>? headers, Duration? start
});




}
/// @nodoc
class _$MediaCopyWithImpl<$Res>
    implements $MediaCopyWith<$Res> {
  _$MediaCopyWithImpl(this._self, this._then);

  final Media _self;
  final $Res Function(Media) _then;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uri = null,Object? headers = freezed,Object? start = freezed,}) {
  return _then(_self.copyWith(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,headers: freezed == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [Media].
extension MediaPatterns on Media {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Media value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Media() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Media value)  $default,){
final _that = this;
switch (_that) {
case _Media():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Media value)?  $default,){
final _that = this;
switch (_that) {
case _Media() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uri,  Map<String, String>? headers,  Duration? start)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Media() when $default != null:
return $default(_that.uri,_that.headers,_that.start);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uri,  Map<String, String>? headers,  Duration? start)  $default,) {final _that = this;
switch (_that) {
case _Media():
return $default(_that.uri,_that.headers,_that.start);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uri,  Map<String, String>? headers,  Duration? start)?  $default,) {final _that = this;
switch (_that) {
case _Media() when $default != null:
return $default(_that.uri,_that.headers,_that.start);case _:
  return null;

}
}

}

/// @nodoc


class _Media implements Media {
  const _Media(this.uri, {final  Map<String, String>? headers, this.start}): _headers = headers;
  

@override final  String uri;
 final  Map<String, String>? _headers;
@override Map<String, String>? get headers {
  final value = _headers;
  if (value == null) return null;
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  Duration? start;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MediaCopyWith<_Media> get copyWith => __$MediaCopyWithImpl<_Media>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Media&&(identical(other.uri, uri) || other.uri == uri)&&const DeepCollectionEquality().equals(other._headers, _headers)&&(identical(other.start, start) || other.start == start));
}


@override
int get hashCode => Object.hash(runtimeType,uri,const DeepCollectionEquality().hash(_headers),start);

@override
String toString() {
  return 'Media(uri: $uri, headers: $headers, start: $start)';
}


}

/// @nodoc
abstract mixin class _$MediaCopyWith<$Res> implements $MediaCopyWith<$Res> {
  factory _$MediaCopyWith(_Media value, $Res Function(_Media) _then) = __$MediaCopyWithImpl;
@override @useResult
$Res call({
 String uri, Map<String, String>? headers, Duration? start
});




}
/// @nodoc
class __$MediaCopyWithImpl<$Res>
    implements _$MediaCopyWith<$Res> {
  __$MediaCopyWithImpl(this._self, this._then);

  final _Media _self;
  final $Res Function(_Media) _then;

/// Create a copy of Media
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? headers = freezed,Object? start = freezed,}) {
  return _then(_Media(
null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,headers: freezed == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, String>?,start: freezed == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
