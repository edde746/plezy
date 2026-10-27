// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:ffi' as ffi;
import 'dart:isolate' show RawReceivePort, ReceivePort;

import 'package:ffi/ffi.dart' show calloc;
import 'package:flutter/services.dart';

/// Represents track information returned from the native player.
class TrackMessage {
  /// Creates a [TrackMessage] with the given [playerId] and [tracks].
  TrackMessage({required this.playerId, required this.tracks});

  /// The unique identifier of the player.
  int playerId;

  /// The list of available tracks for the player.
  List<Map<Object?, Object?>?> tracks;

  /// Serializes this message to a JSON string.
  String toJson() {
    final jsonMap = <String, dynamic>{
      'playerId': playerId,
      'tracks': tracks,
    };
    return jsonEncode(jsonMap);
  }

  /// Deserializes a JSON string into a [TrackMessage].
  static TrackMessage fromJson(String jsonString) {
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return TrackMessage(
      playerId: jsonMap['playerId'] as int,
      tracks: (jsonMap['tracks'] as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>).cast<Object?, Object?>())
          .toList(),
    );
  }
}

/// Represents the parameters for creating a new video player instance.
class CreateMessage {
  /// Creates a [CreateMessage] with optional parameters.
  CreateMessage({
    this.asset,
    this.uri,
    this.packageName,
    this.formatHint,
    this.httpHeaders,
    this.drmConfigs,
    this.playerOptions,
    this.windowGeometry,
  });

  /// The asset path for local video resources.
  String? asset;

  /// The URI of the video to play.
  String? uri;

  /// The package name for asset resolution.
  String? packageName;

  /// The format hint for the video.
  String? formatHint;

  /// HTTP headers for the video request.
  Map<Object?, Object?>? httpHeaders;

  /// DRM configuration for protected content.
  Map<Object?, Object?>? drmConfigs;

  /// Additional player options.
  Map<Object?, Object?>? playerOptions;

  /// The window geometry for the video display surface.
  Map<Object?, Object?>? windowGeometry;

  /// Serializes this message to a JSON string.
  String toJson() {
    final jsonMap = <String, dynamic>{};
    if (asset != null && asset!.isNotEmpty) {
      jsonMap['asset'] = asset;
    }
    if (uri != null && uri!.isNotEmpty) {
      jsonMap['uri'] = uri;
    }
    if (packageName != null && packageName!.isNotEmpty) {
      jsonMap['packageName'] = packageName;
    }
    if (formatHint != null && formatHint!.isNotEmpty) {
      jsonMap['formatHint'] = formatHint;
    }
    if (httpHeaders != null && httpHeaders!.isNotEmpty) {
      jsonMap['httpHeaders'] = httpHeaders;
    }
    if (drmConfigs != null && drmConfigs!.isNotEmpty) {
      jsonMap['drmConfigs'] = drmConfigs;
    }
    if (playerOptions != null && playerOptions!.isNotEmpty) {
      jsonMap['playerOptions'] = playerOptions;
    }
    if (windowGeometry != null && windowGeometry!.isNotEmpty) {
      jsonMap['windowGeometry'] = windowGeometry;
    }
    return jsonEncode(jsonMap);
  }

  /// Deserializes a JSON string into a [CreateMessage].
  static CreateMessage fromJson(String jsonString) {
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return CreateMessage(
      asset: jsonMap['asset'] as String?,
      uri: jsonMap['uri'] as String?,
      packageName: jsonMap['packageName'] as String?,
      formatHint: jsonMap['formatHint'] as String?,
      httpHeaders: (jsonMap['httpHeaders'] as Map?)?.cast<Object?, Object?>(),
      drmConfigs: (jsonMap['drmConfigs'] as Map?)?.cast<Object?, Object?>(),
      playerOptions: (jsonMap['playerOptions'] as Map?)?.cast<Object?, Object?>(),
      windowGeometry: (jsonMap['windowGeometry'] as Map?)?.cast<Object?, Object?>(),
    );
  }
}

/// Represents the duration information of a video player.
class DurationMessage {
  /// Creates a [DurationMessage] with the given [playerId] and optional [durationRange].
  DurationMessage({required this.playerId, this.durationRange});

  /// The unique identifier of the player.
  int playerId;

