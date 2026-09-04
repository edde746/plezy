// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'watch_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Participant {

 String get peerId; String get displayName; bool get isHost; bool get isBuffering;
/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParticipantCopyWith<Participant> get copyWith => _$ParticipantCopyWithImpl<Participant>(this as Participant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Participant&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering));
}


@override
int get hashCode => Object.hash(runtimeType,peerId,displayName,isHost,isBuffering);

@override
String toString() {
  return 'Participant(peerId: $peerId, displayName: $displayName, isHost: $isHost, isBuffering: $isBuffering)';
}


}

/// @nodoc
abstract mixin class $ParticipantCopyWith<$Res>  {
  factory $ParticipantCopyWith(Participant value, $Res Function(Participant) _then) = _$ParticipantCopyWithImpl;
@useResult
$Res call({
 String peerId, String displayName, bool isHost, bool isBuffering
});




}
/// @nodoc
class _$ParticipantCopyWithImpl<$Res>
    implements $ParticipantCopyWith<$Res> {
  _$ParticipantCopyWithImpl(this._self, this._then);

  final Participant _self;
  final $Res Function(Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? peerId = null,Object? displayName = null,Object? isHost = null,Object? isBuffering = null,}) {
  return _then(_self.copyWith(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Participant].
extension ParticipantPatterns on Participant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Participant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Participant value)  $default,){
final _that = this;
switch (_that) {
case _Participant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Participant value)?  $default,){
final _that = this;
switch (_that) {
case _Participant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String peerId,  String displayName,  bool isHost,  bool isBuffering)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.peerId,_that.displayName,_that.isHost,_that.isBuffering);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String peerId,  String displayName,  bool isHost,  bool isBuffering)  $default,) {final _that = this;
switch (_that) {
case _Participant():
return $default(_that.peerId,_that.displayName,_that.isHost,_that.isBuffering);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String peerId,  String displayName,  bool isHost,  bool isBuffering)?  $default,) {final _that = this;
switch (_that) {
case _Participant() when $default != null:
return $default(_that.peerId,_that.displayName,_that.isHost,_that.isBuffering);case _:
  return null;

}
}

}

/// @nodoc


class _Participant implements Participant {
  const _Participant({required this.peerId, required this.displayName, required this.isHost, this.isBuffering = false});
  

@override final  String peerId;
@override final  String displayName;
@override final  bool isHost;
@override@JsonKey() final  bool isBuffering;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParticipantCopyWith<_Participant> get copyWith => __$ParticipantCopyWithImpl<_Participant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Participant&&(identical(other.peerId, peerId) || other.peerId == peerId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isHost, isHost) || other.isHost == isHost)&&(identical(other.isBuffering, isBuffering) || other.isBuffering == isBuffering));
}


@override
int get hashCode => Object.hash(runtimeType,peerId,displayName,isHost,isBuffering);

@override
String toString() {
  return 'Participant(peerId: $peerId, displayName: $displayName, isHost: $isHost, isBuffering: $isBuffering)';
}


}

