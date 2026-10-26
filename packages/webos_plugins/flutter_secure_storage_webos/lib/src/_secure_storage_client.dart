import 'dart:convert';

import 'package:flutter/services.dart';

const _channel = MethodChannel('webos_plugin');

class Lock {
  Future<void> _chain = Future.value();

  Future<T> synchronized<T>(Future<T> Function() fn) {
    final Future<T> result = _chain.then((_) => fn());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }
}

class SecureStorageClient {
  final Lock _lock = Lock();

  Future<String> encrypt(String key, String value) async {
    if (value.isEmpty) return '';
    return _lock.synchronized(() async {
      final beginR =
          await _channel.invokeMapMethod<String, dynamic>(
            'keymanager/begin',
            _header(key, ['encrypt']),
          ) ??
          {};
      if (beginR['returnValue'] != true) return '';
      final iv = beginR['iv'] as String? ?? '';
      final handle = beginR['handle'] as String? ?? '';
      if (handle.isEmpty) return '';
      final encoded = base64.encode(utf8.encode(value));
      final out = await _finish(handle, encoded);
      if (out.isEmpty) {
        await _abort(handle);
        return '';
      }
      return iv + out;
    });
  }

  Future<String> decrypt(String key, String output) async {
    if (output.length <= 24) return '';
    final iv = output.substring(0, 24);
    final value = output.substring(24);
    return _lock.synchronized(() async {
      final beginR =
          await _channel.invokeMapMethod<String, dynamic>(
            'keymanager/begin',
            _header(key, ['decrypt'], iv: iv),
          ) ??
          {};
      if (beginR['returnValue'] != true) return '';
      final handle = beginR['handle'] as String? ?? '';
      if (handle.isEmpty) return '';
      final encoded = await _finish(handle, value);
      if (encoded.isEmpty) {
        await _abort(handle);
        return '';
      }
      try {
        return utf8.decode(base64.decode(encoded));
      } catch (_) {
        return '';
      }
    });
  }

  Future<bool> isValid(String key, String output) async {
    if (output.length < 24) return false;
    final iv = output.substring(0, 24);
    return _lock.synchronized(() async {
      final beginR =
          await _channel.invokeMapMethod<String, dynamic>(
            'keymanager/begin',
            _header(key, ['decrypt'], iv: iv),
          ) ??
          {};
      if (beginR['returnValue'] != true) return false;
      final handle = beginR['handle'] as String? ?? '';
      if (handle.isNotEmpty) await _abort(handle);
      return true;
    });
  }

  Future<void> generateKey(String key) {
    return _lock.synchronized(() async {
      await _channel.invokeMethod<bool>(
        'keymanager/generateKey',
        _header(key, ['encrypt', 'decrypt']),
      );
    });
  }

  Future<void> removeKey(String key) {
    return _lock.synchronized(() async {
      await _channel.invokeMethod<bool>('keymanager/removeKey', {'name': key});
    });
  }

  Future<String> _finish(String handle, String data) async {
    final reply =
        await _channel.invokeMapMethod<String, dynamic>('keymanager/finish', {
          'handle': handle,
          'data': data,
        }) ??
        {};
    if (reply['returnValue'] != true) return '';
    return reply['output'] as String? ?? '';
  }

  Future<void> _abort(String handle) async {
    await _channel.invokeMethod<bool>('keymanager/abort', {'handle': handle});
  }

  Map<String, dynamic> _header(String key, List<String> purpose, {String? iv}) {
    final params = <String, dynamic>{
      'type': 'AES',
      'size': '256',
      'mode': ['CBC'],
      'purpose': purpose,
      'padding': ['PKCS7'],
    };
    if (iv != null && iv.isNotEmpty) params['iv'] = iv;
    return {'name': key, 'params': params};
  }
}
