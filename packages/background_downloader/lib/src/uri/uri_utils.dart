/// Object attached to the [FileDownloader]'s `utils` property, used to access
/// URI related utility functions

library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../base_downloader.dart';
import '../models.dart';

import 'package:path/path.dart' as p;

import '../native_downloader.dart';
import '../task.dart';

/// Base implementation of the utilities related to File, Uri and filePath
/// manipulation.
///
/// Use the [withDownloader] factory constructor to get the appropriate subclass
/// for the platform you're on
sealed class UriUtils {
  final log = Logger('UriUtils');
  final BaseDownloader _downloader;

  UriUtils(BaseDownloader downloader) : _downloader = downloader;

  factory UriUtils.withDownloader(BaseDownloader downloader) =>
      switch (downloader) {
        AndroidDownloader() => _AndroidUriUtils(downloader),
        IOSDownloader() => _IOSUriUtils(downloader),
        _ => _DesktopUriUtils(downloader),
      };

  /// Opens a directory picker dialog and returns the selected directory's URI.
  ///
  /// [startLocation] (optional) specifies a [SharedStorage] location to open the picker at.
  ///    [SharedStorage.images] and [SharedStorage.video] will launch the media
  ///    picker instead of the file picker, and allow selection of the respective media type.
  /// [startLocationUri] (optional) specifies a URI to open the picker at.
  /// Only one of [startLocation] or [startLocationUri] should be provided.
  /// [persistedUriPermission] (optional, defaults to `false`) indicates whether to take persisted URI permission
  /// for the selected directory, if the platform supports it.
  ///
  /// Returns the selected directory's URI, or `null` if the user canceled the operation.
  Future<Uri?> pickDirectory({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    bool persistedUriPermission = false,
  });

  /// Opens a file picker dialog and returns the Uri of the selected file,
  /// or null if the user canceled the operation.
  ///
  /// [startLocation] (optional) specifies a [SharedStorage] location to open the picker at.
  ///   Only .videos and .images will launch the media picker instead of the file picker.
  /// [startLocationUri] (optional) specifies a URI to open the picker at.
  /// Only one of [startLocation] or [startLocationUri] should be provided.
  /// [allowedExtensions] (optional) specifies a list of file extensions to filter the picker by.
  /// [persistedUriPermission] (optional, defaults to `false`) indicates whether to take persisted URI permission
  /// for the selected files, if the platform supports it.
  ///
  /// Returns the URI of the selected file, or `null` if the user canceled the operation.
  Future<Uri?> pickFile({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    List<String>? allowedExtensions,
    bool persistedUriPermission = false,
  }) async {
    final list = await pickFiles(
      startLocation: startLocation,
      startLocationUri: startLocationUri,
      allowedExtensions: allowedExtensions,
      persistedUriPermission: persistedUriPermission,
      multipleAllowed: false,
    );
    return list?.isNotEmpty == true ? list!.first : null;
  }

  /// Opens a file picker dialog and returns a list of the selected files' URIs,
  /// or null if the user canceled the operation.
  ///
  /// [startLocation] (optional) specifies a [SharedStorage] location to open the picker at.
  ///   Only .videos and .images will launch the media picker instead of the file picker.
  /// [startLocationUri] (optional) specifies a URI to open the picker at.
  /// Only one of [startLocation] or [startLocationUri] should be provided.
  /// [allowedExtensions] (optional) specifies a list of file extensions to filter the picker by.
  /// [multipleAllowed] (optional, defaults to `false`) indicates whether to allow multiple file selection.
  /// [persistedUriPermission] (optional, defaults to `false`) indicates whether to take persisted URI permission
  /// for the selected files, if the platform supports it.
  ///
  /// Returns a list of the selected files' URIs, or `null` if the user canceled the operation.
  Future<List<Uri>?> pickFiles({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    List<String>? allowedExtensions,
    bool multipleAllowed = false,
    bool persistedUriPermission = false,
  });

  /// Creates a new directory with the given name within the specified parent directory.
  ///
  /// [parentDirectoryUri] is the URI of the parent directory.
  /// [newDirectoryName] is the name of the new directory to create.
  /// [persistedUriPermission] (optional, defaults to `false`) indicates whether to take persisted URI permission
  /// for the created directory, if the platform supports it.
  ///
  /// Returns the URI of the newly created directory.
  Future<Uri> createDirectory(
    Uri parentDirectoryUri,
    String newDirectoryName, {
    bool persistedUriPermission = false,
  });

