/// Stub implementations of dart:io types for web compilation.
/// These should never be instantiated at runtime on web — they exist
/// only so that code referencing File/Directory compiles on all platforms.

class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);
}

class File extends FileSystemEntity {
  File(super.path);
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<File> writeAsBytes(List<int> bytes) async => this;
  Future<File> writeAsString(String contents) async => this;
  Future<String> readAsString() async => '';
  Future<int> length() async => 0;
  int lengthSync() => 0;
  Future<void> delete({bool recursive = false}) async {}
  void deleteSync({bool recursive = false}) {}
  Future<File> rename(String newPath) async => File(newPath);
  Future<File> copy(String newPath) async => File(newPath);
  Directory get parent => Directory(path.substring(0, path.lastIndexOf('/')));
}

class Directory extends FileSystemEntity {
  Directory(super.path);
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) => const Stream.empty();
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) => [];
  Directory get parent => Directory(path.substring(0, path.lastIndexOf('/')));
}

/// Stub for dart:io Process.
class Process {
  final int pid = 0;
  static Future<Process> start(
    String executable,
    List<String> arguments, {
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    throw UnsupportedError('Process.start is not supported on web');
  }

  static Future<ProcessResult> run(String executable, List<String> arguments) async {
    throw UnsupportedError('Process.run is not supported on web');
  }
}

/// Stub for dart:io ProcessStartMode.
class ProcessStartMode {
  static const normal = ProcessStartMode._('normal');
  static const detached = ProcessStartMode._('detached');
  final String _name;
  const ProcessStartMode._(this._name);
  @override
  String toString() => _name;
}

/// Stub for dart:io ProcessResult.
class ProcessResult {
  final int exitCode;
  final dynamic stdout;
  final dynamic stderr;
  final int pid;
  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}