  /// The duration range [min, max] in milliseconds.
  List<int?>? durationRange;

  /// Serializes this message to a JSON string.
  String toJson() {
    final jsonMap = <String, dynamic>{
      'playerId': playerId,
      if (durationRange != null) 'durationRange': durationRange,
    };
    return jsonEncode(jsonMap);
  }

  /// Deserializes a JSON string into a [DurationMessage].
  static DurationMessage fromJson(String jsonString) {
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    return DurationMessage(
      playerId: jsonMap['playerId'] as int,
      durationRange:
          (jsonMap['durationRange'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
    );
  }
}

typedef _FFIInitializeNative = ffi.Int32 Function();
typedef _FFIInitializeDart = int Function();

typedef _FFICreateNative = ffi.Int64 Function(ffi.Pointer<ffi.Char>);
typedef _FFICreateDart = int Function(ffi.Pointer<ffi.Char>);

typedef _FFIPrepareNative = ffi.Int32 Function(ffi.Int64);
typedef _FFIPrepareDart = int Function(int);

typedef _FFIDisposeNative = ffi.Int32 Function(ffi.Int64);
typedef _FFIDisposeDart = int Function(int);

typedef _FFIPlayNative = ffi.Int32 Function(ffi.Int64);
typedef _FFIPlayDart = int Function(int);

typedef _FFIPauseNative = ffi.Int32 Function(ffi.Int64);
typedef _FFIPauseDart = int Function(int);

typedef _FFISeekToNative = ffi.Int32 Function(ffi.Int64, ffi.Int64);
typedef _FFISeekToDart = int Function(int, int);

typedef _FFIGetPositionNative = ffi.Int64 Function(ffi.Int64);
typedef _FFIGetPositionDart = int Function(int);

typedef _FFIGetDurationNative = ffi.Pointer<ffi.Char> Function(ffi.Int64);
typedef _FFIGetDurationDart = ffi.Pointer<ffi.Char> Function(int);

typedef _FFISetVolumeNative = ffi.Int32 Function(ffi.Int64, ffi.Double);
typedef _FFISetVolumeDart = int Function(int, double);

typedef _FFISetPlaybackSpeedNative = ffi.Int32 Function(ffi.Int64, ffi.Double);
typedef _FFISetPlaybackSpeedDart = int Function(int, double);

typedef _FFISetLoopingNative = ffi.Int32 Function(ffi.Int64, ffi.Bool);
typedef _FFISetLoopingDart = int Function(int, bool);

typedef _FFIGetTrackInfoNative = ffi.Pointer<ffi.Char> Function(ffi.Int64, ffi.Pointer<ffi.Char>);
typedef _FFIGetTrackInfoDart = ffi.Pointer<ffi.Char> Function(int, ffi.Pointer<ffi.Char>);

typedef _FFISetTrackSelectionNative = ffi.Int32 Function(
    ffi.Int64, ffi.Int64, ffi.Pointer<ffi.Char>);
typedef _FFISetTrackSelectionDart = int Function(int, int, ffi.Pointer<ffi.Char>);

typedef _FFISetDisplayGeometryNative = ffi.Int32 Function(
    ffi.Int64, ffi.Int32, ffi.Int32, ffi.Int32, ffi.Int32);
typedef _FFISetDisplayGeometryDart = int Function(int, int, int, int, int);

typedef _FFISetDisplayRotateNative = ffi.Int32 Function(ffi.Int64, ffi.Int32);
typedef _FFISetDisplayRotateDart = int Function(int, int);

typedef _FFISetActivateNative = ffi.Int32 Function(ffi.Int64);
typedef _FFISetActivateDart = int Function(int);

typedef _FFISetDeactivateNative = ffi.Int32 Function(ffi.Int64);
typedef _FFISetDeactivateDart = int Function(int);

typedef _FFISetMixWithOthersNative = ffi.Int32 Function(ffi.Bool);
typedef _FFISetMixWithOthersDart = int Function(bool);

typedef _FFISuspendNative = ffi.Int32 Function(ffi.Int64);
typedef _FFISuspendDart = int Function(int);

typedef _FFIRestoreNative = ffi.Int32 Function(ffi.Int64, ffi.Pointer<ffi.Char>, ffi.Int64);
typedef _FFIRestoreDart = int Function(int, ffi.Pointer<ffi.Char>, int);

typedef _FFIFreeStringNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _FFIFreeStringDart = void Function(ffi.Pointer<ffi.Char>);

ffi.Pointer<ffi.Char> _toPointer(String? str) {
  if (str == null) {
    return ffi.nullptr;
  }
  final Uint8List units = utf8.encode(str);
  final ffi.Pointer<ffi.Uint8> result = calloc.allocate<ffi.Uint8>(units.length + 1);
  final Uint8List nativeString = result.asTypedList(units.length + 1);
  nativeString.setAll(0, units);
  nativeString[units.length] = 0;
  return result.cast<ffi.Char>();
}

void _freePointer(ffi.Pointer<ffi.Char> ptr) {
  if (ptr != ffi.nullptr) {
    calloc.free(ptr);
  }
}

/// Manages FFI bindings to the native video player library.
class VideoPlayerFFIBindings {
  VideoPlayerFFIBindings._();
  static VideoPlayerFFIBindings? _instance;
  ffi.DynamicLibrary? _lib;

  late int Function() _ffiInitialize;
  late int Function(ffi.Pointer<ffi.Char>) _ffiCreate;
  late int Function(int) _ffiPrepare;

  late int Function(int) _ffiDispose;
  late int Function(int) _ffiPlay;
  late int Function(int) _ffiPause;
  late int Function(int, int) _ffiSeekTo;
  late int Function(int) _ffiGetPosition;
  late ffi.Pointer<ffi.Char> Function(int) _ffiGetDuration;
  late int Function(int, double) _ffiSetVolume;
  late int Function(int, double) _ffiSetPlaybackSpeed;
  late int Function(int, bool) _ffiSetLooping;
  late ffi.Pointer<ffi.Char> Function(int, ffi.Pointer<ffi.Char>) _ffiGetTrackInfo;
  late int Function(int, int, ffi.Pointer<ffi.Char>) _ffiSetTrackSelection;
  late int Function(int, int, int, int, int) _ffiSetDisplayGeometry;
  late int Function(int, int) _ffiSetDisplayRotate;
  late int Function(int) _ffiSuspend;
  late int Function(int, ffi.Pointer<ffi.Char>, int) _ffiRestore;
  late int Function(int) _ffiSetActivate;
  late int Function(int) _ffiSetDeactivate;
  late int Function(bool) _ffiSetMixWithOthers;
  late void Function(ffi.Pointer<ffi.Char>) _ffiFreeString;
  late void Function(int) _ffiRegisterDartPort;
  late void Function() _ffiUnregisterDartPort;

  /// Returns the singleton instance of [VideoPlayerFFIBindings].
  static VideoPlayerFFIBindings get instance {
    _instance ??= VideoPlayerFFIBindings._();
    return _instance!;
  }

  /// Loads the native library and resolves all FFI function symbols.
  void load() {
    if (_lib != null) {
      return;
    }

    try {
      _lib = ffi.DynamicLibrary.process();

      _ffiInitialize = _lib!
          .lookup<ffi.NativeFunction<_FFIInitializeNative>>('ffi_initialize')
          .asFunction<_FFIInitializeDart>();

      _ffiCreate = _lib!
          .lookup<ffi.NativeFunction<_FFICreateNative>>('ffi_create')
          .asFunction<_FFICreateDart>();

      _ffiPrepare = _lib!
          .lookup<ffi.NativeFunction<_FFIPrepareNative>>('ffi_prepare')
          .asFunction<_FFIPrepareDart>();

      _ffiDispose = _lib!
          .lookup<ffi.NativeFunction<_FFIDisposeNative>>('ffi_dispose')
          .asFunction<_FFIDisposeDart>();

      _ffiPlay =
          _lib!.lookup<ffi.NativeFunction<_FFIPlayNative>>('ffi_play').asFunction<_FFIPlayDart>();

      _ffiPause = _lib!
          .lookup<ffi.NativeFunction<_FFIPauseNative>>('ffi_pause')
          .asFunction<_FFIPauseDart>();

      _ffiSeekTo = _lib!
          .lookup<ffi.NativeFunction<_FFISeekToNative>>('ffi_seek_to')
          .asFunction<_FFISeekToDart>();

      _ffiGetPosition = _lib!
          .lookup<ffi.NativeFunction<_FFIGetPositionNative>>('ffi_get_position')
          .asFunction<_FFIGetPositionDart>();

      _ffiGetDuration = _lib!
          .lookup<ffi.NativeFunction<_FFIGetDurationNative>>('ffi_get_duration')
          .asFunction<_FFIGetDurationDart>();

      _ffiSetVolume = _lib!
          .lookup<ffi.NativeFunction<_FFISetVolumeNative>>('ffi_set_volume')
          .asFunction<_FFISetVolumeDart>();

      _ffiSetPlaybackSpeed = _lib!
          .lookup<ffi.NativeFunction<_FFISetPlaybackSpeedNative>>('ffi_set_playback_speed')
          .asFunction<_FFISetPlaybackSpeedDart>();

      _ffiSetLooping = _lib!
          .lookup<ffi.NativeFunction<_FFISetLoopingNative>>('ffi_set_looping')
          .asFunction<_FFISetLoopingDart>();

      _ffiGetTrackInfo = _lib!
          .lookup<ffi.NativeFunction<_FFIGetTrackInfoNative>>('ffi_get_track_info')
          .asFunction<_FFIGetTrackInfoDart>();

      _ffiSetTrackSelection = _lib!
          .lookup<ffi.NativeFunction<_FFISetTrackSelectionNative>>('ffi_set_track_selection')
          .asFunction<_FFISetTrackSelectionDart>();

      _ffiSetDisplayGeometry = _lib!
          .lookup<ffi.NativeFunction<_FFISetDisplayGeometryNative>>('ffi_set_display_geometry')
          .asFunction<_FFISetDisplayGeometryDart>();

      _ffiSetDisplayRotate = _lib!
          .lookup<ffi.NativeFunction<_FFISetDisplayRotateNative>>('ffi_set_display_rotate')
          .asFunction<_FFISetDisplayRotateDart>();

      _ffiSuspend = _lib!
          .lookup<ffi.NativeFunction<_FFISuspendNative>>('ffi_suspend')
          .asFunction<_FFISuspendDart>();

      _ffiRestore = _lib!
          .lookup<ffi.NativeFunction<_FFIRestoreNative>>('ffi_restore')
          .asFunction<_FFIRestoreDart>();

      _ffiSetActivate = _lib!
          .lookup<ffi.NativeFunction<_FFISetActivateNative>>('ffi_set_activate')
          .asFunction<_FFISetActivateDart>();

      _ffiSetDeactivate = _lib!
          .lookup<ffi.NativeFunction<_FFISetDeactivateNative>>('ffi_set_deactivate')
          .asFunction<_FFISetDeactivateDart>();

      _ffiSetMixWithOthers = _lib!
          .lookup<ffi.NativeFunction<_FFISetMixWithOthersNative>>('ffi_set_mix_with_others')
          .asFunction<_FFISetMixWithOthersDart>();

      _ffiFreeString = _lib!
          .lookup<ffi.NativeFunction<_FFIFreeStringNative>>('ffi_free_string')
          .asFunction<_FFIFreeStringDart>();

      _ffiRegisterDartPort = _lib!
          .lookup<ffi.NativeFunction<_FFIRegisterEventPortNative>>('ffi_register_dart_port')
          .asFunction<_FFIRegisterEventPortDart>();
      _ffiUnregisterDartPort = _lib!
          .lookup<ffi.NativeFunction<_FFIUnregisterEventPortNative>>('ffi_unregister_dart_port')
          .asFunction<_FFIUnregisterEventPortDart>();
    } catch (e) {
      _lib = null;
      throw PlatformException(
        code: 'FFI_LIBRARY_LOAD_FAILED',
        message: 'Failed to load FFI bindings',
      );
    }
  }

  /// Whether the native library has been loaded.
  bool get isLoaded => _lib != null;
}

/// Provides the Dart-facing API for the native video player via FFI.
class VideoPlayerVideoholeFFIApi {
  /// Initializes the native video player library.
  int initialize() {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiInitialize();
  }

  /// Creates a new native video player instance from [message].
  int create(CreateMessage message) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    final String jsonString = message.toJson();
    final ffi.Pointer<ffi.Char> jsonPtr = _toPointer(jsonString);
    try {
      return bindings._ffiCreate(jsonPtr);
    } finally {
      _freePointer(jsonPtr);
    }
  }

  /// Prepares the player for playback asynchronously.
  int prepare(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiPrepare(playerId);
  }

  /// Restores a previously suspended player with optional [message] and [resumeTime].
  int restore(int playerId, CreateMessage? message, int resumeTime) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    final String? jsonString = message?.toJson();
    final ffi.Pointer<ffi.Char> createMessagePtr = _toPointer(jsonString);
    try {
      return bindings._ffiRestore(playerId, createMessagePtr, resumeTime);
    } finally {
      _freePointer(createMessagePtr);
    }
  }

