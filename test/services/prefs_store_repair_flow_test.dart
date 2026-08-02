import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/prefs_recovery.dart';
import 'package:plezy/services/sensitive_prefs.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:shared_preferences_linux/shared_preferences_linux.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../test_helpers/io_fakes.dart';

/// The whole #1732 loop, driven against the **real** desktop preference
/// backend rather than an in-memory fake.
///
/// The two halves of the existing coverage never met: file-level tests called
/// `PrefsRecovery` statics with a `storeFileOverride` and never built a gate,
/// while gate-level tests threw synthetic exceptions and never touched a file.
/// Every defect in #1732 lived in the join — the preflight's callsite, the
/// classification of what the plugin threw, and the reopen after a repair.
///
/// `shared_preferences_linux` is pure Dart and byte-identical to the Windows
/// implementation; both expose `fs`/`pathProvider` for exactly this. Pointing
/// its path provider at a temp directory runs the genuine read, parse, cache
/// and write code on any host.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory support;
  late File store;

  /// A 32-byte key, the only length `AesGcm.with256bits()` accepts.
  final validVaultKey = base64Encode(List<int>.generate(32, (i) => i));

  setUp(() async {
    root = await Directory.systemTemp.createTemp('plezy_prefs_repair_flow_');
    support = Directory(p.join(root.path, 'support'))..createSync(recursive: true);
    store = File(p.join(support.path, prefsStoreFileName));

    PathProviderPlatform.instance = FakePathProvider(root);
    // The desktop store path is Windows/Linux only; without this the preflight
    // is a no-op on a macOS host and the test would assert nothing.
    PrefsRecovery.debugSetSupportedPlatformOverride(true);

    final pathProvider = _TempPathProviderLinux(support.path);
    SharedPreferencesStorePlatform.instance = SharedPreferencesLinux()..pathProvider = pathProvider;
    SharedPreferencesAsyncPlatform.instance = SharedPreferencesAsyncLinux()..pathProvider = pathProvider;

    BaseSharedPreferencesService.resetForTesting();
    SettingsService.resetForTesting();
    // `CredentialVault` memoises the first key it sees; the repair reseeds
    // before anything can read, which is what makes the reseed safe.
  });

  tearDown(() async {
    BaseSharedPreferencesService.resetForTesting();
    SettingsService.resetForTesting();
    PrefsRecovery.debugSetSupportedPlatformOverride(null);
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('a store the backend can read opens normally', () async {
    await store.writeAsString(jsonEncode({'theme': 'dark'}));

    await expectLater(SettingsService.getInstance(), completes);
  });

  test('an offset-0 store fails the gate as a repairable corruption', () async {
    // The exact shape reported in #1732: valid UTF-8, non-empty, and a first
    // byte that is not a legal JSON value start.
    await store.writeAsBytes([
      0,
      ...utf8.encode(jsonEncode({'theme': 'dark'})),
    ]);

    final error = await SettingsService.getInstance().then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<CorruptPreferenceStoreException>());
    final corruption = error! as CorruptPreferenceStoreException;
    expect(corruption.offset, 0);
    // Caught by the preflight, before either backend memoised anything, so the
    // repair can reopen in this same process.
    expect(corruption.reopenSafe, isTrue);
  });

  test('repairing an offset-0 store reopens it in the same process and keeps the vault key', () async {
    await store.writeAsBytes([
      0,
      ...utf8.encode(jsonEncode({credentialVaultKeyPref: validVaultKey, 'theme': 'dark'})),
    ]);

    await expectLater(SettingsService.getInstance(), throwsA(isA<CorruptPreferenceStoreException>()));

    final outcome = await BaseSharedPreferencesService.repairCorruptStore();

    expect(outcome.vaultKeySalvaged, isTrue);
    expect(outcome.requiresRestart, isFalse);
    expect(outcome.backupPath, isNotNull);
    expect(await File(outcome.backupPath!).exists(), isTrue);

    // The point of the whole exercise: this process, no restart.
    final settings = await SettingsService.getInstance();
    expect(settings, isNotNull);

    // The salvaged key is on disk under the async key name, so every token
    // stored as ciphertext in the database stays decryptable.
    final reopened = jsonDecode(await store.readAsString()) as Map<String, dynamic>;
    expect(reopened[credentialVaultKeyPref], validVaultKey);
    // Settings were reset, which is the cost the consent dialog names.
    expect(reopened.containsKey('theme'), isFalse);
  });

  test('a store whose bytes are not UTF-8 is repairable, not a dead end', () async {
    // `File.readAsString` reports a decode failure as FileSystemException, so
    // this used to slip past the preflight, fail the type check that decides
    // repairability, and reach the user as a failure screen with no Repair
    // button and no way forward.
    await store.writeAsBytes([
      0xFF,
      0xFE,
      ...utf8.encode(jsonEncode({credentialVaultKeyPref: validVaultKey})),
    ]);

    final error = await SettingsService.getInstance().then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<CorruptPreferenceStoreException>());
    expect((error! as CorruptPreferenceStoreException).shape?.validUtf8, isFalse);

    final outcome = await BaseSharedPreferencesService.repairCorruptStore();

    expect(outcome.vaultKeySalvaged, isTrue);
    await expectLater(SettingsService.getInstance(), completes);
  });

  test('an empty store is a first launch, not damage', () async {
    // Both backends skip `json.decode` for an empty document, so rejecting it
    // would brick a launch the plugin handles perfectly well.
    await store.writeAsBytes(const []);

    await expectLater(SettingsService.getInstance(), completes);
  });

  test('the all-zero store reported in #1732 is repairable and costs every sign-in', () async {
    // The store the reporter actually had: a full-length file whose every byte
    // is zero. It reaches the parser as "FormatException at offset 0", exactly
    // like a truncated document, but nothing can be salvaged from it — which
    // is the opposite of harmless, because the vault key goes with it.
    await store.writeAsBytes(List<int>.filled(10336, 0));

    final error = await SettingsService.getInstance().then<Object?>((_) => null, onError: (Object e) => e);
    final corruption = error! as CorruptPreferenceStoreException;
    expect(corruption.shape?.allZero, isTrue);
    expect(corruption.shape?.length, 10336);

    // The consent dialog reads this before destroying anything, and must not
    // promise that servers and profiles survive.
    final preview = await PrefsRecovery.previewSalvage(storeFileOverride: store);
    expect(preview.vaultKey, isNull);
    expect(preview.sessions, isEmpty);
    // Purely a preview: the damaged store is still exactly where it was.
    expect(await store.exists(), isTrue);
    expect(await store.length(), 10336);

    // Retrying re-reads the same bytes and reaches the same verdict, so the
    // failure screen's Retry button can never clear this on its own.
    await expectLater(SettingsService.getInstance(), throwsA(isA<CorruptPreferenceStoreException>()));

    final outcome = await BaseSharedPreferencesService.repairCorruptStore();

    expect(outcome.requiresRestart, isFalse);
    expect(outcome.vaultKeySalvaged, isFalse);
    // A file of zeros is not a secret, so the outcome dialog must not tell the
    // user the retained copy holds their credentials.
    expect(outcome.backupHoldsCredentials, isFalse);
    // The repair is what actually gets them into the app, in this process.
    await expectLater(SettingsService.getInstance(), completes);
  });

  test('a salvageable store previews as keeping its sign-ins', () async {
    await store.writeAsBytes([
      0,
      ...utf8.encode(jsonEncode({credentialVaultKeyPref: validVaultKey})),
    ]);

    final preview = await PrefsRecovery.previewSalvage(storeFileOverride: store);

    expect(preview.vaultKey, validVaultKey);

    final outcome = await BaseSharedPreferencesService.repairCorruptStore();
    expect(outcome.vaultKeySalvaged, isTrue);
    expect(outcome.backupHoldsCredentials, isTrue);
  });

  test('a store truncated mid-credential still warns that the copy holds secrets', () async {
    // The ordinary damage shape, and the one that makes "what did salvage
    // recover" useless as a proxy for "what is still in the file". The value
    // has no closing quote, so the salvage pattern matches nothing and reports
    // no losses — while almost the entire vault key sits in the quarantined
    // copy in plaintext.
    final truncated = '{"$credentialVaultKeyPref":"${validVaultKey.substring(0, validVaultKey.length - 4)}';
    await store.writeAsString(truncated);

    final preview = await PrefsRecovery.previewSalvage(storeFileOverride: store);
    expect(preview.vaultKey, isNull);
    expect(preview.sessions, isEmpty);
    expect(preview.losses, 0);

    final outcome = await BaseSharedPreferencesService.repairCorruptStore();

    expect(outcome.vaultKeySalvaged, isFalse);
    // The copy is unmistakably sensitive even though nothing was recoverable.
    expect(outcome.backupHoldsCredentials, isTrue);
    final quarantined = await File(outcome.backupPath!).readAsString();
    expect(quarantined, contains(validVaultKey.substring(0, 20)));
  });

  test('a genuine read failure keeps its own type and stays non-repairable', () async {
    // A store the process cannot read is not a damaged *document*. Offering a
    // destructive repair for a permissions problem would reset every setting
    // and risk the vault key over something a chmod fixes, so the failure has
    // to keep its own type and its own non-repairable path.
    await store.writeAsString(jsonEncode({'theme': 'dark'}));
    if (!_run('chmod', ['000', store.path])) {
      // No `chmod` on a Windows PATH, and its ACL model would need a different
      // probe entirely.
      markTestSkipped('cannot make a file unreadable here');
      return;
    }
    addTearDown(() => _run('chmod', ['600', store.path]));

    var readable = true;
    try {
      store.readAsBytesSync();
    } on FileSystemException {
      readable = false;
    }
    // Running as root (some container images) defeats the mode bits entirely.
    if (readable) {
      markTestSkipped('the store stayed readable after chmod 000; cannot stage an I/O failure here');
      return;
    }

    final error = await SettingsService.getInstance().then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isNotNull);
    expect(error, isNot(isA<CorruptPreferenceStoreException>()));
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