  /// Activate a previously accessed directory or file (applies previously
  /// obtained permissions) and return the Uri, or null if this was not
  /// possible
  ///
  /// This is a no-op except on iOS, where it is required to re-activate the
  /// permission obtained when setting `persistedUriPermission` to `true`,
  /// when using the directory or file picker.  In those instances, the returned
  /// URI will have a 'urlbookmark' scheme instead of a file scheme, and that
  /// bookmark contains security information. When you store that bookmark (for
  /// later use) then you must make sure that you still have access to that
  /// resource when - for example - using [getFileBytes] to get the data, or
  /// to upload a file from a previously selected directory.
  ///
  /// This method also converts a media:// scheme URI on iOS to a file:// URI,
  /// allowing you to access (and delete) it.  Media URIs on iOS are generated when
  /// using [pickFiles] with a .images or .videos startingLocation (which
  /// launches the media picker). Selected media is copied into the Application
  /// Support directory, subdirectory "com.bbflight.downloader.media" and
  /// returned as a media:// URI.  To access the actual copied file,
  /// use [activate]
  Future<Uri?> activate(Uri uri) async => uri;

  /// Retrieves the file data (bytes) for a given URI.
  ///
  /// [uri] is the URI of the file.
  ///
  /// Returns a [Uint8List] containing the file data, or `null` if an error occurred.
  Future<Uint8List?> getFileBytes(Uri uri);

  /// Copy a file from a Uri to a new destination.
  ///
  /// The [destination] parameter can be a [File] object, a [String] with a
  /// filePath, or a [Uri].
  Future<Uri?> copyFile(Uri source, dynamic destination);

  /// Move a file from a Uri to a new destination.
  ///
  /// The [destination] parameter can be a [File] object, a [String] with a
  /// filePath, or a [Uri].
  Future<Uri?> moveFile(Uri source, dynamic destination);

  /// Deletes the file at the given URI.
  ///
  /// [uri] is the URI of the file to delete.
  ///
  /// Returns `true` if the file was deleted successfully, `false` otherwise.
  Future<bool> deleteFile(Uri uri);

  /// Opens the file at [uri] with the given [mimeType].
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> openFile(Uri uri, {String mimeType});

  /// Move the file represented by the [task] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [UriTask.fileUri]
  ///
  /// Returns the Uri of the stored file, or null if not successful.
  ///
  /// NOTE: on iOS, using [destination] [SharedStorage.images] or
  /// [SharedStorage.video] adds the photo or video file to the Photos
  /// library. This requires the user to grant permission, and requires the
  /// "NSPhotoLibraryAddUsageDescription" key to be set in Info.plist. The
  /// returned value is NOT a filePath but an identifier. If the full filepath
  /// is required, follow the [moveToSharedStorage] call with a call to
  /// [pathInSharedStorage], passing the identifier obtained from the call
  /// to [moveToSharedStorage] as the filePath parameter. This requires the user to
  /// grant additional permissions, and requires the "NSPhotoLibraryUsageDescription"
  /// key to be set in Info.plist. The returned value is the actual file path
  /// of the photo or video in the Photos Library.
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<Uri?> moveToSharedStorage(
    DownloadTask task,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async {
    final uri = switch (task) {
      final UriTask t => t.fileUri,
      _ => Uri.file(await task.filePath()),
    };
    return uri != null
        ? await moveFileToSharedStorage(
            uri,
            destination,
            directory: directory,
            mimeType: mimeType,
          )
        : null;
  }

  /// Move the file represented by [fileUri] to a shared storage
  /// [destination] and potentially a [directory] within that destination. If
  /// the [mimeType] is not provided we will attempt to derive it from the
  /// [fileUri] extension
  ///
  /// Returns the URI of the stored file, or null if not successful
  ///
  /// NOTE: on iOS, using [destination] [SharedStorage.images] or
  /// [SharedStorage.video] adds the photo or video file to the Photos
  /// library. This requires the user to grant permission, and requires the
  /// "NSPhotoLibraryAddUsageDescription" key to be set in Info.plist. The
  /// returned value is NOT a filePath but an identifier. If the full filepath
  /// is required, follow the [moveToSharedStorage] call with a call to
  /// [pathInSharedStorage], passing the identifier obtained from the call
  /// to [moveToSharedStorage] as the filePath parameter. This requires the user to
  /// grant additional permissions, and requires the "NSPhotoLibraryUsageDescription"
  /// key to be set in Info.plist. The returned value is the actual file path
  /// of the photo or video in the Photos Library.
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<Uri?> moveFileToSharedStorage(
    Uri fileUri,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) async {
    assert(
      fileUri.scheme == 'file',
      'uri.moveFileToSharedStorage requires a file scheme uri, got $fileUri',
    );
    final uriString = await _downloader.moveToSharedStorage(
      fileUri.toString(),
      destination,
      directory,
      mimeType,
      asUriString: true,
    );
    return uriString != null ? Uri.tryParse(uriString) : null;
  }

  /// Returns the Uri of the file represented by [fileUri] in shared
  /// storage [destination] and potentially a [directory] within that
  /// destination.
  ///
  /// Returns the path to the stored file, or null if not successful
  ///
  /// See the documentation for [moveToSharedStorage] for special use case
  /// on iOS for .images and .video
  ///
  /// Platform-dependent, not consistent across all platforms
  Future<Uri?> pathInSharedStorage(
    Uri fileUri,
    SharedStorage destination, {
    String directory = '',
  }) async {
    assert(
      fileUri.scheme == 'file',
      'uri.pathInSharedStorage requires a file scheme uri, got $fileUri',
    );
    final uriString = await _downloader.pathInSharedStorage(
      fileUri.toString(),
      destination,
      directory,
      asUriString: true,
    );
    return uriString != null ? Uri.tryParse(uriString) : null;
  }

  /// Private helper method to determine the destination URI.
  Uri _determineDestinationUri(dynamic destination) => switch (destination) {
    File() => destination.uri,
    String() => Uri.file(destination),
    Uri() => destination,
    _ => throw ArgumentError(
      'Invalid destination type. Must be File, String, or Uri.',
    ),
  };
}

final class _DesktopUriUtils extends UriUtils {
  _DesktopUriUtils(super.downloader);

