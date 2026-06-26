// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadProgress {

 String get globalKey; DownloadStatus get status; int get progress; int get downloadedBytes; int get totalBytes; double get speed; String? get errorMessage; String? get currentFile; String? get thumbPath;// Whether the native download task is actively transferring (received
// `TaskStatus.running`), as opposed to being enqueued and held in the
// download queue. Held items read as "Queued" even though they carry a
// downloading status. Transient — never persisted.
 bool get running;
/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadProgressCopyWith<DownloadProgress> get copyWith => _$DownloadProgressCopyWithImpl<DownloadProgress>(this as DownloadProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadProgress&&(identical(other.globalKey, globalKey) || other.globalKey == globalKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.thumbPath, thumbPath) || other.thumbPath == thumbPath)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,globalKey,status,progress,downloadedBytes,totalBytes,speed,errorMessage,currentFile,thumbPath,running);

@override
String toString() {
  return 'DownloadProgress(globalKey: $globalKey, status: $status, progress: $progress, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes, speed: $speed, errorMessage: $errorMessage, currentFile: $currentFile, thumbPath: $thumbPath, running: $running)';
}


}

/// @nodoc
abstract mixin class $DownloadProgressCopyWith<$Res>  {
  factory $DownloadProgressCopyWith(DownloadProgress value, $Res Function(DownloadProgress) _then) = _$DownloadProgressCopyWithImpl;
@useResult
$Res call({
 String globalKey, DownloadStatus status, int progress, int downloadedBytes, int totalBytes, double speed, String? errorMessage, String? currentFile, String? thumbPath, bool running
});




}
/// @nodoc
class _$DownloadProgressCopyWithImpl<$Res>
    implements $DownloadProgressCopyWith<$Res> {
  _$DownloadProgressCopyWithImpl(this._self, this._then);

  final DownloadProgress _self;
  final $Res Function(DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? globalKey = null,Object? status = null,Object? progress = null,Object? downloadedBytes = null,Object? totalBytes = null,Object? speed = null,Object? errorMessage = freezed,Object? currentFile = freezed,Object? thumbPath = freezed,Object? running = null,}) {
  return _then(_self.copyWith(
globalKey: null == globalKey ? _self.globalKey : globalKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,thumbPath: freezed == thumbPath ? _self.thumbPath : thumbPath // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadProgress].
extension DownloadProgressPatterns on DownloadProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadProgress value)  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String globalKey,  DownloadStatus status,  int progress,  int downloadedBytes,  int totalBytes,  double speed,  String? errorMessage,  String? currentFile,  String? thumbPath,  bool running)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.globalKey,_that.status,_that.progress,_that.downloadedBytes,_that.totalBytes,_that.speed,_that.errorMessage,_that.currentFile,_that.thumbPath,_that.running);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String globalKey,  DownloadStatus status,  int progress,  int downloadedBytes,  int totalBytes,  double speed,  String? errorMessage,  String? currentFile,  String? thumbPath,  bool running)  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress():
return $default(_that.globalKey,_that.status,_that.progress,_that.downloadedBytes,_that.totalBytes,_that.speed,_that.errorMessage,_that.currentFile,_that.thumbPath,_that.running);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String globalKey,  DownloadStatus status,  int progress,  int downloadedBytes,  int totalBytes,  double speed,  String? errorMessage,  String? currentFile,  String? thumbPath,  bool running)?  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.globalKey,_that.status,_that.progress,_that.downloadedBytes,_that.totalBytes,_that.speed,_that.errorMessage,_that.currentFile,_that.thumbPath,_that.running);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadProgress extends DownloadProgress {
  const _DownloadProgress({required this.globalKey, required this.status, this.progress = 0, this.downloadedBytes = 0, this.totalBytes = 0, this.speed = 0.0, this.errorMessage, this.currentFile, this.thumbPath, this.running = false}): super._();
  

@override final  String globalKey;
@override final  DownloadStatus status;
@override@JsonKey() final  int progress;
@override@JsonKey() final  int downloadedBytes;
@override@JsonKey() final  int totalBytes;
@override@JsonKey() final  double speed;
@override final  String? errorMessage;
@override final  String? currentFile;
@override final  String? thumbPath;
// Whether the native download task is actively transferring (received
// `TaskStatus.running`), as opposed to being enqueued and held in the
// download queue. Held items read as "Queued" even though they carry a
// downloading status. Transient — never persisted.
@override@JsonKey() final  bool running;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadProgressCopyWith<_DownloadProgress> get copyWith => __$DownloadProgressCopyWithImpl<_DownloadProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadProgress&&(identical(other.globalKey, globalKey) || other.globalKey == globalKey)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.downloadedBytes, downloadedBytes) || other.downloadedBytes == downloadedBytes)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.thumbPath, thumbPath) || other.thumbPath == thumbPath)&&(identical(other.running, running) || other.running == running));
}


