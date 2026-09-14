import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// The vendored `_writePreferences` patch, exercised against a real file
/// system.
///
/// Upstream writes the whole preference document with a bare
/// `writeAsStringSync`, which opens with the default `FileMode.write` and so
/// truncates the live file before writing it. Every preference write therefore
/// has a window in which the only copy on disk is empty or half-written, and
/// the store holds the credential-vault key — the corruption behind #1732.
///
/// `shared_preferences_linux` and `shared_preferences_windows` carry the same
/// patch and are byte-identical apart from their path-provider type, so the
/// Linux copy stands in for both here. Windows rename semantics
/// (`MoveFileExW` with MOVEFILE_REPLACE_EXISTING) cannot be proven on a POSIX
/// host and are covered by the windows-latest step in CI.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late File store;
  late File staging;
  late SharedPreferencesAsyncLinux backend;

  const options = SharedPreferencesOptions();

  setUp(() async {
    support = await Directory.systemTemp.createTemp('plezy_atomic_write_');
    store = File(p.join(support.path, prefsStoreFileName));
    staging = File('${store.path}.tmp');
    backend = SharedPreferencesAsyncLinux()..pathProvider = _TempPathProviderLinux(support.path);
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test('a write leaves no staging file behind', () async {
    await backend.setString('theme', 'dark', options);

    expect(await store.exists(), isTrue);
    expect(jsonDecode(await store.readAsString()), containsPair('theme', 'dark'));
    expect(await staging.exists(), isFalse);
  });
  test('a write replaces the document rather than rewriting it in place', () async {
    await backend.setString('theme', 'dark', options);

    // A hard link names the same inode as the store. Under upstream's
    // truncate-then-write the link would observe the new content, because the
    // live file is rewritten underneath every reader holding it open — the
    // window that makes an interrupted write destroy the document. Under an
    // atomic rename the old inode is simply unlinked from the path, so the
    // witness keeps exactly what a reader mid-write would still have seen.
    final witness = File(p.join(support.path, 'witness.json'));
    if (!_run('ln', [store.path, witness.path])) {
      // Windows has no `ln` on PATH at all, and NTFS replacement is covered by
      // prefs_store_atomic_write_windows_test.dart instead.
      markTestSkipped('hard links are unavailable here');
      return;
    }

    await backend.setString('theme', 'light', options);

    expect(jsonDecode(await witness.readAsString()), containsPair('theme', 'dark'));
    expect(jsonDecode(await store.readAsString()), containsPair('theme', 'light'));
  });

  test('an interrupted write leaves the live document valid', () async {
    await backend.setString('theme', 'dark', options);
    final intact = await store.readAsString();

    // What an interruption leaves once writes are staged: a half-written
    // staging file that was never renamed. The invariant this guards is that
    // the staging file is never itself the live document.
    await staging.writeAsString('{"theme":"light","trunc', flush: true);

    expect(await store.readAsString(), intact);
    expect(PrefsRecovery.describeStoreDamage(await store.readAsBytes()), isNull);
  });

  test('a stale staging file is swept once the document reads cleanly', () async {
    await backend.setString('theme', 'dark', options);
    await staging.writeAsString('{"credential_vault_key_v1":"left-behind"', flush: true);

    // The staging file is a plaintext copy of the credentials, so it must not
    // outlive the interrupted write that produced it.
    final reader = SharedPreferencesAsyncLinux()..pathProvider = _TempPathProviderLinux(support.path);
    await reader.getPreferences(const GetPreferencesParameters(filter: PreferencesFilters()), options);

    expect(await staging.exists(), isFalse);
    expect(jsonDecode(await store.readAsString()), containsPair('theme', 'dark'));
  });

  test('writing into a directory that does not exist yet still lands', () async {
    final nested = Directory(p.join(support.path, 'nested'));
    final nestedBackend = SharedPreferencesAsyncLinux()..pathProvider = _TempPathProviderLinux(nested.path);

    await nestedBackend.setString('theme', 'dark', options);

    expect(
      jsonDecode(await File(p.join(nested.path, prefsStoreFileName)).readAsString()),
      containsPair('theme', 'dark'),
    );
  });
}

class _TempPathProviderLinux extends PathProviderLinux {
  _TempPathProviderLinux(this.supportPath);

  final String supportPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;
}

/// Runs a POSIX helper, reporting whether it succeeded.
///
/// Returns false rather than throwing when the binary is missing, so a Windows
/// run reaches `markTestSkipped` instead of failing the whole suite on a
/// ProcessException before the test body can decide anything.
bool _run(String executable, List<String> arguments) {
  try {
    return Process.runSync(executable, arguments).exitCode == 0;
  } on ProcessException {
    return false;
  }
}
