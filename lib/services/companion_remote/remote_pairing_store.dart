import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../utils/serial_future_queue.dart';
import '../base_shared_preferences_service.dart';
import '../credential_vault.dart';

/// A local, profile-scoped pairing capability. Backend IDs only select peers;
/// possession of this 128-bit random capability authenticates remote control.
abstract final class RemotePairingStore {
  static final _queue = SerialFutureQueue();

  static String _key(String profileId, String peer) =>
      'companion_remote_pairing_${sha256.convert(utf8.encode(jsonEncode([profileId, peer])))}';

  static String? normalizeCode(String value) {
    final code = value.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
    return RegExp(r'^[0-9a-f]{32}$').hasMatch(code) ? code : null;
  }

  static String displayCode(String code) =>
      [for (var i = 0; i < code.length; i += 4) code.substring(i, i + 4)].join('-');

  static Future<String?> _read(String key) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    final value = readTolerantString(prefs, key);
    if (value == null) return null;
    final clear = await CredentialVault.reveal(value);
    return clear == null ? null : normalizeCode(clear);
  }

  static Future<void> _write(String key, String code) async {
    final prefs = await BaseSharedPreferencesService.sharedCache();
    await prefs.setString(key, await CredentialVault.protect(code));
  }

  static Future<String> hostCode(String profileId, {bool rotate = false}) => _queue.run(() async {
    final key = _key(profileId, 'host');
    if (!rotate) {
      final existing = await _read(key);
      if (existing != null) return existing;
    }
    final random = Random.secure();
    final code = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    await _write(key, code);
    return code;
  });

  static Future<String?> remoteCode(String profileId, String peer) =>
      _queue.run(() => _read(_key(profileId, 'remote:$peer')));

  /// Called only after the peer proves possession through encrypted authSuccess.
  static Future<void> rememberRemote(String profileId, String peer, String code) => _queue.run(() async {
    final normalized = normalizeCode(code);
    if (normalized == null) throw const FormatException('Invalid pairing code');
    await _write(_key(profileId, 'remote:$peer'), normalized);
  });
}

class RemotePairingRequired implements Exception {
  const RemotePairingRequired();
}
