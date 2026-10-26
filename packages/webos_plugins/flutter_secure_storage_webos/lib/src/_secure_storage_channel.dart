import 'dart:convert';

import 'package:flutter/services.dart';

import '_secure_storage_client.dart';

const String dbRowKey = 'flutter_secure_storage';

class SecureStorageChannel {
  SecureStorageChannel(this._client);

  static const MethodChannel _channel = MethodChannel('webos/secure_storage');

  final SecureStorageClient _client;
  final Map<String, String> _kvs = <String, String>{};
  bool _opened = false;

  Future<void> open() async {
    if (_opened) return;
    final row = await _channel.invokeMapMethod<String, Object?>('load');
    final encryptedKeys = row?['keys'] as String?;
    if (encryptedKeys == null) {
      // First run on this device: seed the row with empty arrays.
      await _client.generateKey(dbRowKey);
      final seedKeys = await _client.encrypt(dbRowKey, '[]');
      await _channel.invokeMethod<void>('store', <String, String>{
        'keys': seedKeys,
        'datas': '[]',
      });
      _opened = true;
      return;
    }
    final datasJson = (row?['datas'] as String?) ?? '[]';
    final keysJson = await _client.decrypt(dbRowKey, encryptedKeys);
    _hydrate(keysJson, datasJson);

    // Drop entries whose envelope no longer decrypts (e.g. after a reflash).
    final filtered = <String, String>{};
    for (final entry in _kvs.entries) {
      if (await _client.isValid(entry.key, entry.value)) {
        filtered[entry.key] = entry.value;
      }
    }
    if (filtered.length != _kvs.length) {
      _kvs
        ..clear()
        ..addAll(filtered);
      await _flush();
    }
    _opened = true;
  }

  bool containsKey(String key) => _kvs.containsKey(key);

  String? rawValue(String key) => _kvs[key];

  Map<String, String> entries() => Map<String, String>.unmodifiable(_kvs);

  Future<void> setRaw(String key, String value) async {
    _kvs[key] = value;
    await _flush();
  }

  Future<void> removeRaw(String key) async {
    if (_kvs.remove(key) == null) return;
    await _flush();
  }

  Future<void> clear() async {
    if (_kvs.isEmpty) return;
    _kvs.clear();
    await _flush();
  }

  void _hydrate(String keysJson, String datasJson) {
    final keys = _decodeStringArray(keysJson);
    final datas = _decodeStringArray(datasJson);
    if (keys == null || datas == null) return;
    final n = keys.length < datas.length ? keys.length : datas.length;
    _kvs.clear();
    for (var i = 0; i < n; i++) {
      _kvs[keys[i]] = datas[i];
    }
  }

  Future<void> _flush() async {
    final keysJson = jsonEncode(_kvs.keys.toList(growable: false));
    final datasJson = jsonEncode(_kvs.values.toList(growable: false));

    await _client.removeKey(dbRowKey);
    await _client.generateKey(dbRowKey);
    final encryptedKeys = await _client.encrypt(dbRowKey, keysJson);

    await _channel.invokeMethod<void>('store', <String, String>{
      'keys': encryptedKeys,
      'datas': datasJson,
    });
  }
}

List<String>? _decodeStringArray(String json) {
  if (json.isEmpty) return null;
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) return null;
    return decoded.whereType<String>().toList(growable: false);
  } catch (_) {
    return null;
  }
}
