// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeviceCode {

 String get deviceCode; String get userCode; String get verificationUrl; int get expiresIn; int get interval;/// URL with the code pre-filled (e.g. `https://simkl.com/pin?user_code=BDWP-HQPK`)
/// when the provider supports it. Null when the provider sends none and
/// none can be built, leaving the user to enter the code by hand.
 String? get verificationUrlComplete;
/// Create a copy of DeviceCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceCodeCopyWith<DeviceCode> get copyWith => _$DeviceCodeCopyWithImpl<DeviceCode>(this as DeviceCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.verificationUrlComplete, verificationUrlComplete) || other.verificationUrlComplete == verificationUrlComplete));
}


@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval,verificationUrlComplete);

@override
String toString() {
  return 'DeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval, verificationUrlComplete: $verificationUrlComplete)';
}


}

/// @nodoc
abstract mixin class $DeviceCodeCopyWith<$Res>  {
  factory $DeviceCodeCopyWith(DeviceCode value, $Res Function(DeviceCode) _then) = _$DeviceCodeCopyWithImpl;
@useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval, String? verificationUrlComplete
});




}
/// @nodoc
class _$DeviceCodeCopyWithImpl<$Res>
    implements $DeviceCodeCopyWith<$Res> {
  _$DeviceCodeCopyWithImpl(this._self, this._then);

  final DeviceCode _self;
  final $Res Function(DeviceCode) _then;

/// Create a copy of DeviceCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,Object? verificationUrlComplete = freezed,}) {
  return _then(_self.copyWith(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,verificationUrlComplete: freezed == verificationUrlComplete ? _self.verificationUrlComplete : verificationUrlComplete // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceCode].
extension DeviceCodePatterns on DeviceCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceCode value)  $default,){
final _that = this;
switch (_that) {
case _DeviceCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceCode value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval,  String? verificationUrlComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval,_that.verificationUrlComplete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval,  String? verificationUrlComplete)  $default,) {final _that = this;
switch (_that) {
case _DeviceCode():
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval,_that.verificationUrlComplete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval,  String? verificationUrlComplete)?  $default,) {final _that = this;
switch (_that) {
case _DeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval,_that.verificationUrlComplete);case _:
  return null;

}
}

}

/// @nodoc


class _DeviceCode implements DeviceCode {
  const _DeviceCode({required this.deviceCode, required this.userCode, required this.verificationUrl, required this.expiresIn, required this.interval, this.verificationUrlComplete});
  

@override final  String deviceCode;
@override final  String userCode;
@override final  String verificationUrl;
@override final  int expiresIn;
@override final  int interval;
/// URL with the code pre-filled (e.g. `https://simkl.com/pin?user_code=BDWP-HQPK`)
/// when the provider supports it. Null when the provider sends none and
/// none can be built, leaving the user to enter the code by hand.
@override final  String? verificationUrlComplete;

/// Create a copy of DeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceCodeCopyWith<_DeviceCode> get copyWith => __$DeviceCodeCopyWithImpl<_DeviceCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval)&&(identical(other.verificationUrlComplete, verificationUrlComplete) || other.verificationUrlComplete == verificationUrlComplete));
}


@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval,verificationUrlComplete);

@override
String toString() {
  return 'DeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval, verificationUrlComplete: $verificationUrlComplete)';
}


}

