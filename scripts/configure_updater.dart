import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';

const upstreamPublicKey = 'q7t6eu1txRrqv1PeWDCRV95rFxnmD/D3GZWbUPMwUyU=';

/// Configure only a repository-owned trust root. Never generate a release
/// private key in CI or silently reuse the upstream application's key.
Future<void> main() async {
  try {
    final environment = Platform.environment;
    final publicKey = (environment['SPARKLE_PUBLIC_KEY'] ?? '').trim();
    final privateKey = (environment['SPARKLE_PRIVATE_KEY'] ?? '').trim();
    final repository = environment['GITHUB_REPOSITORY'] ?? '';
    if (publicKey.isNotEmpty) {
      final bytes = base64Decode(publicKey);
      if (bytes.length != 32 || base64Encode(bytes) != publicKey) {
        throw StateError('SPARKLE_PUBLIC_KEY must be a canonical base64 Ed25519 public key');
      }
      if (repository != 'edde746/plezy' && publicKey == upstreamPublicKey) {
        throw StateError('A fork must configure its own updater public key');
      }
    }
    if (privateKey.isNotEmpty) {
      if (publicKey.isEmpty) throw StateError('Signing requires SPARKLE_PUBLIC_KEY');
      final seed = base64Decode(
        privateKey
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty && !line.startsWith('-----'))
            .join(),
      );
      if (seed.length != 32) throw StateError('Expected a 32-byte Ed25519 signing seed');
      final pair = await Ed25519().newKeyPairFromSeed(seed);
      if (base64Encode((await pair.extractPublicKey()).bytes) != publicKey) {
        throw StateError('Updater signing key does not match the embedded public key');
      }
    }

    final plist = File('macos/Runner/Info.plist');
    final resource = File('windows/runner/Runner.rc');
    final plistText = await plist.readAsString();
    final resourceText = await resource.readAsString();
    final plistPattern = RegExp(r'(<key>SUPublicEDKey</key>\s*<string>)[^<]*(</string>)');
    final resourcePattern = RegExp(r'EdDSAPub EDDSA \{"[^"]*"\}');
    if (!plistPattern.hasMatch(plistText) || !resourcePattern.hasMatch(resourceText)) {
      throw StateError('Updater trust-root resource was not found');
    }
    await plist.writeAsString(
      plistText.replaceFirstMapped(plistPattern, (match) => '${match[1]}$publicKey${match[2]}'),
    );
    await resource.writeAsString(resourceText.replaceFirst(resourcePattern, 'EdDSAPub EDDSA {"$publicKey"}'));
    final githubEnv = environment['GITHUB_ENV'];
    if (githubEnv != null) {
      await File(githubEnv).writeAsString(
        'NATIVE_UPDATER_DEFINE=--dart-define=NATIVE_UPDATER_CONFIGURED=${publicKey.isNotEmpty}\n',
        mode: FileMode.append,
      );
    }
    stdout.writeln(
      publicKey.isEmpty
          ? 'Native updater disabled; GitHub release checks remain available.'
          : 'Repository updater trust root configured.',
    );
  } catch (_) {
    // Never echo parsing exceptions that might contain signing material.
    stderr.writeln(
      'Updater configuration failed: check the repository public key and matching 32-byte signing seed. Forks cannot reuse the upstream key.',
    );
    exitCode = 1;
  }
}
