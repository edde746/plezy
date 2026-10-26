import 'package:flutter/services.dart';

const MethodChannel _smbChannel = MethodChannel('org.snapetech.plezyng/smb2');

enum Smb2Version { any, any3 }

enum Smb2ErrorType {
  auth,
  accessDenied,
  cancelled,
  notSupported,
  invalidParam,
  notFound,
  notADirectory,
  isADirectory,
  network,
}

class Smb2Exception implements Exception {
  const Smb2Exception({required this.type, this.message = 'SMB request failed'});

  final Smb2ErrorType type;
  final String message;

  @override
  String toString() => 'Smb2Exception(${type.name})';
}

class Smb2CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class Smb2Stat {
  Smb2Stat({this.size = 0, DateTime? modified, this.isHidden = false, this.isFile = true, this.isDirectory = false})
    : modified = modified ?? DateTime.fromMillisecondsSinceEpoch(0);

  final int size;
  final DateTime modified;
  final bool isHidden;
  final bool isFile;
  final bool isDirectory;
}

class Smb2DirectoryEntry {
  const Smb2DirectoryEntry({required this.name, required this.stat, this.isDirectory = false, this.isFile = true});

  final String name;
  final Smb2Stat stat;
  final bool isDirectory;
  final bool isFile;
  int get size => stat.size;
}

class Smb2File {
  const Smb2File._(this._pool, this._path, this._cancelToken);

  final Smb2Pool _pool;
  final String _path;
  final Smb2CancelToken? _cancelToken;

  Future<List<int>> read({required int offset, required int length}) =>
      _pool._read(_path, offset, length, _cancelToken);
}

class Smb2Pool {
  Smb2Pool._(this._handle);

  final String _handle;
  bool _closed = false;

  static Future<Smb2Pool> connect({
    required String host,
    required String share,
    String? user,
    String? password,
    String? domain,
    int workers = 2,
    bool seal = false,
    Smb2Version version = Smb2Version.any,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final handle = await _invoke<String>('connect', {
      'host': host,
      'share': share,
      'user': user,
      'password': password,
      'domain': domain,
      'workers': workers,
      'seal': seal,
      'version': version.name,
      'timeoutMilliseconds': timeout.inMilliseconds,
    });
    if (handle == null || handle.isEmpty) {
      throw const Smb2Exception(type: Smb2ErrorType.network);
    }
    return Smb2Pool._(handle);
  }

  Future<List<Smb2DirectoryEntry>> listDirectory(String path) async {
    _ensureOpen();
    final rows = await _invoke<List<dynamic>>('listDirectory', _arguments({'path': path}));
    return (rows ?? const <dynamic>[])
        .whereType<Map>()
        .map((raw) {
          final row = Map<Object?, Object?>.from(raw);
          final stat = _stat(row);
          return Smb2DirectoryEntry(
            name: row['name'] as String? ?? '',
            stat: stat,
            isDirectory: stat.isDirectory,
            isFile: stat.isFile,
          );
        })
        .where((row) => row.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<Smb2Stat> stat(String path) async {
    _ensureOpen();
    final result = await _invoke<Map<dynamic, dynamic>>('stat', _arguments({'path': path}));
    if (result == null) throw const Smb2Exception(type: Smb2ErrorType.network);
    return _stat(Map<Object?, Object?>.from(result));
  }

  Future<T> withFile<T>(
    String path,
    Future<T> Function(Smb2File file) action, {
    int? knownSize,
    Smb2CancelToken? cancelToken,
  }) async {
    _ensureOpen();
    if (cancelToken?.isCancelled == true) {
      throw const Smb2Exception(type: Smb2ErrorType.cancelled);
    }
    final value = await action(Smb2File._(this, path, cancelToken));
    if (cancelToken?.isCancelled == true) {
      throw const Smb2Exception(type: Smb2ErrorType.cancelled);
    }
    return value;
  }

  Future<List<int>> _read(String path, int offset, int length, Smb2CancelToken? cancelToken) async {
    _ensureOpen();
    if (cancelToken?.isCancelled == true) {
      throw const Smb2Exception(type: Smb2ErrorType.cancelled);
    }
    if (offset < 0 || length < 0 || length > 8 * 1024 * 1024) {
      throw const Smb2Exception(type: Smb2ErrorType.invalidParam);
    }
    try {
      final bytes = await _invoke<Uint8List>('read', _arguments({'path': path, 'offset': offset, 'length': length}));
      if (cancelToken?.isCancelled == true) {
        throw const Smb2Exception(type: Smb2ErrorType.cancelled);
      }
      return bytes?.toList(growable: false) ?? const <int>[];
    } on Smb2Exception {
      rethrow;
    } catch (error) {
      throw _translate(error);
    }
  }

  Future<void> disconnect() async {
    if (_closed) return;
    _closed = true;
    try {
      await _invoke<Object?>('disconnect', {'handle': _handle});
    } catch (_) {
      // The owning source may be shutting down during app or profile teardown.
    }
  }

  Map<String, Object?> _arguments(Map<String, Object?> values) => {...values, 'handle': _handle};

  void _ensureOpen() {
    if (_closed) throw const Smb2Exception(type: Smb2ErrorType.cancelled);
  }

  static Smb2Stat _stat(Map<Object?, Object?> row) => Smb2Stat(
    size: (row['size'] as num?)?.toInt() ?? 0,
    modified: DateTime.fromMillisecondsSinceEpoch((row['modified'] as num?)?.toInt() ?? 0),
    isHidden: row['isHidden'] == true,
    isFile: row['isFile'] == true,
    isDirectory: row['isDirectory'] == true,
  );
}

Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
  try {
    final value = await _smbChannel.invokeMethod<Object?>(method, arguments);
    return value as T?;
  } on PlatformException catch (error) {
    throw Smb2Exception(type: _errorType(error.code));
  } on MissingPluginException {
    throw const Smb2Exception(type: Smb2ErrorType.network);
  }
}

Smb2Exception _translate(Object error) {
  if (error is PlatformException) return Smb2Exception(type: _errorType(error.code));
  if (error is MissingPluginException) return const Smb2Exception(type: Smb2ErrorType.network);
  return const Smb2Exception(type: Smb2ErrorType.network);
}

Smb2ErrorType _errorType(String code) => switch (code) {
  'auth' => Smb2ErrorType.auth,
  'accessDenied' => Smb2ErrorType.accessDenied,
  'cancelled' => Smb2ErrorType.cancelled,
  'notSupported' => Smb2ErrorType.notSupported,
  'invalidParam' => Smb2ErrorType.invalidParam,
  'notFound' => Smb2ErrorType.notFound,
  'notADirectory' => Smb2ErrorType.notADirectory,
  'isADirectory' => Smb2ErrorType.isADirectory,
  _ => Smb2ErrorType.network,
};