/// @nodoc
abstract mixin class _$DeviceCodeCopyWith<$Res> implements $DeviceCodeCopyWith<$Res> {
  factory _$DeviceCodeCopyWith(_DeviceCode value, $Res Function(_DeviceCode) _then) = __$DeviceCodeCopyWithImpl;
@override @useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval, String? verificationUrlComplete
});




}
/// @nodoc
class __$DeviceCodeCopyWithImpl<$Res>
    implements _$DeviceCodeCopyWith<$Res> {
  __$DeviceCodeCopyWithImpl(this._self, this._then);

  final _DeviceCode _self;
  final $Res Function(_DeviceCode) _then;

/// Create a copy of DeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,Object? verificationUrlComplete = freezed,}) {
  return _then(_DeviceCode(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,verificationUrlComplete: freezed == verificationUrlComplete ? _self.verificationUrlComplete : verificationUrlComplete // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$DevicePollEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DevicePollEvent()';
}


}

/// @nodoc
class $DevicePollEventCopyWith<$Res>  {
$DevicePollEventCopyWith(DevicePollEvent _, $Res Function(DevicePollEvent) __);
}


/// Adds pattern-matching-related methods to [DevicePollEvent].
extension DevicePollEventPatterns on DevicePollEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DevicePollPending value)?  pending,TResult Function( DevicePollSlowDown value)?  slowDown,TResult Function( DevicePollDenied value)?  denied,TResult Function( DevicePollExpired value)?  expired,TResult Function( DevicePollSuccess value)?  success,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DevicePollPending() when pending != null:
return pending(_that);case DevicePollSlowDown() when slowDown != null:
return slowDown(_that);case DevicePollDenied() when denied != null:
return denied(_that);case DevicePollExpired() when expired != null:
return expired(_that);case DevicePollSuccess() when success != null:
return success(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DevicePollPending value)  pending,required TResult Function( DevicePollSlowDown value)  slowDown,required TResult Function( DevicePollDenied value)  denied,required TResult Function( DevicePollExpired value)  expired,required TResult Function( DevicePollSuccess value)  success,}){
final _that = this;
switch (_that) {
case DevicePollPending():
return pending(_that);case DevicePollSlowDown():
return slowDown(_that);case DevicePollDenied():
return denied(_that);case DevicePollExpired():
return expired(_that);case DevicePollSuccess():
return success(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DevicePollPending value)?  pending,TResult? Function( DevicePollSlowDown value)?  slowDown,TResult? Function( DevicePollDenied value)?  denied,TResult? Function( DevicePollExpired value)?  expired,TResult? Function( DevicePollSuccess value)?  success,}){
final _that = this;
switch (_that) {
case DevicePollPending() when pending != null:
return pending(_that);case DevicePollSlowDown() when slowDown != null:
return slowDown(_that);case DevicePollDenied() when denied != null:
return denied(_that);case DevicePollExpired() when expired != null:
return expired(_that);case DevicePollSuccess() when success != null:
return success(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  pending,TResult Function()?  slowDown,TResult Function()?  denied,TResult Function()?  expired,TResult Function( Map<String, dynamic> tokenResponse)?  success,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DevicePollPending() when pending != null:
return pending();case DevicePollSlowDown() when slowDown != null:
return slowDown();case DevicePollDenied() when denied != null:
return denied();case DevicePollExpired() when expired != null:
return expired();case DevicePollSuccess() when success != null:
return success(_that.tokenResponse);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  pending,required TResult Function()  slowDown,required TResult Function()  denied,required TResult Function()  expired,required TResult Function( Map<String, dynamic> tokenResponse)  success,}) {final _that = this;
switch (_that) {
case DevicePollPending():
return pending();case DevicePollSlowDown():
return slowDown();case DevicePollDenied():
return denied();case DevicePollExpired():
return expired();case DevicePollSuccess():
return success(_that.tokenResponse);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  pending,TResult? Function()?  slowDown,TResult? Function()?  denied,TResult? Function()?  expired,TResult? Function( Map<String, dynamic> tokenResponse)?  success,}) {final _that = this;
switch (_that) {
case DevicePollPending() when pending != null:
return pending();case DevicePollSlowDown() when slowDown != null:
return slowDown();case DevicePollDenied() when denied != null:
return denied();case DevicePollExpired() when expired != null:
return expired();case DevicePollSuccess() when success != null:
return success(_that.tokenResponse);case _:
  return null;

}
}

}

/// @nodoc


class DevicePollPending implements DevicePollEvent {
  const DevicePollPending();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollPending);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DevicePollEvent.pending()';
}


}

/// @nodoc
class $DevicePollPendingCopyWith<$Res> implements $DevicePollEventCopyWith<$Res> {
$DevicePollPendingCopyWith(DevicePollPending _, $Res Function(DevicePollPending) __);
}
/// @nodoc
class _$DevicePollPendingCopyWithImpl<$Res>
    implements $DevicePollPendingCopyWith<$Res> {
  _$DevicePollPendingCopyWithImpl(this._self, this._then);

  final DevicePollPending _self;
  final $Res Function(DevicePollPending) _then;




}

