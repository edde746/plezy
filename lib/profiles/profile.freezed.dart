// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Profile {

 String get id; String get displayName; String? get avatarThumbUrl; int get sortOrder; DateTime get createdAt; DateTime? get lastUsedAt;
/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfileCopyWith<Profile> get copyWith => _$ProfileCopyWithImpl<Profile>(this as Profile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarThumbUrl, avatarThumbUrl) || other.avatarThumbUrl == avatarThumbUrl)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarThumbUrl,sortOrder,createdAt,lastUsedAt);

@override
String toString() {
  return 'Profile(id: $id, displayName: $displayName, avatarThumbUrl: $avatarThumbUrl, sortOrder: $sortOrder, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $ProfileCopyWith<$Res>  {
  factory $ProfileCopyWith(Profile value, $Res Function(Profile) _then) = _$ProfileCopyWithImpl;
@useResult
$Res call({
 String id, String displayName, String? avatarThumbUrl, int sortOrder, DateTime createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class _$ProfileCopyWithImpl<$Res>
    implements $ProfileCopyWith<$Res> {
  _$ProfileCopyWithImpl(this._self, this._then);

  final Profile _self;
  final $Res Function(Profile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? avatarThumbUrl = freezed,Object? sortOrder = null,Object? createdAt = null,Object? lastUsedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarThumbUrl: freezed == avatarThumbUrl ? _self.avatarThumbUrl : avatarThumbUrl // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Profile].
extension ProfilePatterns on Profile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LocalProfile value)?  local,TResult Function( PlexHomeProfile value)?  plexHome,TResult Function( JellyfinBonfireProfile value)?  jellyfinBonfire,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LocalProfile() when local != null:
return local(_that);case PlexHomeProfile() when plexHome != null:
return plexHome(_that);case JellyfinBonfireProfile() when jellyfinBonfire != null:
return jellyfinBonfire(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LocalProfile value)  local,required TResult Function( PlexHomeProfile value)  plexHome,required TResult Function( JellyfinBonfireProfile value)  jellyfinBonfire,}){
final _that = this;
switch (_that) {
case LocalProfile():
return local(_that);case PlexHomeProfile():
return plexHome(_that);case JellyfinBonfireProfile():
return jellyfinBonfire(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LocalProfile value)?  local,TResult? Function( PlexHomeProfile value)?  plexHome,TResult? Function( JellyfinBonfireProfile value)?  jellyfinBonfire,}){
final _that = this;
switch (_that) {
case LocalProfile() when local != null:
return local(_that);case PlexHomeProfile() when plexHome != null:
return plexHome(_that);case JellyfinBonfireProfile() when jellyfinBonfire != null:
return jellyfinBonfire(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? pinHash,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  local,TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? plexHomeUserUuid,  bool plexRestricted,  bool plexAdmin,  bool plexProtected,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  plexHome,TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? bonfireUserId,  bool bonfireIsMaster,  bool bonfireIsAdministrator,  bool bonfireRequiresPin,  bool bonfireHasPin,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  jellyfinBonfire,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LocalProfile() when local != null:
return local(_that.id,_that.displayName,_that.avatarThumbUrl,_that.pinHash,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case PlexHomeProfile() when plexHome != null:
return plexHome(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.plexHomeUserUuid,_that.plexRestricted,_that.plexAdmin,_that.plexProtected,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case JellyfinBonfireProfile() when jellyfinBonfire != null:
return jellyfinBonfire(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.bonfireUserId,_that.bonfireIsMaster,_that.bonfireIsAdministrator,_that.bonfireRequiresPin,_that.bonfireHasPin,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? pinHash,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)  local,required TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? plexHomeUserUuid,  bool plexRestricted,  bool plexAdmin,  bool plexProtected,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)  plexHome,required TResult Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? bonfireUserId,  bool bonfireIsMaster,  bool bonfireIsAdministrator,  bool bonfireRequiresPin,  bool bonfireHasPin,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)  jellyfinBonfire,}) {final _that = this;
switch (_that) {
case LocalProfile():
return local(_that.id,_that.displayName,_that.avatarThumbUrl,_that.pinHash,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case PlexHomeProfile():
return plexHome(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.plexHomeUserUuid,_that.plexRestricted,_that.plexAdmin,_that.plexProtected,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case JellyfinBonfireProfile():
return jellyfinBonfire(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.bonfireUserId,_that.bonfireIsMaster,_that.bonfireIsAdministrator,_that.bonfireRequiresPin,_that.bonfireHasPin,_that.sortOrder,_that.createdAt,_that.lastUsedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String displayName,  String? avatarThumbUrl,  String? pinHash,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  local,TResult? Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? plexHomeUserUuid,  bool plexRestricted,  bool plexAdmin,  bool plexProtected,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  plexHome,TResult? Function( String id,  String displayName,  String? avatarThumbUrl,  String? parentConnectionId,  String? bonfireUserId,  bool bonfireIsMaster,  bool bonfireIsAdministrator,  bool bonfireRequiresPin,  bool bonfireHasPin,  int sortOrder,  DateTime createdAt,  DateTime? lastUsedAt)?  jellyfinBonfire,}) {final _that = this;
switch (_that) {
case LocalProfile() when local != null:
return local(_that.id,_that.displayName,_that.avatarThumbUrl,_that.pinHash,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case PlexHomeProfile() when plexHome != null:
return plexHome(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.plexHomeUserUuid,_that.plexRestricted,_that.plexAdmin,_that.plexProtected,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case JellyfinBonfireProfile() when jellyfinBonfire != null:
return jellyfinBonfire(_that.id,_that.displayName,_that.avatarThumbUrl,_that.parentConnectionId,_that.bonfireUserId,_that.bonfireIsMaster,_that.bonfireIsAdministrator,_that.bonfireRequiresPin,_that.bonfireHasPin,_that.sortOrder,_that.createdAt,_that.lastUsedAt);case _:
  return null;

}
}

}

/// @nodoc


class LocalProfile extends Profile {
  const LocalProfile({required this.id, required this.displayName, this.avatarThumbUrl, this.pinHash, this.sortOrder = 0, required this.createdAt, this.lastUsedAt}): super._();
  

@override final  String id;
@override final  String displayName;
@override final  String? avatarThumbUrl;
/// Hashed PIN if set. The raw PIN is never persisted; see [computePinHash].
 final  String? pinHash;
@override@JsonKey() final  int sortOrder;
@override final  DateTime createdAt;
@override final  DateTime? lastUsedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocalProfileCopyWith<LocalProfile> get copyWith => _$LocalProfileCopyWithImpl<LocalProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocalProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarThumbUrl, avatarThumbUrl) || other.avatarThumbUrl == avatarThumbUrl)&&(identical(other.pinHash, pinHash) || other.pinHash == pinHash)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarThumbUrl,pinHash,sortOrder,createdAt,lastUsedAt);

@override
String toString() {
  return 'Profile.local(id: $id, displayName: $displayName, avatarThumbUrl: $avatarThumbUrl, pinHash: $pinHash, sortOrder: $sortOrder, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $LocalProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory $LocalProfileCopyWith(LocalProfile value, $Res Function(LocalProfile) _then) = _$LocalProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarThumbUrl, String? pinHash, int sortOrder, DateTime createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class _$LocalProfileCopyWithImpl<$Res>
    implements $LocalProfileCopyWith<$Res> {
  _$LocalProfileCopyWithImpl(this._self, this._then);

  final LocalProfile _self;
  final $Res Function(LocalProfile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarThumbUrl = freezed,Object? pinHash = freezed,Object? sortOrder = null,Object? createdAt = null,Object? lastUsedAt = freezed,}) {
  return _then(LocalProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarThumbUrl: freezed == avatarThumbUrl ? _self.avatarThumbUrl : avatarThumbUrl // ignore: cast_nullable_to_non_nullable
as String?,pinHash: freezed == pinHash ? _self.pinHash : pinHash // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class PlexHomeProfile extends Profile {
  const PlexHomeProfile({required this.id, required this.displayName, this.avatarThumbUrl, this.parentConnectionId, this.plexHomeUserUuid, this.plexRestricted = false, this.plexAdmin = false, this.plexProtected = false, this.sortOrder = 0, required this.createdAt, this.lastUsedAt}): super._();
  

@override final  String id;
@override final  String displayName;
@override final  String? avatarThumbUrl;
/// The parent Plex account's connection id.
 final  String? parentConnectionId;
/// The Plex Home user UUID. Used by the active-profile binder to call
/// `/home/users/{uuid}/switch`.
 final  String? plexHomeUserUuid;
@JsonKey() final  bool plexRestricted;
@JsonKey() final  bool plexAdmin;
/// Plex's `protected` flag — true when the home user has a PIN that must
/// be entered before `/home/users/{uuid}/switch` will succeed.
@JsonKey() final  bool plexProtected;
@override@JsonKey() final  int sortOrder;
@override final  DateTime createdAt;
@override final  DateTime? lastUsedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlexHomeProfileCopyWith<PlexHomeProfile> get copyWith => _$PlexHomeProfileCopyWithImpl<PlexHomeProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlexHomeProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarThumbUrl, avatarThumbUrl) || other.avatarThumbUrl == avatarThumbUrl)&&(identical(other.parentConnectionId, parentConnectionId) || other.parentConnectionId == parentConnectionId)&&(identical(other.plexHomeUserUuid, plexHomeUserUuid) || other.plexHomeUserUuid == plexHomeUserUuid)&&(identical(other.plexRestricted, plexRestricted) || other.plexRestricted == plexRestricted)&&(identical(other.plexAdmin, plexAdmin) || other.plexAdmin == plexAdmin)&&(identical(other.plexProtected, plexProtected) || other.plexProtected == plexProtected)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarThumbUrl,parentConnectionId,plexHomeUserUuid,plexRestricted,plexAdmin,plexProtected,sortOrder,createdAt,lastUsedAt);

@override
String toString() {
  return 'Profile.plexHome(id: $id, displayName: $displayName, avatarThumbUrl: $avatarThumbUrl, parentConnectionId: $parentConnectionId, plexHomeUserUuid: $plexHomeUserUuid, plexRestricted: $plexRestricted, plexAdmin: $plexAdmin, plexProtected: $plexProtected, sortOrder: $sortOrder, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $PlexHomeProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory $PlexHomeProfileCopyWith(PlexHomeProfile value, $Res Function(PlexHomeProfile) _then) = _$PlexHomeProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarThumbUrl, String? parentConnectionId, String? plexHomeUserUuid, bool plexRestricted, bool plexAdmin, bool plexProtected, int sortOrder, DateTime createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class _$PlexHomeProfileCopyWithImpl<$Res>
    implements $PlexHomeProfileCopyWith<$Res> {
  _$PlexHomeProfileCopyWithImpl(this._self, this._then);

  final PlexHomeProfile _self;
  final $Res Function(PlexHomeProfile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarThumbUrl = freezed,Object? parentConnectionId = freezed,Object? plexHomeUserUuid = freezed,Object? plexRestricted = null,Object? plexAdmin = null,Object? plexProtected = null,Object? sortOrder = null,Object? createdAt = null,Object? lastUsedAt = freezed,}) {
  return _then(PlexHomeProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarThumbUrl: freezed == avatarThumbUrl ? _self.avatarThumbUrl : avatarThumbUrl // ignore: cast_nullable_to_non_nullable
as String?,parentConnectionId: freezed == parentConnectionId ? _self.parentConnectionId : parentConnectionId // ignore: cast_nullable_to_non_nullable
as String?,plexHomeUserUuid: freezed == plexHomeUserUuid ? _self.plexHomeUserUuid : plexHomeUserUuid // ignore: cast_nullable_to_non_nullable
as String?,plexRestricted: null == plexRestricted ? _self.plexRestricted : plexRestricted // ignore: cast_nullable_to_non_nullable
as bool,plexAdmin: null == plexAdmin ? _self.plexAdmin : plexAdmin // ignore: cast_nullable_to_non_nullable
as bool,plexProtected: null == plexProtected ? _self.plexProtected : plexProtected // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc


class JellyfinBonfireProfile extends Profile {
  const JellyfinBonfireProfile({required this.id, required this.displayName, this.avatarThumbUrl, this.parentConnectionId, this.bonfireUserId, this.bonfireIsMaster = false, this.bonfireIsAdministrator = false, this.bonfireRequiresPin = false, this.bonfireHasPin = false, this.sortOrder = 0, required this.createdAt, this.lastUsedAt}): super._();
  

@override final  String id;
@override final  String displayName;
@override final  String? avatarThumbUrl;
/// The parent Jellyfin connection's id (the token that can authorize a
/// profile switch — usually the master user's connection).
 final  String? parentConnectionId;
/// The Bonfire profile's Jellyfin user id (GUID). Used by the binder to
/// call `POST /plugins/profiles/switch`.
 final  String? bonfireUserId;
/// Bonfire's `isMaster` — the household owner profile.
@JsonKey() final  bool bonfireIsMaster;
/// Bonfire's `isAdministrator` — a UI warning signal only, never an
/// authorisation signal.
@JsonKey() final  bool bonfireIsAdministrator;
/// Bonfire's `requiresPin` — a PIN must be entered to switch into this
/// profile right now (already false on the LAN when the server has
/// `bypassPinOnLocalNetwork`). Drives the prompt.
@JsonKey() final  bool bonfireRequiresPin;
/// Bonfire's `hasPin` — a PIN is configured at all. Drives display only
/// (shield icon); never prompt from this.
@JsonKey() final  bool bonfireHasPin;
@override@JsonKey() final  int sortOrder;
@override final  DateTime createdAt;
@override final  DateTime? lastUsedAt;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JellyfinBonfireProfileCopyWith<JellyfinBonfireProfile> get copyWith => _$JellyfinBonfireProfileCopyWithImpl<JellyfinBonfireProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JellyfinBonfireProfile&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarThumbUrl, avatarThumbUrl) || other.avatarThumbUrl == avatarThumbUrl)&&(identical(other.parentConnectionId, parentConnectionId) || other.parentConnectionId == parentConnectionId)&&(identical(other.bonfireUserId, bonfireUserId) || other.bonfireUserId == bonfireUserId)&&(identical(other.bonfireIsMaster, bonfireIsMaster) || other.bonfireIsMaster == bonfireIsMaster)&&(identical(other.bonfireIsAdministrator, bonfireIsAdministrator) || other.bonfireIsAdministrator == bonfireIsAdministrator)&&(identical(other.bonfireRequiresPin, bonfireRequiresPin) || other.bonfireRequiresPin == bonfireRequiresPin)&&(identical(other.bonfireHasPin, bonfireHasPin) || other.bonfireHasPin == bonfireHasPin)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.lastUsedAt, lastUsedAt) || other.lastUsedAt == lastUsedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,avatarThumbUrl,parentConnectionId,bonfireUserId,bonfireIsMaster,bonfireIsAdministrator,bonfireRequiresPin,bonfireHasPin,sortOrder,createdAt,lastUsedAt);

@override
String toString() {
  return 'Profile.jellyfinBonfire(id: $id, displayName: $displayName, avatarThumbUrl: $avatarThumbUrl, parentConnectionId: $parentConnectionId, bonfireUserId: $bonfireUserId, bonfireIsMaster: $bonfireIsMaster, bonfireIsAdministrator: $bonfireIsAdministrator, bonfireRequiresPin: $bonfireRequiresPin, bonfireHasPin: $bonfireHasPin, sortOrder: $sortOrder, createdAt: $createdAt, lastUsedAt: $lastUsedAt)';
}


}

/// @nodoc
abstract mixin class $JellyfinBonfireProfileCopyWith<$Res> implements $ProfileCopyWith<$Res> {
  factory $JellyfinBonfireProfileCopyWith(JellyfinBonfireProfile value, $Res Function(JellyfinBonfireProfile) _then) = _$JellyfinBonfireProfileCopyWithImpl;
@override @useResult
$Res call({
 String id, String displayName, String? avatarThumbUrl, String? parentConnectionId, String? bonfireUserId, bool bonfireIsMaster, bool bonfireIsAdministrator, bool bonfireRequiresPin, bool bonfireHasPin, int sortOrder, DateTime createdAt, DateTime? lastUsedAt
});




}
/// @nodoc
class _$JellyfinBonfireProfileCopyWithImpl<$Res>
    implements $JellyfinBonfireProfileCopyWith<$Res> {
  _$JellyfinBonfireProfileCopyWithImpl(this._self, this._then);

  final JellyfinBonfireProfile _self;
  final $Res Function(JellyfinBonfireProfile) _then;

/// Create a copy of Profile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? avatarThumbUrl = freezed,Object? parentConnectionId = freezed,Object? bonfireUserId = freezed,Object? bonfireIsMaster = null,Object? bonfireIsAdministrator = null,Object? bonfireRequiresPin = null,Object? bonfireHasPin = null,Object? sortOrder = null,Object? createdAt = null,Object? lastUsedAt = freezed,}) {
  return _then(JellyfinBonfireProfile(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarThumbUrl: freezed == avatarThumbUrl ? _self.avatarThumbUrl : avatarThumbUrl // ignore: cast_nullable_to_non_nullable
as String?,parentConnectionId: freezed == parentConnectionId ? _self.parentConnectionId : parentConnectionId // ignore: cast_nullable_to_non_nullable
as String?,bonfireUserId: freezed == bonfireUserId ? _self.bonfireUserId : bonfireUserId // ignore: cast_nullable_to_non_nullable
as String?,bonfireIsMaster: null == bonfireIsMaster ? _self.bonfireIsMaster : bonfireIsMaster // ignore: cast_nullable_to_non_nullable
as bool,bonfireIsAdministrator: null == bonfireIsAdministrator ? _self.bonfireIsAdministrator : bonfireIsAdministrator // ignore: cast_nullable_to_non_nullable
as bool,bonfireRequiresPin: null == bonfireRequiresPin ? _self.bonfireRequiresPin : bonfireRequiresPin // ignore: cast_nullable_to_non_nullable
as bool,bonfireHasPin: null == bonfireHasPin ? _self.bonfireHasPin : bonfireHasPin // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,lastUsedAt: freezed == lastUsedAt ? _self.lastUsedAt : lastUsedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
