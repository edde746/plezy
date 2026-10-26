import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../exceptions.dart';

final _log = Logger('FileDownloader');

/// Live capacity on the filesystem containing [path], including mounted volumes.
/// The native APIs return bytes available to this user, not privileged free space.
/// Throws when the filesystem cannot be queried.
({int available, int total}) desktopVolumeCapacity(String path) {
  var directory = Directory(path).absolute;
  if (FileSystemEntity.isFileSync(directory.path)) {
    directory = File(File(directory.path).resolveSymbolicLinksSync()).parent;
  }
  while (!directory.existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw const FileSystemException('No existing target ancestor');
    }
    directory = parent;
  }
  return _NativeCapacity.instance.query(directory.resolveSymbolicLinksSync());
}

/// Whether [error] is the filesystem refusing a write for lack of space.
/// Matches the OS error code because the message text is localized.
bool isOutOfSpaceError(Object error) {
  if (error is! FileSystemException) return false;
  final code = error.osError?.errorCode;
  // ERROR_HANDLE_DISK_FULL, ERROR_DISK_FULL; ENOSPC on Linux and macOS.
  return Platform.isWindows ? code == 39 || code == 112 : code == 28;
}

/// Checks actual target-volume capacity before each bounded, drained write.
///
/// A volume that cannot report its capacity (some network and FUSE mounts
/// report zero) is not checked; a write that then runs out of space still
/// fails as a storage failure through [isOutOfSpaceError].
class StorageSpaceGuard {
  static const writeSize = 1024 * 1024;
  final String path;
  final int configuration;
  final ({int available, int total}) Function(String) _capacity;

  StorageSpaceGuard(
    this.path,
    this.configuration, {
    ({int available, int total}) Function(String)? capacity,
  }) : _capacity = capacity ?? desktopVolumeCapacity;

  void check([int requiredBytes = 0]) {
    if (configuration == 0) return;
    final ({int available, int total}) capacity;
    try {
      capacity = _capacity(path);
    } catch (error) {
      _skipUnknownCapacity(error);
      return;
    }
    if (capacity.total <= 0 || capacity.available < 0) {
      _skipUnknownCapacity(
        'reported ${capacity.available} of ${capacity.total} bytes available',
      );
      return;
    }
    final floor = configuration < 0
        ? max(256 * 1024 * 1024, capacity.total ~/ 100)
        : configuration * 1024 * 1024;
    if (capacity.available - max(0, requiredBytes) < floor) {
      throw TaskFileSystemException(
        'Insufficient space to store download on $path',
      );
    }
  }

  var _loggedUnknownCapacity = false;

  void _skipUnknownCapacity(Object reason) {
    if (_loggedUnknownCapacity) return;
    _loggedUnknownCapacity = true;
    _log.warning(
      'Storage capacity of $path is unknown, not checking free space: $reason',
    );
  }

  Future<void> write(IOSink sink, List<int> bytes) async {
    for (var offset = 0; offset < bytes.length; offset += writeSize) {
      final end = min(offset + writeSize, bytes.length);
      check(end - offset);
      sink.add(offset == 0 && end == bytes.length
          ? bytes
          : bytes is Uint8List
              ? Uint8List.sublistView(bytes, offset, end)
              : bytes.sublist(offset, end));
      // Bound queued writes, so the next capacity sample accounts for this one.
      await sink.flush();
    }
  }
}

/// Copy to a task-owned staging file, never truncate an existing final file.
/// The caller publishes by rename only after successful completion.
Future<void> copyWithSpaceGuard(
  File source,
  File staging,
  int configuration,
) async {
  final guard = StorageSpaceGuard(staging.path, configuration);
  IOSink? sink;
  var complete = false;
  try {
    guard.check(await source.length());
    await staging.parent.create(recursive: true);
    sink = staging.openWrite();
    // Observe asynchronous sink failures even when the read fails first.
    sink.done.ignore();
    await for (final bytes in source.openRead()) {
      await guard.write(sink, bytes);
    }
    await sink.close();
    sink = null;
    complete = true;
  } finally {
    try {
      await sink?.close();
    } catch (_) {}
    if (!complete && await staging.exists()) await staging.delete();
  }
}