/// @nodoc


class DevicePollSlowDown implements DevicePollEvent {
  const DevicePollSlowDown();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollSlowDown);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DevicePollEvent.slowDown()';
}


}

/// @nodoc
class $DevicePollSlowDownCopyWith<$Res> implements $DevicePollEventCopyWith<$Res> {
$DevicePollSlowDownCopyWith(DevicePollSlowDown _, $Res Function(DevicePollSlowDown) __);
}
/// @nodoc
class _$DevicePollSlowDownCopyWithImpl<$Res>
    implements $DevicePollSlowDownCopyWith<$Res> {
  _$DevicePollSlowDownCopyWithImpl(this._self, this._then);

  final DevicePollSlowDown _self;
  final $Res Function(DevicePollSlowDown) _then;




}

/// @nodoc


class DevicePollDenied implements DevicePollEvent {
  const DevicePollDenied();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollDenied);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DevicePollEvent.denied()';
}


}

/// @nodoc
class $DevicePollDeniedCopyWith<$Res> implements $DevicePollEventCopyWith<$Res> {
$DevicePollDeniedCopyWith(DevicePollDenied _, $Res Function(DevicePollDenied) __);
}
/// @nodoc
class _$DevicePollDeniedCopyWithImpl<$Res>
    implements $DevicePollDeniedCopyWith<$Res> {
  _$DevicePollDeniedCopyWithImpl(this._self, this._then);

  final DevicePollDenied _self;
  final $Res Function(DevicePollDenied) _then;




}

/// @nodoc


class DevicePollExpired implements DevicePollEvent {
  const DevicePollExpired();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollExpired);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DevicePollEvent.expired()';
}


}

/// @nodoc
class $DevicePollExpiredCopyWith<$Res> implements $DevicePollEventCopyWith<$Res> {
$DevicePollExpiredCopyWith(DevicePollExpired _, $Res Function(DevicePollExpired) __);
}
/// @nodoc
class _$DevicePollExpiredCopyWithImpl<$Res>
    implements $DevicePollExpiredCopyWith<$Res> {
  _$DevicePollExpiredCopyWithImpl(this._self, this._then);

  final DevicePollExpired _self;
  final $Res Function(DevicePollExpired) _then;




}

/// @nodoc


class DevicePollSuccess implements DevicePollEvent {
  const DevicePollSuccess(final  Map<String, dynamic> tokenResponse): _tokenResponse = tokenResponse;
  

 final  Map<String, dynamic> _tokenResponse;
 Map<String, dynamic> get tokenResponse {
  if (_tokenResponse is EqualUnmodifiableMapView) return _tokenResponse;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tokenResponse);
}


/// Create a copy of DevicePollEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DevicePollSuccessCopyWith<DevicePollSuccess> get copyWith => _$DevicePollSuccessCopyWithImpl<DevicePollSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DevicePollSuccess&&const DeepCollectionEquality().equals(other._tokenResponse, _tokenResponse));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tokenResponse));

@override
String toString() {
  return 'DevicePollEvent.success(tokenResponse: $tokenResponse)';
}


}

/// @nodoc
abstract mixin class $DevicePollSuccessCopyWith<$Res> implements $DevicePollEventCopyWith<$Res> {
  factory $DevicePollSuccessCopyWith(DevicePollSuccess value, $Res Function(DevicePollSuccess) _then) = _$DevicePollSuccessCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> tokenResponse
});




}
/// @nodoc
class _$DevicePollSuccessCopyWithImpl<$Res>
    implements $DevicePollSuccessCopyWith<$Res> {
  _$DevicePollSuccessCopyWithImpl(this._self, this._then);

  final DevicePollSuccess _self;
  final $Res Function(DevicePollSuccess) _then;

/// Create a copy of DevicePollEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tokenResponse = null,}) {
  return _then(DevicePollSuccess(
null == tokenResponse ? _self._tokenResponse : tokenResponse // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