  /// Disposes the native player identified by [playerId].
  int dispose(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiDispose(playerId);
  }

  /// Starts playback of the player identified by [playerId].
  int play(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiPlay(playerId);
  }

  /// Pauses playback of the player identified by [playerId].
  int pause(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiPause(playerId);
  }

  /// Seeks to [positionMs] in the player identified by [playerId].
  int seekTo(int playerId, int positionMs) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSeekTo(playerId, positionMs);
  }

  /// Returns the current playback position in milliseconds.
  int getPosition(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiGetPosition(playerId);
  }

  /// Returns the duration information of the player identified by [playerId].
  DurationMessage duration(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    final ffi.Pointer<ffi.Char> ptr = bindings._ffiGetDuration(playerId);
    if (ptr == ffi.nullptr) {
      throw PlatformException(
        code: 'FFI_GET_DURATION_FAILED',
        message: 'FFI getDuration failed - returned null pointer',
      );
    }
    try {
      final ffi.Pointer<ffi.Uint8> bytes = ptr.cast<ffi.Uint8>();
      var length = 0;
      while (bytes[length] != 0) {
        length++;
      }
      final String jsonString = utf8.decode(bytes.asTypedList(length));
      if (jsonString == '-1') {
        throw PlatformException(
          code: 'FFI_GET_DURATION_FAILED',
          message: 'FFI getDuration failed',
        );
      }
      return DurationMessage.fromJson(jsonString);
    } finally {
      bindings._ffiFreeString(ptr);
    }
  }

  /// Sets the playback volume for the player identified by [playerId].
  int setVolume(int playerId, double volume) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetVolume(playerId, volume);
  }

  /// Sets the playback speed for the player identified by [playerId].
  int setPlaybackSpeed(int playerId, double speed) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetPlaybackSpeed(playerId, speed);
  }

  /// Enables or disables looping for the player identified by [playerId].
  int setLooping(int playerId, bool isLooping) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetLooping(playerId, isLooping);
  }

  /// Sets the display geometry (position and size) for the player.
  int setDisplayGeometry(int playerId, int x, int y, int width, int height) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetDisplayGeometry(playerId, x, y, width, height);
  }

  /// Sets the display rotation for the player identified by [playerId].
  int setDisplayRotate(int playerId, int rotation) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetDisplayRotate(playerId, rotation);
  }

  /// Suspends the player identified by [playerId].
  int suspend(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSuspend(playerId);
  }

  /// Activates the player identified by [playerId].
  int setActivate(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetActivate(playerId);
  }

  /// Deactivates the player identified by [playerId].
  int setDeactivate(int playerId) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetDeactivate(playerId);
  }

  /// Retrieves track information for the player identified by [playerId].
  TrackMessage getTrackInfo(int playerId, String trackType) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    final ffi.Pointer<ffi.Char> trackTypePtr = _toPointer(trackType);
    ffi.Pointer<ffi.Char>? ptr;
    try {
      ptr = bindings._ffiGetTrackInfo(playerId, trackTypePtr);
      if (ptr == ffi.nullptr) {
        throw PlatformException(
          code: 'FFI_GET_TRACK_INFO_FAILED',
          message: 'FFI getTrackInfo failed - returned null pointer',
        );
      }
      final ffi.Pointer<ffi.Uint8> bytes = ptr.cast<ffi.Uint8>();
      var length = 0;
      while (bytes[length] != 0) {
        length++;
      }
      final String jsonString = utf8.decode(bytes.asTypedList(length));
      if (jsonString == '-1') {
        throw PlatformException(
          code: 'FFI_GET_TRACK_INFO_FAILED',
          message: 'FFI getTrackInfo failed',
        );
      }
      return TrackMessage.fromJson(jsonString);
    } finally {
      if (ptr != null) {
        bindings._ffiFreeString(ptr);
      }
      _freePointer(trackTypePtr);
    }
  }

  /// Selects a track by [trackId] and [trackType] for the player.
  int setTrackSelection(int playerId, int trackId, String trackType) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    final ffi.Pointer<ffi.Char> trackTypePtr = _toPointer(trackType);
    try {
      return bindings._ffiSetTrackSelection(playerId, trackId, trackTypePtr);
    } finally {
      _freePointer(trackTypePtr);
    }
  }

  /// Sets whether audio should mix with other audio sources.
  int setMixWithOthers(bool mixWithOthers) {
    final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
    if (!bindings.isLoaded) {
      bindings.load();
    }
    return bindings._ffiSetMixWithOthers(mixWithOthers);
  }
}

