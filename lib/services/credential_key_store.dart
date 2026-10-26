import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The OS credential store. Never fall back to a plaintext preferences/file
/// store when a keychain is locked or unavailable, and never reset it on error.
abstract final class CredentialKeyStore {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false, storageNamespace: 'plezy_credentials'),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
    // No cross-app sharing: the login keychain also works for directly
    // distributed/ad-hoc macOS builds without a provisioning profile.
    mOptions: MacOsOptions(accountName: 'org.snapetech.plezyng.credential-vault', usesDataProtectionKeychain: false),
  );
  static const _tvChannel = MethodChannel('com.plezy/credential_keys');
  static const _isTvOS = bool.fromEnvironment('TVOS_BUILD');

  @visibleForTesting
  static bool useFederatedStoreForTesting = false;

  static bool get _usesNativeStore => !useFederatedStoreForTesting && (_isTvOS || Platform.isWindows);

  static Future<String?> read(String key) =>
      _usesNativeStore ? _tvChannel.invokeMethod<String>('read', {'key': key}) : _storage.read(key: key);

  static Future<void> write(String key, String value) => _usesNativeStore
      ? _tvChannel.invokeMethod<void>('write', {'key': key, 'value': value})
      : _storage.write(key: key, value: value);
}
