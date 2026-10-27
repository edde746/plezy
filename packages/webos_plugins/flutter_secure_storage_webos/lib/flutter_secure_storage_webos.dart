// Copyright (c) 2026 LG Electronics, Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'src/_secure_storage_channel.dart';
import 'src/_secure_storage_client.dart';

class FlutterSecureStorageWebos extends FlutterSecureStoragePlatform {
  FlutterSecureStorageWebos();

  static void registerWith() => FlutterSecureStoragePlatform.instance = FlutterSecureStorageWebos();

  final SecureStorageClient _client = SecureStorageClient();
  late final SecureStorageChannel _store = SecureStorageChannel(_client);
  // All instances in one isolate share the lock. Native compare-and-store
  // protects competing isolates/processes and first-use initialization.
  static final Lock _operations = Lock();

  Future<T> _run<T>(Future<T> Function() operation) => _operations.synchronized(() async {
        for (var attempt = 0;; attempt++) {
          try {
            await _store.open();
            return await operation();
          } on PlatformException catch (error) {
            // A reader can have loaded an index just superseded by another isolate.
            // Reload it, and retry CAS conflicts, without interpreting either as
            // absence. Persistent failures still propagate to CredentialVault.
            if (attempt >= 2 || !const {'secure_storage_conflict', 'secure_storage_unavailable'}.contains(error.code)) {
              rethrow;
            }
          }
        }
      });

  void _validateKey(String key) {
    if (key.isEmpty) throw PlatformException(code: 'Invalid argument', message: 'No key provided.');
  }

  @override
  Future<void> write({required String key, required String value, required Map<String, String> options}) async {
    _validateKey(key);
    if (value.isEmpty) throw PlatformException(code: 'Invalid argument', message: 'No value provided.');
    await _run(() async {
      final old = _store.rawValue(key);
      final staged = await _client.createSecret(value);
      try {
        await _store.setRaw(key, staged);
      } on StorageWriteException catch (error) {
        if (!error.mayHaveCommitted) {
          await _client.removeKeyBestEffort(_client.secretKey(key, staged));
        }
        rethrow;
      }
      if (old != null) await _client.removeSecretBestEffort(key, old);
    });
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async {
    _validateKey(key);
    return _run(() async {
      final raw = _store.rawValue(key);
      return raw == null ? null : _client.readSecret(key, raw);
    });
  }

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async {
    _validateKey(key);
    return _run(() async => _store.containsKey(key));
  }

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _validateKey(key);
    await _run(() async {
      final old = _store.rawValue(key);
      if (old == null) return;
      await _store.removeRaw(key);
      await _client.removeSecretBestEffort(key, old);
    });
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) => _run(() async {
        final out = <String, String>{};
        for (final entry in _store.entries().entries) {
          out[entry.key] = await _client.readSecret(entry.key, entry.value);
        }
        return out;
      });

  @override
  Future<void> deleteAll({required Map<String, String> options}) => _run(() async {
        final old = _store.entries();
        if (old.isEmpty) return;
        await _store.clear();
        for (final entry in old.entries) {
          await _client.removeSecretBestEffort(entry.key, entry.value);
        }
      });
}
