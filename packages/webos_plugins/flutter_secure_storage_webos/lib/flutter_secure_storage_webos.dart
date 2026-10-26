// Copyright (c) 2026 LG Electronics, Inc. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

import 'src/_secure_storage_channel.dart';
import 'src/_secure_storage_client.dart';

class FlutterSecureStorageWebos extends FlutterSecureStoragePlatform {
  FlutterSecureStorageWebos();

  static void registerWith() {
    FlutterSecureStoragePlatform.instance = FlutterSecureStorageWebos();
  }

  final SecureStorageClient _client = SecureStorageClient();
  late final SecureStorageChannel _store = SecureStorageChannel(_client);
  Future<void>? _initFuture;
  final Lock _writeLock = Lock();

  Future<void> _ensureInit() {
    _initFuture ??= _store.open().catchError((Object e, StackTrace st) {
      _initFuture = null;
      return Future<void>.error(e, st);
    });
    return _initFuture!;
  }

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    if (key.isEmpty || value.isEmpty) {
      throw PlatformException(
        code: 'Invalid argument',
        message: 'No key/val provided.',
      );
    }
    await _ensureInit();
    await _writeLock.synchronized(() async {
      if (_store.containsKey(key)) {
        await _client.removeKey(key);
      }
      await _client.generateKey(key);
      final encrypted = await _client.encrypt(key, value);
      if (encrypted.isEmpty) {
        await _client.removeKey(key);
        await _store.removeRaw(key);
      } else {
        await _store.setRaw(key, encrypted);
      }
    });
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    if (key.isEmpty) {
      throw PlatformException(
        code: 'Invalid argument',
        message: 'No key provided.',
      );
    }
    await _ensureInit();
    final raw = _store.rawValue(key);
    if (raw == null) return null;
    final decrypted = await _client.decrypt(key, raw);
    return decrypted.isEmpty ? null : decrypted;
  }

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    if (key.isEmpty) {
      throw PlatformException(
        code: 'Invalid argument',
        message: 'No key provided.',
      );
    }
    await _ensureInit();
    return _store.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    if (key.isEmpty) {
      throw PlatformException(
        code: 'Invalid argument',
        message: 'No key provided.',
      );
    }
    await _ensureInit();
    await _writeLock.synchronized(() async {
      if (!_store.containsKey(key)) return;
      await _client.removeKey(key);
      await _store.removeRaw(key);
    });
  }

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    await _ensureInit();
    final out = <String, String>{};
    for (final entry in _store.entries().entries) {
      final value = await _client.decrypt(entry.key, entry.value);
      if (value.isNotEmpty) out[entry.key] = value;
    }
    return out;
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    await _ensureInit();
    await _writeLock.synchronized(() async {
      for (final key in _store.entries().keys.toList(growable: false)) {
        await _client.removeKey(key);
      }
      await _store.clear();
    });
  }
}