/// @nodoc
abstract mixin class _$ParticipantCopyWith<$Res> implements $ParticipantCopyWith<$Res> {
  factory _$ParticipantCopyWith(_Participant value, $Res Function(_Participant) _then) = __$ParticipantCopyWithImpl;
@override @useResult
$Res call({
 String peerId, String displayName, bool isHost, bool isBuffering
});




}
/// @nodoc
class __$ParticipantCopyWithImpl<$Res>
    implements _$ParticipantCopyWith<$Res> {
  __$ParticipantCopyWithImpl(this._self, this._then);

  final _Participant _self;
  final $Res Function(_Participant) _then;

/// Create a copy of Participant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? peerId = null,Object? displayName = null,Object? isHost = null,Object? isBuffering = null,}) {
  return _then(_Participant(
peerId: null == peerId ? _self.peerId : peerId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isHost: null == isHost ? _self.isHost : isHost // ignore: cast_nullable_to_non_nullable
as bool,isBuffering: null == isBuffering ? _self.isBuffering : isBuffering // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$WatchSession {

 String get sessionId; SessionRole get role; ControlMode get controlMode; SessionState get state; String? get errorMessage; String? get mediaRatingKey; String? get mediaServerId; String? get mediaTitle; String? get hostPeerId;
/// Create a copy of WatchSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WatchSessionCopyWith<WatchSession> get copyWith => _$WatchSessionCopyWithImpl<WatchSession>(this as WatchSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WatchSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.role, role) || other.role == role)&&(identical(other.controlMode, controlMode) || other.controlMode == controlMode)&&(identical(other.state, state) || other.state == state)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.mediaRatingKey, mediaRatingKey) || other.mediaRatingKey == mediaRatingKey)&&(identical(other.mediaServerId, mediaServerId) || other.mediaServerId == mediaServerId)&&(identical(other.mediaTitle, mediaTitle) || other.mediaTitle == mediaTitle)&&(identical(other.hostPeerId, hostPeerId) || other.hostPeerId == hostPeerId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,role,controlMode,state,errorMessage,mediaRatingKey,mediaServerId,mediaTitle,hostPeerId);

@override
String toString() {
  return 'WatchSession(sessionId: $sessionId, role: $role, controlMode: $controlMode, state: $state, errorMessage: $errorMessage, mediaRatingKey: $mediaRatingKey, mediaServerId: $mediaServerId, mediaTitle: $mediaTitle, hostPeerId: $hostPeerId)';
}


}

/// @nodoc
abstract mixin class $WatchSessionCopyWith<$Res>  {
  factory $WatchSessionCopyWith(WatchSession value, $Res Function(WatchSession) _then) = _$WatchSessionCopyWithImpl;
@useResult
$Res call({
 String sessionId, SessionRole role, ControlMode controlMode, SessionState state, String? errorMessage, String? mediaRatingKey, String? mediaServerId, String? mediaTitle, String? hostPeerId
});




}
/// @nodoc
class _$WatchSessionCopyWithImpl<$Res>
    implements $WatchSessionCopyWith<$Res> {
  _$WatchSessionCopyWithImpl(this._self, this._then);

  final WatchSession _self;
  final $Res Function(WatchSession) _then;

/// Create a copy of WatchSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? role = null,Object? controlMode = null,Object? state = null,Object? errorMessage = freezed,Object? mediaRatingKey = freezed,Object? mediaServerId = freezed,Object? mediaTitle = freezed,Object? hostPeerId = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SessionRole,controlMode: null == controlMode ? _self.controlMode : controlMode // ignore: cast_nullable_to_non_nullable
as ControlMode,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SessionState,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,mediaRatingKey: freezed == mediaRatingKey ? _self.mediaRatingKey : mediaRatingKey // ignore: cast_nullable_to_non_nullable
as String?,mediaServerId: freezed == mediaServerId ? _self.mediaServerId : mediaServerId // ignore: cast_nullable_to_non_nullable
as String?,mediaTitle: freezed == mediaTitle ? _self.mediaTitle : mediaTitle // ignore: cast_nullable_to_non_nullable
as String?,hostPeerId: freezed == hostPeerId ? _self.hostPeerId : hostPeerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WatchSession].
extension WatchSessionPatterns on WatchSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WatchSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WatchSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WatchSession value)  $default,){
final _that = this;
switch (_that) {
case _WatchSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WatchSession value)?  $default,){
final _that = this;
switch (_that) {
case _WatchSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sessionId,  SessionRole role,  ControlMode controlMode,  SessionState state,  String? errorMessage,  String? mediaRatingKey,  String? mediaServerId,  String? mediaTitle,  String? hostPeerId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WatchSession() when $default != null:
return $default(_that.sessionId,_that.role,_that.controlMode,_that.state,_that.errorMessage,_that.mediaRatingKey,_that.mediaServerId,_that.mediaTitle,_that.hostPeerId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sessionId,  SessionRole role,  ControlMode controlMode,  SessionState state,  String? errorMessage,  String? mediaRatingKey,  String? mediaServerId,  String? mediaTitle,  String? hostPeerId)  $default,) {final _that = this;
switch (_that) {
case _WatchSession():
return $default(_that.sessionId,_that.role,_that.controlMode,_that.state,_that.errorMessage,_that.mediaRatingKey,_that.mediaServerId,_that.mediaTitle,_that.hostPeerId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sessionId,  SessionRole role,  ControlMode controlMode,  SessionState state,  String? errorMessage,  String? mediaRatingKey,  String? mediaServerId,  String? mediaTitle,  String? hostPeerId)?  $default,) {final _that = this;
switch (_that) {
case _WatchSession() when $default != null:
return $default(_that.sessionId,_that.role,_that.controlMode,_that.state,_that.errorMessage,_that.mediaRatingKey,_that.mediaServerId,_that.mediaTitle,_that.hostPeerId);case _:
  return null;

}
}

}

/// @nodoc


class _WatchSession extends WatchSession {
  const _WatchSession({required this.sessionId, required this.role, required this.controlMode, required this.state, this.errorMessage, this.mediaRatingKey, this.mediaServerId, this.mediaTitle, this.hostPeerId}): super._();
  

@override final  String sessionId;
@override final  SessionRole role;
@override final  ControlMode controlMode;
@override final  SessionState state;
@override final  String? errorMessage;
@override final  String? mediaRatingKey;
@override final  String? mediaServerId;
@override final  String? mediaTitle;
@override final  String? hostPeerId;

/// Create a copy of WatchSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WatchSessionCopyWith<_WatchSession> get copyWith => __$WatchSessionCopyWithImpl<_WatchSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WatchSession&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.role, role) || other.role == role)&&(identical(other.controlMode, controlMode) || other.controlMode == controlMode)&&(identical(other.state, state) || other.state == state)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.mediaRatingKey, mediaRatingKey) || other.mediaRatingKey == mediaRatingKey)&&(identical(other.mediaServerId, mediaServerId) || other.mediaServerId == mediaServerId)&&(identical(other.mediaTitle, mediaTitle) || other.mediaTitle == mediaTitle)&&(identical(other.hostPeerId, hostPeerId) || other.hostPeerId == hostPeerId));
}


@override
int get hashCode => Object.hash(runtimeType,sessionId,role,controlMode,state,errorMessage,mediaRatingKey,mediaServerId,mediaTitle,hostPeerId);

@override
String toString() {
  return 'WatchSession(sessionId: $sessionId, role: $role, controlMode: $controlMode, state: $state, errorMessage: $errorMessage, mediaRatingKey: $mediaRatingKey, mediaServerId: $mediaServerId, mediaTitle: $mediaTitle, hostPeerId: $hostPeerId)';
}


}

