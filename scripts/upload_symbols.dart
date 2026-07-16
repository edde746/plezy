import 'dart:io';

import 'package:path/path.dart' as path;

typedef SymbolUploader =
    Future<int> Function({
      required List<String> arguments,
      required Map<String, String> environment,
      required String workingDirectory,
    });

const _defaultSentryUrl = 'https://bugs.plezy.app';

Future<void> main(List<String> arguments) async {
  final scriptDirectory = File.fromUri(Platform.script).parent;
  final result = await runUploadSymbols(arguments, repositoryRoot: scriptDirectory.parent);
  if (result != 0) {
    exitCode = result;
  }
}

Future<int> runUploadSymbols(
  List<String> arguments, {
  required Directory repositoryRoot,
  Map<String, String>? environment,
  SymbolUploader uploader = _runSentryPlugin,
  Future<String?> Function()? revisionProvider,
  StringSink? output,
  StringSink? errors,
}) async {
  final out = output ?? stdout;
  final err = errors ?? stderr;
  if (arguments.isEmpty || arguments.first.isEmpty) {
    err.writeln('platform arg required');
    return 1;
  }

  final platform = arguments.first;
  final root = path.normalize(path.absolute(repositoryRoot.path));
  final sourceArgument = arguments.length > 1 ? arguments[1] : '';
  final sourceRoot = sourceArgument.isEmpty
      ? root
      : path.normalize(path.isAbsolute(sourceArgument) ? sourceArgument : path.join(root, sourceArgument));
  final buildRoot = path.join(sourceRoot, 'build');
  final symbolRoot = path.join(sourceRoot, 'debug-info', platform);

  final searchRoots = <String>[];
  void addExistingRoot(String candidate) {
    if (Directory(candidate).existsSync()) {
      searchRoots.add(candidate);
    }
  }

  addExistingRoot(symbolRoot);
  switch (platform) {
    case 'macos':
      addExistingRoot(path.join(buildRoot, 'macos'));
    case 'ios':
      addExistingRoot(path.join(buildRoot, 'ios'));
      addExistingRoot(path.join(sourceRoot, 'ios', 'build'));
    case 'linux-x64' || 'linux-arm64':
      addExistingRoot(path.join(buildRoot, 'linux'));
    case 'android-apk' || 'android-aab':
      addExistingRoot(path.join(buildRoot, 'app'));
    case 'windows-x64' || 'windows-arm64':
      addExistingRoot(path.join(buildRoot, 'windows'));
    default:
      err.writeln('unknown platform: $platform');
      return 2;
  }

  final symbolFiles = _discoverFiles(searchRoots);
  if (symbolFiles.isEmpty) {
    err.writeln('no symbols found for platform $platform');
    return 3;
  }

  final childEnvironment = Map<String, String>.of(environment ?? Platform.environment);
  final dryRun = _isNotEmpty(childEnvironment['BUGS_UPLOAD_DRY_RUN']);
  childEnvironment['SENTRY_URL'] = _firstNotEmpty([
    childEnvironment['SENTRY_URL'],
    childEnvironment['BUGS_URL'],
    _defaultSentryUrl,
  ]);
  childEnvironment['SENTRY_LOG_LEVEL'] = _firstNotEmpty([childEnvironment['SENTRY_LOG_LEVEL'], 'info']);
  if (!_isNotEmpty(childEnvironment['SENTRY_AUTH_TOKEN']) && _isNotEmpty(childEnvironment['BUGS_ADMIN_TOKEN'])) {
    childEnvironment['SENTRY_AUTH_TOKEN'] = childEnvironment['BUGS_ADMIN_TOKEN']!;
  }
  if (!dryRun && !_isNotEmpty(childEnvironment['SENTRY_AUTH_TOKEN'])) {
    err.writeln('SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN env var required');
    return 1;
  }

  if (!_isNotEmpty(childEnvironment['SENTRY_RELEASE'])) {
    final revision = await (revisionProvider?.call() ?? _gitRevision(root));
    if (!_isNotEmpty(revision)) {
      err.writeln('failed to determine SENTRY_RELEASE from git');
      return 1;
    }
    childEnvironment['SENTRY_RELEASE'] = 'plezy@$revision';
  }

  var dartSymbolMapPath = childEnvironment['SENTRY_DART_SYMBOL_MAP_PATH'] ?? '';
  if (dartSymbolMapPath.isEmpty) {
    for (final candidate in [
      path.join(symbolRoot, 'obfuscation.map.json'),
      path.join(buildRoot, 'app', 'obfuscation', '$platform.map.json'),
      path.join(buildRoot, 'app', 'obfuscation.map.json'),
    ]) {
      if (File(candidate).existsSync()) {
        dartSymbolMapPath = candidate;
        break;
      }
    }
  }

  final release = childEnvironment['SENTRY_RELEASE']!;
  final dist = childEnvironment['SENTRY_DIST'] ?? '';
  final pluginArguments = <String>[
    '--sentry-define=release=$release',
    '--sentry-define=url=${childEnvironment['SENTRY_URL']}',
    '--sentry-define=build_path=$buildRoot',
    if (dist.isNotEmpty) '--sentry-define=dist=$dist',
    if (Directory(symbolRoot).existsSync()) '--sentry-define=symbols_path=$symbolRoot',
    if (dartSymbolMapPath.isNotEmpty) '--sentry-define=dart_symbol_map_path=$dartSymbolMapPath',
  ];

  if (dryRun) {
    out.writeln('dry-run: would upload symbols for $platform');
    out.writeln('dry-run: release=$release');
    out.writeln('dry-run: dist=$dist');
    out.writeln('dry-run: source_root=$sourceRoot');
    out.writeln('dry-run: build_path=$buildRoot');
    out.writeln('dry-run: symbols_path=$symbolRoot');
    out.writeln('dry-run: dart_symbol_map_path=$dartSymbolMapPath');
    for (final file in symbolFiles) {
      out.writeln(file);
    }
    return 0;
  }

  out.writeln('uploading symbols for $platform release $release dist $dist');
  try {
    final result = await uploader(arguments: pluginArguments, environment: childEnvironment, workingDirectory: root);
    if (result != 0) {
      err.writeln('symbol upload failed for $platform (exit code $result)');
    }
    return result;
  } on ProcessException catch (error) {
    err.writeln('failed to start symbol upload: $error');
    return 1;
  }
}

List<String> _discoverFiles(List<String> roots) {
  final files = <String>[];
  for (final root in roots) {
    try {
      files.addAll(
        Directory(root)
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .map((file) => path.normalize(path.absolute(file.path))),
      );
    } on FileSystemException {
      // Match the wrappers' previous best-effort discovery behavior.
    }
  }
  files.sort();
  return files;
}

Future<String?> _gitRevision(String root) async {
  try {
    final result = await Process.run('git', const ['rev-parse', '--short', 'HEAD'], workingDirectory: root);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
  } on ProcessException {
    return null;
  }
  return null;
}

Future<int> _runSentryPlugin({
  required List<String> arguments,
  required Map<String, String> environment,
  required String workingDirectory,
}) async {
  final process = await Process.start(
    Platform.resolvedExecutable,
    ['run', 'sentry_dart_plugin', ...arguments],
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: false,
    mode: ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

bool _isNotEmpty(String? value) => value != null && value.isNotEmpty;

String _firstNotEmpty(List<String?> values) => values.firstWhere(_isNotEmpty)!;