final class _NativeCapacity {
  static final instance = _NativeCapacity();
  final DynamicLibrary _allocator = Platform.isWindows
      ? DynamicLibrary.open('msvcrt.dll')
      : DynamicLibrary.process();
  late final _calloc = _allocator.lookupFunction<
      Pointer<Void> Function(IntPtr, IntPtr),
      Pointer<Void> Function(int, int)>('calloc');
  late final _free = _allocator.lookupFunction<Void Function(Pointer<Void>),
      void Function(Pointer<Void>)>('free');
  // Darwin's statvfs has 32-bit block counts (fsblkcnt_t is unsigned int).
  // statfs has 64-bit counts in its 64-bit-inode layout, which Intel binaries
  // bind through the statfs$INODE64 symbol.
  late final _statfs = DynamicLibrary.process().lookupFunction<
          Int32 Function(Pointer<Uint8>, Pointer<Void>),
          int Function(Pointer<Uint8>, Pointer<Void>)>(
      Abi.current() == Abi.macosX64 ? r'statfs$INODE64' : 'statfs');
  late final _statvfs = DynamicLibrary.process().lookupFunction<
      Int32 Function(Pointer<Uint8>, Pointer<Void>),
      int Function(Pointer<Uint8>, Pointer<Void>)>('statvfs');
  late final _diskFree = DynamicLibrary.open('kernel32.dll').lookupFunction<
      Int32 Function(Pointer<Uint16>, Pointer<Uint64>, Pointer<Uint64>,
          Pointer<Uint64>),
      int Function(Pointer<Uint16>, Pointer<Uint64>, Pointer<Uint64>,
          Pointer<Uint64>)>('GetDiskFreeSpaceExW');

  ({int available, int total}) query(String directory) {
    // Flutter's supported desktop ABIs are 64-bit. The buffer is larger than
    // every queried structure (Darwin's struct statfs is 2168 bytes).
    if (sizeOf<IntPtr>() != 8) {
      throw UnsupportedError('32-bit desktop filesystem capacity');
    }
    final encoded = Platform.isWindows
        ? directory.codeUnits
        : utf8.encode(directory);
    final name = _calloc(encoded.length + 1, Platform.isWindows ? 2 : 1);
    final data = _calloc(1, 4096);
    try {
      if (name == nullptr || data == nullptr) {
        throw const FileSystemException('Native capacity allocation failed');
      }
      final values = data.cast<Uint64>();
      if (Platform.isWindows) {
        name.cast<Uint16>().asTypedList(encoded.length).setAll(0, encoded);
        if (_diskFree(name.cast<Uint16>(), values, values + 1, values + 2) == 0) {
          throw const FileSystemException('GetDiskFreeSpaceExW failed');
        }
        return (available: values[0], total: values[1]);
      }
      name.cast<Uint8>().asTypedList(encoded.length).setAll(0, encoded);
      if (Platform.isMacOS) {
        // struct statfs: uint32_t f_bsize @0, uint64_t f_blocks @8,
        // f_bfree @16, f_bavail @24.
        if (_statfs(name.cast<Uint8>(), data) != 0) {
          throw const FileSystemException('statfs failed');
        }
        final blockSize = data.cast<Uint32>()[0];
        return (available: values[3] * blockSize, total: values[1] * blockSize);
      }
      if (!Platform.isLinux) {
        throw UnsupportedError('Desktop filesystem capacity on this platform');
      }
      // 64-bit glibc and musl: unsigned long f_bsize, f_frsize, then 64-bit
      // f_blocks, f_bfree, f_bavail.
      if (_statvfs(name.cast<Uint8>(), data) != 0) {
        throw const FileSystemException('statvfs failed');
      }
      return (
        available: values[4] * values[1],
        total: values[2] * values[1],
      );
    } finally {
      _free(name);
      _free(data);
    }
  }
}
