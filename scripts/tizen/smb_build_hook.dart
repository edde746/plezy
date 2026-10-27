// Installed only into the isolated Tizen build's dart_smb2 0.2.3 copy.
// The normal package rejects Linux ARM before considering custom libraries.
// These are direct dependencies of the staged dart_smb2 package.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    final code = input.config.code;
    if (code.targetOS != OS.linux ||
        (code.targetArchitecture != Architecture.arm && code.targetArchitecture != Architecture.x64)) {
      throw UnsupportedError('This hook is only for Samsung TV ARM or x64 emulator builds.');
    }
    final source = input.userDefines.path('libsmb2');
    if (source == null || !File.fromUri(source).existsSync()) throw StateError('A Tizen-built libsmb2 is required.');
    final target = File.fromUri(input.outputDirectory.resolve('libdart_smb2.so'));
    await File.fromUri(source).copy(target.path);
    output.dependencies.add(source);
    output.assets.code.add(
      CodeAsset(package: input.packageName, name: 'libsmb2', linkMode: DynamicLoadingBundled(), file: target.uri),
    );
  });
}
