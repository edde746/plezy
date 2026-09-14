import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

const sentryCliVersion = '2.58.6';

// Checksums from sentry_dart_plugin 3.4.0's published CLI manifest.
const _downloads = {
  'Darwin-universal': '728d5a8c48d3e94d0a3e644431dcaad19c28b126a00eb37930e67bd146905d96',
  'Linux-aarch64': '79e60095ab461eac70c23ce750499bff5c6bffb95d364ccf38d3259557403987',
  'Linux-armv7': 'a935540e64dc0b73e169a39034975ae326862b517739dc3e6adc7f9d0b47a657',
  'Linux-x86_64': '36b689311b399d9332950d84f4299aee682d2d290a770a77372b30a74f7e7add',
  'Windows-x86_64.exe': '99c1bf7a3d18df2b62ee5052f7e8f5d1e065e218442cdf0cfa2ede0b9cf7b938',
};

Future<String> provisionSymbolCli(String root, Map<String, String> environment, {required bool dryRun}) async {
  final String target;
  if (Platform.isMacOS) {
    target = 'Darwin-universal';
  } else if (Platform.isWindows) {
    target = 'Windows-x86_64.exe';
  } else if (Platform.isLinux) {
    final machine = await Process.run('uname', ['-m']);
    if (machine.exitCode != 0) throw const FormatException('Cannot determine CLI host architecture');
    target = switch (machine.stdout.toString().trim()) {
      'aarch64' || 'arm64' => 'Linux-aarch64',
      'armv7l' => 'Linux-armv7',
      'x86_64' => 'Linux-x86_64',
      _ => throw const FormatException('Unsupported CLI host architecture'),
    };
  } else {
    throw const FormatException('Unsupported CLI host OS');
  }
  final override = environment['SENTRY_CLI_EXECUTABLE'];
  final file = File(
    override != null && override.isNotEmpty
        ? path.absolute(override)
        : path.join(root, '.dart_tool', 'symbol-upload', sentryCliVersion, 'sentry-cli-$target'),
  );
  Future<bool> valid(File value) async =>
      value.existsSync() && (await sha256.bind(value.openRead()).first).toString() == _downloads[target];
  if (await valid(file)) return file.path;
  if (dryRun || (override != null && override.isNotEmpty)) {
    throw FormatException(
      'A checksum-verified sentry-cli $sentryCliVersion is required at ${file.path}; dry-run never downloads it',
    );
  }
  await file.parent.create(recursive: true);
  final temporary = await file.parent.createTemp('download-');
  final download = File(path.join(temporary.path, 'sentry-cli'));
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('https://github.com/getsentry/sentry-cli/releases/download/$sentryCliVersion/sentry-cli-$target'),
    );
    final response = await request.close();
    if (response.statusCode != 200) throw HttpException('CLI download HTTP ${response.statusCode}');
    final sink = download.openWrite();
    await response.pipe(sink);
    if (!await valid(download)) throw const FormatException('Downloaded CLI checksum mismatch');
    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', ['755', download.path]);
      if (chmod.exitCode != 0) throw const FileSystemException('Cannot make CLI executable');
    }
    await download.rename(file.path);
  } finally {
    client.close(force: true);
    await temporary.delete(recursive: true);
  }
  return file.path;
}
