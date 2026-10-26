/// Compile-time stub used only for tvOS, where dart_smb2 has no native asset.
///
/// SMB sources remain hidden and rejected by PlezyNG's platform guard on
/// tvOS. This package exists so the shared source adapter compiles in the
/// Apple TV application without attempting to link an unsupported library.
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
  const Smb2Exception({required this.type, this.message = 'SMB is unsupported on tvOS'});

  final Smb2ErrorType type;
  final String message;

  @override
  String toString() => message;
}

class Smb2CancelToken {
  void cancel() {}
}

class Smb2Stat {
  Smb2Stat({this.size = 0, DateTime? modified, this.isHidden = false, this.isFile = true})
    : modified = modified ?? DateTime.fromMillisecondsSinceEpoch(0);

  final int size;
  final DateTime modified;
  final bool isHidden;
  final bool isFile;
}

class Smb2DirectoryEntry {
  const Smb2DirectoryEntry({
    required this.name,
    required this.stat,
    this.isDirectory = false,
    this.isFile = true,
  });

  final String name;
  final Smb2Stat stat;
  final bool isDirectory;
  final bool isFile;
  int get size => stat.size;
}

class Smb2File {
  Future<List<int>> read({required int offset, required int length}) async =>
      throw const Smb2Exception(type: Smb2ErrorType.notSupported);
}

class Smb2Pool {
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
  }) async => throw const Smb2Exception(type: Smb2ErrorType.notSupported);

  Future<List<Smb2DirectoryEntry>> listDirectory(String path) async =>
      throw const Smb2Exception(type: Smb2ErrorType.notSupported);

  Future<Smb2Stat> stat(String path) async => throw const Smb2Exception(type: Smb2ErrorType.notSupported);

  Future<T> withFile<T>(
    String path,
    Future<T> Function(Smb2File file) action, {
    int? knownSize,
    Smb2CancelToken? cancelToken,
  }) async => throw const Smb2Exception(type: Smb2ErrorType.notSupported);

  Future<void> disconnect() async {}
}
