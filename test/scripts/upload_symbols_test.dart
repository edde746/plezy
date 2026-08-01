import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../scripts/upload_symbols.dart';

void main() {
  late Directory repository;

  setUp(() async {
    repository = await Directory.systemTemp.createTemp('plezy_upload_symbols_');
  });

  tearDown(() async {
    await repository.delete(recursive: true);
  });

  test('discovers symbols and passes the complete upload request to the plugin', () async {
    final symbolRoot = Directory(path.join(repository.path, 'debug-info', 'linux-x64'))..createSync(recursive: true);
    File(path.join(symbolRoot.path, 'symbols.zip')).writeAsStringSync('symbols');
    final symbolMap = File(path.join(symbolRoot.path, 'obfuscation.map.json'))..writeAsStringSync('{}');
    late List<String> uploadArguments;
    late Map<String, String> uploadEnvironment;
    late String uploadWorkingDirectory;

    final result = await runUploadSymbols(
      const ['linux-x64'],
      repositoryRoot: repository,
      environment: const {
        'BUGS_ADMIN_TOKEN': 'admin-token',
        'BUGS_URL': 'https://bugs.example.test',
        'SENTRY_RELEASE': 'plezy@test',
        'SENTRY_DIST': 'test-linux',
      },
      uploader: ({required arguments, required environment, required workingDirectory}) async {
        uploadArguments = arguments;
        uploadEnvironment = environment;
        uploadWorkingDirectory = workingDirectory;
        return 0;
      },
    );

    expect(result, 0);
    expect(uploadWorkingDirectory, path.normalize(path.absolute(repository.path)));
    expect(uploadEnvironment['SENTRY_AUTH_TOKEN'], 'admin-token');
    expect(uploadEnvironment['SENTRY_LOG_LEVEL'], 'info');
    expect(uploadArguments, [
      '--sentry-define=release=plezy@test',
      '--sentry-define=url=https://bugs.example.test',
      '--sentry-define=build_path=${path.join(repository.path, 'build')}',
      '--sentry-define=dist=test-linux',
      '--sentry-define=symbols_path=${symbolRoot.path}',
      '--sentry-define=dart_symbol_map_path=${symbolMap.path}',
    ]);
  });

  test('rejects missing platform, symbols, and credentials', () async {
    final errors = StringBuffer();
    expect(await runUploadSymbols(const [], repositoryRoot: repository, errors: errors), 1);
    expect(errors.toString(), contains('platform arg required'));

    errors.clear();
    expect(
      await runUploadSymbols(
        const ['windows-x64'],
        repositoryRoot: repository,
        environment: const {'SENTRY_RELEASE': 'plezy@test'},
        errors: errors,
      ),
      3,
    );
    expect(errors.toString(), contains('no symbols found'));

    Directory(path.join(repository.path, 'debug-info', 'windows-x64')).createSync(recursive: true);
    File(path.join(repository.path, 'debug-info', 'windows-x64', 'symbols.zip')).writeAsStringSync('symbols');
    errors.clear();
    expect(
      await runUploadSymbols(
        const ['windows-x64'],
        repositoryRoot: repository,
        environment: const {'SENTRY_RELEASE': 'plezy@test'},
        errors: errors,
      ),
      1,
    );
    expect(errors.toString(), contains('SENTRY_AUTH_TOKEN or BUGS_ADMIN_TOKEN env var required'));
  });

  test('propagates an HTTP upload failure without network access', () async {
    final symbolRoot = Directory(path.join(repository.path, 'debug-info', 'android-apk'))..createSync(recursive: true);
    File(path.join(symbolRoot.path, 'symbols.zip')).writeAsStringSync('symbols');
    final errors = StringBuffer();

    final result = await runUploadSymbols(
      const ['android-apk'],
      repositoryRoot: repository,
      environment: const {'SENTRY_AUTH_TOKEN': 'token', 'SENTRY_RELEASE': 'plezy@test'},
      errors: errors,
      uploader: ({required arguments, required environment, required workingDirectory}) async => 22,
    );

    expect(result, 22);
    expect(errors.toString(), contains('symbol upload failed for android-apk (exit code 22)'));
  });
}
