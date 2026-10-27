import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'native_downloader.dart';

enum PermissionType {
  notifications,
  androidSharedStorage,
  iosAddToPhotoLibrary,
  iosChangePhotoLibrary,
}

enum PermissionStatus { undetermined, denied, granted, partial, requestError }

/// Developer visible interface to the PermissionService
abstract interface class Permissions {
  /// Request a permission; returns the [PermissionStatus]
  ///
  /// Ensure that only one request is being handled at the same time,
  /// i.e. wait for the result before requesting another permission
  Future<PermissionStatus> request(PermissionType permissionType);

  /// Get the auth status of a permission; returns the [PermissionStatus]
  Future<PermissionStatus> status(PermissionType permissionType);

  /// Returns true if the developer should show a rationale for
  /// requesting this permission
  Future<bool> shouldShowRationale(PermissionType permissionType);
}

/// Basic implementation of the PermissionsService
base class PermissionsService implements Permissions {
  final log = Logger("PermissionService");

  PermissionsService();

  /// Creates a [PermissionsService] appropriate for this platform
  factory PermissionsService.instance() => switch (defaultTargetPlatform) {
    .android => AndroidPermissionsService(),
    .iOS => IOSPermissionsService(),
    .linux || .macOS || .windows => PermissionsService(),
    _ => throw ArgumentError(
      'Platform $defaultTargetPlatform is not supported',
    ),
  };

  @override
  Future<PermissionStatus> request(PermissionType permissionType) =>
      Future.value(PermissionStatus.granted);

  @override
  Future<bool> shouldShowRationale(PermissionType permissionType) =>
      Future.value(false);

  @override
  Future<PermissionStatus> status(PermissionType permissionType) =>
      Future.value(PermissionStatus.granted);

  /// Process the permissionRequest result sent from the native side
  /// (Android only)
  void onPermissionRequestResult(PermissionStatus permissionStatus) {}
}

final class IOSPermissionsService extends PermissionsService {
  IOSPermissionsService();

  @override
  Future<PermissionStatus> request(PermissionType permissionType) async {
    final result = await NativeDownloader.methodChannel.invokeMethod<int>(
      'requestPermission',
      permissionType.index,
    );
    return result != null
        ? PermissionStatus.values[result]
        : PermissionStatus.requestError;
  }

  @override
  Future<PermissionStatus> status(PermissionType permissionType) async {
    final result = await NativeDownloader.methodChannel.invokeMethod<int>(
      'permissionStatus',
      permissionType.index,
    );
    return result != null
        ? PermissionStatus.values[result]
        : PermissionStatus.requestError;
  }
}

final class AndroidPermissionsService extends IOSPermissionsService {
  Completer<PermissionStatus>? permissionStatusCompleter;

  @override
  Future<PermissionStatus> request(PermissionType permissionType) async {
    if (![
      PermissionType.notifications,
      PermissionType.androidSharedStorage,
    ].contains(permissionType)) {
      return PermissionStatus.granted;
    }
    if (permissionStatusCompleter != null) {
      log.warning(
        'Permission request already in progress - failing this one immediately',
      );
      return PermissionStatus.requestError;
    }
    permissionStatusCompleter = Completer();
    final waitForCompletion = await NativeDownloader.methodChannel
        .invokeMethod<bool>('requestPermission', permissionType.index);
    if (waitForCompletion == true) {
      return permissionStatusCompleter!.future;
    } else {
      log.warning(
        'Failure to request for permission - was it already granted?',
      );
      permissionStatusCompleter = null;
      return PermissionStatus.requestError;
    }
  }

  @override
  Future<bool> shouldShowRationale(PermissionType permissionType) async {
    final result = await NativeDownloader.methodChannel.invokeMethod<bool>(
      'shouldShowPermissionRationale',
      permissionType.index,
    );
    return result ?? false;
  }

  @override
  void onPermissionRequestResult(PermissionStatus permissionStatus) {
    permissionStatusCompleter?.complete(permissionStatus);
    permissionStatusCompleter = null;
  }
}