  @override
  Future<Uri?> pickDirectory({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    bool persistedUriPermission = false,
  }) => throw UnimplementedError(
    'pickDirectory not implemented for this platform. '
    'Use the file_picker package and convert the resulting filePath '
    'to a URI Uri.file(directoryPath, windows: Platform.isWindows)',
  );

  @override
  Future<List<Uri>?> pickFiles({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    List<String>? allowedExtensions,
    bool multipleAllowed = false,
    bool persistedUriPermission = false,
  }) => throw UnimplementedError(
    'pickFiles not implemented for this platform. '
    'Use the file_picker package and convert the resulting filePath '
    'to a URI using Uri.file(filepath, windows: Platform.isWindows)',
  );

  @override
  Future<Uri> createDirectory(
    Uri parentDirectoryUri,
    String newDirectoryName, {
    bool persistedUriPermission = false,
  }) async {
    final parentPath = parentDirectoryUri.toFilePath(
      windows: Platform.isWindows,
    );
    final cleanedSegments = newDirectoryName
        .split(RegExp(r'[\\/]+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    final fullPath = p.joinAll([parentPath, ...cleanedSegments]);
    final createdDirectory = await Directory(fullPath).create(recursive: true);
    return createdDirectory.uri;
  }

  @override
  Future<Uint8List?> getFileBytes(Uri uri) async {
    try {
      final file = File.fromUri(uri);
      if (await file.exists()) {
        return await file.readAsBytes();
      } else {
        log.warning('File does not exist: $uri');
      }
    } catch (e) {
      log.info('Error getting file bytes for $uri', e);
    }
    return null;
  }

  /// Private helper method to perform the file operation (copy or move).
  Future<Uri?> _performFileOperation(
    Uri source,
    Uri destination,
    Future<File> Function(String) operation,
  ) async {
    if (!source.isScheme('file')) {
      log.info('Source must be a file:// URI');
      return null;
    }
    if (!destination.isScheme('file')) {
      throw ArgumentError(
        'Invalid destination type. Must be  file:// Uri, is $destination',
      );
    }
    try {
      final destinationFile = File.fromUri(destination);
      await destinationFile.parent.create(recursive: true);
      await operation(destinationFile.path);
      return destination;
    } catch (e) {
      log.info('Error during file operation from $source to $destination', e);
      return null;
    }
  }

  @override
  Future<Uri?> copyFile(Uri source, dynamic destination) async {
    final destinationUri = _determineDestinationUri(destination);
    return _performFileOperation(
      source,
      destinationUri,
      File.fromUri(source).copy,
    );
  }

  @override
  Future<Uri?> moveFile(Uri source, dynamic destination) async {
    final destinationUri = _determineDestinationUri(destination);
    return _performFileOperation(
      source,
      destinationUri,
      File.fromUri(source).rename,
    );
  }

  @override
  Future<bool> deleteFile(Uri uri) async {
    try {
      final file = File.fromUri(uri);
      if (await file.exists()) {
        await file.delete();
        return true;
      } else {
        log.warning('File does not exist: $uri');
      }
    } catch (e) {
      log.warning('Error deleting file: $uri', e);
    }
    return false;
  }

  @override
  Future<bool> openFile(Uri uri, {String? mimeType}) async {
    try {
      final filePath = uri.toFilePath();
      return await _downloader.openFile(null, filePath, mimeType);
    } catch (e) {
      log.warning('Error opening file: $uri', e);
      return false;
    }
  }
}

final class _NativeUriUtils extends UriUtils {
  final _methodChannel = MethodChannel(
    'com.bbflight.background_downloader.uriutils',
  );

  _NativeUriUtils(super.downloader);

  @override
  Future<Uri?> pickDirectory({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    bool persistedUriPermission = false,
  }) async {
    final uriString = (await _methodChannel.invokeMethod<String>(
      'pickDirectory',
      [
        startLocation?.index,
        startLocationUri?.toString(),
        persistedUriPermission,
      ],
    ));
    return (uriString != null) ? Uri.parse(uriString) : null;
  }

  @override
  Future<List<Uri>?> pickFiles({
    SharedStorage? startLocation,
    Uri? startLocationUri,
    List<String>? allowedExtensions,
    bool multipleAllowed = false,
    bool persistedUriPermission = false,
  }) async {
    final uriStrings = (await _methodChannel.invokeMethod('pickFiles', [
      startLocation?.index,
      startLocationUri?.toString(),
      allowedExtensions,
      multipleAllowed,
      persistedUriPermission,
    ]));
    // uriStrings can be a list of Strings or just one String, or null
    return switch (uriStrings) {
      final String uri => [Uri.parse(uri)],
      final List<Object?>? uris =>
        uris
            ?.where((e) => e != null)
            .map((e) => Uri.parse(e as String))
            .toList(growable: false),
      _ => throw ArgumentError(
        'pickFiles returned invalid value $uriStrings of type ${uriStrings.runtimeType}',
      ),
    };
  }

  @override
  Future<Uri> createDirectory(
    Uri parentDirectoryUri,
    String newDirectoryName, {
    bool persistedUriPermission = false,
  }) async {
    final uriString = (await _methodChannel.invokeMethod<String>(
      'createDirectory',
      [parentDirectoryUri.toString(), newDirectoryName, persistedUriPermission],
    ));
    return Uri.parse(uriString!);
  }

  /// Retrieves the file data (bytes) for a given URI.
  ///
  /// [uri] is the URI of the file.
  ///
  /// Returns a [Uint8List] containing the file data, or `null` if an error occurred.
  @override
  Future<Uint8List?> getFileBytes(Uri uri) async {
    try {
      final result = await _methodChannel.invokeMethod<Uint8List>(
        'getFileBytes',
        uri.toString(),
      );
      return result;
    } catch (e) {
      log.warning('Error reading file: $e');
      return null;
    }
  }

  @override
  Future<Uri?> copyFile(Uri source, dynamic destination) async {
    final destinationUri = _determineDestinationUri(destination);
    try {
      final result = await _methodChannel.invokeMethod<String>('copyFile', [
        source.toString(),
        destinationUri.toString(),
      ]);
      return result != null ? Uri.parse(result) : null;
    } catch (e) {
      log.warning('Error copying file from $source to $destinationUri', e);
      return null;
    }
  }

  @override
  Future<Uri?> moveFile(Uri source, dynamic destination) async {
    final destinationUri = _determineDestinationUri(destination);
    try {
      final result = await _methodChannel.invokeMethod<String>('moveFile', [
        source.toString(),
        destinationUri.toString(),
      ]);
      return result != null ? Uri.parse(result) : null;
    } catch (e) {
      log.warning('Error moving file from $source to $destinationUri', e);
      return null;
    }
  }

  @override
  Future<bool> deleteFile(Uri uri) async {
    try {
      await _methodChannel.invokeMethod('deleteFile', uri.toString());
      return true;
    } catch (e) {
      log.warning('Error deleting file at URI $uri: $e');
      return false;
    }
  }

  @override
  Future<bool> openFile(Uri uri, {String? mimeType}) async {
    try {
      await _methodChannel.invokeMethod('openFile', [uri.toString(), mimeType]);
      return true;
    } catch (e) {
      log.warning('Error opening file at URI $uri: $e');
      return false;
    }
  }
}

final class _AndroidUriUtils extends _NativeUriUtils {
  _AndroidUriUtils(super.downloader);
}

final class _IOSUriUtils extends _NativeUriUtils {
  _IOSUriUtils(super.downloader);

  @override
  Future<Uri?> activate(Uri uri) async {
    try {
      final result = await _methodChannel.invokeMethod<String?>(
        'activateUri',
        uri.toString(),
      );
      return result != null ? Uri.parse(result) : uri;
    } catch (e) {
      log.fine('Error activating URI $uri: $e');
    }
    return null;
  }
}

/// Extensions on String related to Uri and File
extension StringUriExtensions on String {
  /// Converts this filePath to a file URI
  Uri toFileUri() =>
      Uri.file(this, windows: defaultTargetPlatform == TargetPlatform.windows);
}

/// Extensions on Uri related to File and String
extension UriExtensions on Uri {
  /// Returns the File represented by this [uri]
  File toFile() => File(
    toFilePath(windows: defaultTargetPlatform == TargetPlatform.windows),
  );

  /// True if Uri scheme is file
  bool get isFileUri => scheme == 'file';

  /// True if Uri scheme is content
  bool get isContentUri => scheme == 'content';
}