/// @nodoc
abstract mixin class _$WatchSessionCopyWith<$Res> implements $WatchSessionCopyWith<$Res> {
  factory _$WatchSessionCopyWith(_WatchSession value, $Res Function(_WatchSession) _then) = __$WatchSessionCopyWithImpl;
@override @useResult
$Res call({
 String sessionId, SessionRole role, ControlMode controlMode, SessionState state, String? errorMessage, String? mediaRatingKey, String? mediaServerId, String? mediaTitle, String? hostPeerId
});




}
/// @nodoc
class __$WatchSessionCopyWithImpl<$Res>
    implements _$WatchSessionCopyWith<$Res> {
  __$WatchSessionCopyWithImpl(this._self, this._then);

  final _WatchSession _self;
  final $Res Function(_WatchSession) _then;

/// Create a copy of WatchSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? role = null,Object? controlMode = null,Object? state = null,Object? errorMessage = freezed,Object? mediaRatingKey = freezed,Object? mediaServerId = freezed,Object? mediaTitle = freezed,Object? hostPeerId = freezed,}) {
  return _then(_WatchSession(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as SessionRole,controlMode: null == controlMode ? _self.controlMode : controlMode // ignore: cast_nullable_to_non_nullable
as ControlMode,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as SessionState,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,mediaRatingKey: freezed == mediaRatingKey ? _self.mediaRatingKey : mediaRatingKey // ignore: cast_nullable_to_non_nullable
as String?,mediaServerId: freezed == mediaServerId ? _self.mediaServerId : mediaServerId // ignore: cast_nullable_to_non_nullable
as String?,mediaTitle: freezed == mediaTitle ? _self.mediaTitle : mediaTitle // ignore: cast_nullable_to_non_nullable
as String?,hostPeerId: freezed == hostPeerId ? _self.hostPeerId : hostPeerId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