typedef _FFIInitializeApiDlNative = ffi.Int32 Function(ffi.Pointer<ffi.Void>);
typedef _FFIInitializeApiDlDart = int Function(ffi.Pointer<ffi.Void>);

typedef _FFIRegisterEventPortNative = ffi.Void Function(ffi.Int64);
typedef _FFIRegisterEventPortDart = void Function(int);

typedef _FFIUnregisterEventPortNative = ffi.Void Function();
typedef _FFIUnregisterEventPortDart = void Function();

late ffi.Pointer<ffi.NativeFunction<_FFIInitializeApiDlNative>>? _ffiInitializeApiDlPtr;

/// Whether the Dart API DL has been initialized.
bool _apiDlInitialized = false;

/// Initializes the Dart API DL for native-to-Dart communication.
void ffiInitializeApiDL() {
  if (_apiDlInitialized) {
    return;
  }

  final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
  if (!bindings.isLoaded) {
    bindings.load();
  }
  final ffi.DynamicLibrary? lib = bindings._lib;
  if (lib == null) {
    throw PlatformException(
      code: 'FFI_LIBRARY_NOT_LOADED',
      message: 'FFI library is not loaded',
    );
  }

  try {
    _ffiInitializeApiDlPtr =
        lib.lookup<ffi.NativeFunction<_FFIInitializeApiDlNative>>('ffi_initialize_api_dl');
  } catch (e) {
    throw PlatformException(
      code: 'FFI_API_DL_LOOKUP_FAILED',
      message: 'Failed to lookup ffi_initialize_api_dl',
    );
  }

  final int result = _ffiInitializeApiDlPtr!
      .asFunction<_FFIInitializeApiDlDart>()(ffi.NativeApi.initializeApiDLData);
  if (result != 0) {
    throw PlatformException(
      code: 'FFI_API_DL_INITIALIZATION_FAILED',
      message: 'Dart API DL initialization failed with code: $result',
    );
  }

  _apiDlInitialized = true;
}

/// Extension on [RawReceivePort] to expose the native port ID.
extension RawReceivePortNativePort on RawReceivePort {
  /// Returns the native port ID of this [RawReceivePort].
  int get nativePort => _rawReceivePortNativePort(this);
}

/// Extension on [ReceivePort] to expose the native port ID.
extension ReceivePortNativePort on ReceivePort {
  /// Returns the native port ID of this [ReceivePort].
  int get nativePort => _receivePortNativePort(this);
}

@pragma('vm:never-inline')
int _rawReceivePortNativePort(RawReceivePort port) {
  return port.sendPort.nativePort;
}

@pragma('vm:never-inline')
int _receivePortNativePort(ReceivePort port) {
  return port.sendPort.nativePort;
}

/// Registers the Dart event [port] with the native player for receiving events.
void ffiRegisterEventPort(int port) {
  final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
  if (!bindings.isLoaded) {
    bindings.load();
  }
  bindings._ffiRegisterDartPort(port);
}

/// Unregisters the Dart event port from the native player.
void ffiUnregisterEventPort() {
  final VideoPlayerFFIBindings bindings = VideoPlayerFFIBindings.instance;
  if (!bindings.isLoaded) {
    bindings.load();
  }
  bindings._ffiUnregisterDartPort();
}