@override
int get hashCode => Object.hash(runtimeType,globalKey,status,progress,downloadedBytes,totalBytes,speed,errorMessage,currentFile,thumbPath,running);

@override
String toString() {
  return 'DownloadProgress(globalKey: $globalKey, status: $status, progress: $progress, downloadedBytes: $downloadedBytes, totalBytes: $totalBytes, speed: $speed, errorMessage: $errorMessage, currentFile: $currentFile, thumbPath: $thumbPath, running: $running)';
}


}

/// @nodoc
abstract mixin class _$DownloadProgressCopyWith<$Res> implements $DownloadProgressCopyWith<$Res> {
  factory _$DownloadProgressCopyWith(_DownloadProgress value, $Res Function(_DownloadProgress) _then) = __$DownloadProgressCopyWithImpl;
@override @useResult
$Res call({
 String globalKey, DownloadStatus status, int progress, int downloadedBytes, int totalBytes, double speed, String? errorMessage, String? currentFile, String? thumbPath, bool running
});




}
/// @nodoc
class __$DownloadProgressCopyWithImpl<$Res>
    implements _$DownloadProgressCopyWith<$Res> {
  __$DownloadProgressCopyWithImpl(this._self, this._then);

  final _DownloadProgress _self;
  final $Res Function(_DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? globalKey = null,Object? status = null,Object? progress = null,Object? downloadedBytes = null,Object? totalBytes = null,Object? speed = null,Object? errorMessage = freezed,Object? currentFile = freezed,Object? thumbPath = freezed,Object? running = null,}) {
  return _then(_DownloadProgress(
globalKey: null == globalKey ? _self.globalKey : globalKey // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as int,downloadedBytes: null == downloadedBytes ? _self.downloadedBytes : downloadedBytes // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,thumbPath: freezed == thumbPath ? _self.thumbPath : thumbPath // ignore: cast_nullable_to_non_nullable
as String?,running: null == running ? _self.running : running // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$DeletionProgress {

 String get globalKey; String get itemTitle; int get currentItem; int get totalItems; String? get currentOperation;
/// Create a copy of DeletionProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeletionProgressCopyWith<DeletionProgress> get copyWith => _$DeletionProgressCopyWithImpl<DeletionProgress>(this as DeletionProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeletionProgress&&(identical(other.globalKey, globalKey) || other.globalKey == globalKey)&&(identical(other.itemTitle, itemTitle) || other.itemTitle == itemTitle)&&(identical(other.currentItem, currentItem) || other.currentItem == currentItem)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.currentOperation, currentOperation) || other.currentOperation == currentOperation));
}


@override
int get hashCode => Object.hash(runtimeType,globalKey,itemTitle,currentItem,totalItems,currentOperation);

@override
String toString() {
  return 'DeletionProgress(globalKey: $globalKey, itemTitle: $itemTitle, currentItem: $currentItem, totalItems: $totalItems, currentOperation: $currentOperation)';
}


}

/// @nodoc
abstract mixin class $DeletionProgressCopyWith<$Res>  {
  factory $DeletionProgressCopyWith(DeletionProgress value, $Res Function(DeletionProgress) _then) = _$DeletionProgressCopyWithImpl;
@useResult
$Res call({
 String globalKey, String itemTitle, int currentItem, int totalItems, String? currentOperation
});




}
/// @nodoc
class _$DeletionProgressCopyWithImpl<$Res>
    implements $DeletionProgressCopyWith<$Res> {
  _$DeletionProgressCopyWithImpl(this._self, this._then);

  final DeletionProgress _self;
  final $Res Function(DeletionProgress) _then;

/// Create a copy of DeletionProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? globalKey = null,Object? itemTitle = null,Object? currentItem = null,Object? totalItems = null,Object? currentOperation = freezed,}) {
  return _then(_self.copyWith(
globalKey: null == globalKey ? _self.globalKey : globalKey // ignore: cast_nullable_to_non_nullable
as String,itemTitle: null == itemTitle ? _self.itemTitle : itemTitle // ignore: cast_nullable_to_non_nullable
as String,currentItem: null == currentItem ? _self.currentItem : currentItem // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,currentOperation: freezed == currentOperation ? _self.currentOperation : currentOperation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DeletionProgress].
extension DeletionProgressPatterns on DeletionProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeletionProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeletionProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeletionProgress value)  $default,){
final _that = this;
switch (_that) {
case _DeletionProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeletionProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DeletionProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String globalKey,  String itemTitle,  int currentItem,  int totalItems,  String? currentOperation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeletionProgress() when $default != null:
return $default(_that.globalKey,_that.itemTitle,_that.currentItem,_that.totalItems,_that.currentOperation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String globalKey,  String itemTitle,  int currentItem,  int totalItems,  String? currentOperation)  $default,) {final _that = this;
switch (_that) {
case _DeletionProgress():
return $default(_that.globalKey,_that.itemTitle,_that.currentItem,_that.totalItems,_that.currentOperation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String globalKey,  String itemTitle,  int currentItem,  int totalItems,  String? currentOperation)?  $default,) {final _that = this;
switch (_that) {
case _DeletionProgress() when $default != null:
return $default(_that.globalKey,_that.itemTitle,_that.currentItem,_that.totalItems,_that.currentOperation);case _:
  return null;

}
}

}

/// @nodoc


class _DeletionProgress extends DeletionProgress {
  const _DeletionProgress({required this.globalKey, required this.itemTitle, required this.currentItem, required this.totalItems, this.currentOperation}): super._();
  

@override final  String globalKey;
@override final  String itemTitle;
@override final  int currentItem;
@override final  int totalItems;
@override final  String? currentOperation;

/// Create a copy of DeletionProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeletionProgressCopyWith<_DeletionProgress> get copyWith => __$DeletionProgressCopyWithImpl<_DeletionProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeletionProgress&&(identical(other.globalKey, globalKey) || other.globalKey == globalKey)&&(identical(other.itemTitle, itemTitle) || other.itemTitle == itemTitle)&&(identical(other.currentItem, currentItem) || other.currentItem == currentItem)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.currentOperation, currentOperation) || other.currentOperation == currentOperation));
}


@override
int get hashCode => Object.hash(runtimeType,globalKey,itemTitle,currentItem,totalItems,currentOperation);

@override
String toString() {
  return 'DeletionProgress(globalKey: $globalKey, itemTitle: $itemTitle, currentItem: $currentItem, totalItems: $totalItems, currentOperation: $currentOperation)';
}


}

/// @nodoc
abstract mixin class _$DeletionProgressCopyWith<$Res> implements $DeletionProgressCopyWith<$Res> {
  factory _$DeletionProgressCopyWith(_DeletionProgress value, $Res Function(_DeletionProgress) _then) = __$DeletionProgressCopyWithImpl;
@override @useResult
$Res call({
 String globalKey, String itemTitle, int currentItem, int totalItems, String? currentOperation
});




}
/// @nodoc
class __$DeletionProgressCopyWithImpl<$Res>
    implements _$DeletionProgressCopyWith<$Res> {
  __$DeletionProgressCopyWithImpl(this._self, this._then);

  final _DeletionProgress _self;
  final $Res Function(_DeletionProgress) _then;

/// Create a copy of DeletionProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? globalKey = null,Object? itemTitle = null,Object? currentItem = null,Object? totalItems = null,Object? currentOperation = freezed,}) {
  return _then(_DeletionProgress(
globalKey: null == globalKey ? _self.globalKey : globalKey // ignore: cast_nullable_to_non_nullable
as String,itemTitle: null == itemTitle ? _self.itemTitle : itemTitle // ignore: cast_nullable_to_non_nullable
as String,currentItem: null == currentItem ? _self.currentItem : currentItem // ignore: cast_nullable_to_non_nullable
as int,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,currentOperation: freezed == currentOperation ? _self.currentOperation : currentOperation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
