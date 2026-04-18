import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

import '../../models/plex_home.dart';
import '../../utils/app_logger.dart';

/// Cryptographic authentication service for companion remote.
///
/// Proves same-home membership via a shared secret derived from Plex home data.
/// This authenticates **group membership**, not individual user identity —
/// any device in the same Plex home can connect.
class RemoteAuthService {
  RemoteAuthService._();
  static final instance = RemoteAuthService._();

  // Reusable crypto algorithm instances
  static final _hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
  static final _aesGcm = AesGcm.with256bits();

  // Cached home secret — derived in memory, never persisted
  List<int>? _cachedHomeSecret;
  int? _cachedHomeId;
  String? _cachedAdminUUID;

  /// Build canonical IKM bytes from home data.
  /// Format: [4-byte BE len][utf8 bytes] for each field, in fixed order.
  static Uint8List _canonicalIkm(int homeId, String adminUUID) {
    final homeIdBytes = utf8.encode(homeId.toString());
    final uuidBytes = utf8.encode(adminUUID.toLowerCase());

    final buf = BytesWriter();
    buf.writeUint32BE(homeIdBytes.length);
    buf.writeBytes(homeIdBytes);
    buf.writeUint32BE(uuidBytes.length);
    buf.writeBytes(uuidBytes);
    return buf.toBytes();
  }

  /// Derive the long-term home secret via HKDF-SHA256.
  /// This is derived in memory from cached Plex data — never persisted.
  Future<List<int>> deriveHomeSecret(int homeId, String adminUUID) async {
    // Return cached if inputs unchanged
    if (_cachedHomeSecret != null && _cachedHomeId == homeId && _cachedAdminUUID == adminUUID) {
      return _cachedHomeSecret!;
    }

    final hkdf = _hkdf;
    final ikm = _canonicalIkm(homeId, adminUUID);

    final secretKey = await hkdf.deriveKey(
      secretKey: SecretKey(ikm),
      nonce: utf8.encode('plezy-remote-v1'),
      info: utf8.encode('home-secret'),
    );

    _cachedHomeSecret = await secretKey.extractBytes();
    _cachedHomeId = homeId;
    _cachedAdminUUID = adminUUID;

    appLogger.d('RemoteAuth: Derived home secret');
    return _cachedHomeSecret!;
  }

  /// Derive the long-term home secret from a PlexHome object.
  Future<List<int>> deriveHomeSecretFromHome(PlexHome home) async {
    final admin = home.adminUser;
    if (admin == null) {
      throw StateError('PlexHome has no admin user');
    }
    return deriveHomeSecret(home.id, admin.uuid);
  }

  /// Derive per-session encryption key from homeSecret + both nonces.
  Future<List<int>> deriveSessionEncKey(List<int> homeSecret, List<int> hostNonce, List<int> clientNonce) async {
    final hkdf = _hkdf;

    final salt = Uint8List(hostNonce.length + clientNonce.length);
    salt.setAll(0, hostNonce);
    salt.setAll(hostNonce.length, clientNonce);

    // First derive session secret
    final sessionSecretKey = await hkdf.deriveKey(
      secretKey: SecretKey(homeSecret),
      nonce: salt,
      info: utf8.encode('plezy-session-v1'),
    );
    final sessionSecret = await sessionSecretKey.extractBytes();

    // Then derive encryption key from session secret
    final encKeyResult = await hkdf.deriveKey(
      secretKey: SecretKey(sessionSecret),
      nonce: const <int>[],
      info: utf8.encode('encryption'),
    );

    return encKeyResult.extractBytes();
  }

  /// Derive discovery key from homeSecret.
  Future<List<int>> deriveDiscoveryKey(List<int> homeSecret) async {
    final hkdf = _hkdf;
    final key = await hkdf.deriveKey(
      secretKey: SecretKey(homeSecret),
      nonce: const <int>[],
      info: utf8.encode('discovery'),
    );
    return key.extractBytes();
  }

  /// Compute rotating discovery tag for beacon filtering.
  /// Uses 5-minute epoch windows to reduce cross-network tracking.
  String computeDiscoveryTag(List<int> discoveryKey, {DateTime? now}) {
    final epochSeconds = ((now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000);
    final window = epochSeconds ~/ 300; // 5-minute windows
    final msg = utf8.encode('identify|$window');
    final hmac = crypto.Hmac(crypto.sha256, discoveryKey);
    return hmac.convert(msg).toString();
  }

  /// Check if a received homeHash matches any of the ±1 epoch windows.
  bool matchesDiscoveryTag(String receivedHash, List<int> discoveryKey, {DateTime? now}) {
    final epochSeconds = ((now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000);
    final currentWindow = epochSeconds ~/ 300;

    for (final window in [currentWindow - 1, currentWindow, currentWindow + 1]) {
      final msg = utf8.encode('identify|$window');
      final hmac = crypto.Hmac(crypto.sha256, discoveryKey);
      final tag = hmac.convert(msg).toString();
      if (_constantTimeEquals(tag, receivedHash)) return true;
    }
    return false;
  }

  /// Generate 32 cryptographically random bytes.
  List<int> generateNonce() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }

  /// Compute auth tag (HMAC-SHA256) over the full handshake transcript.
  /// Domain-separated with "plezy-auth-v1|" prefix.
  String computeAuthTag({
    required List<int> homeSecret,
    required List<int> hostNonce,
    required List<int> clientNonce,
    required String hostClientId,
    required String userUUID,
    required String clientIdentifier,
    required String deviceName,
    required String platform,
  }) {
    final msg = _buildAuthTranscript(
      hostNonce: hostNonce,
      clientNonce: clientNonce,
      hostClientId: hostClientId,
      userUUID: userUUID,
      clientIdentifier: clientIdentifier,
      deviceName: deviceName,
      platform: platform,
    );
    final hmac = crypto.Hmac(crypto.sha256, homeSecret);
    return hmac.convert(msg).toString();
  }

  /// Verify auth tag with constant-time comparison.
  bool verifyAuthTag({
    required String authTag,
    required List<int> homeSecret,
    required List<int> hostNonce,
    required List<int> clientNonce,
    required String hostClientId,
    required String userUUID,
    required String clientIdentifier,
    required String deviceName,
    required String platform,
  }) {
    final expected = computeAuthTag(
      homeSecret: homeSecret,
      hostNonce: hostNonce,
      clientNonce: clientNonce,
      hostClientId: hostClientId,
      userUUID: userUUID,
      clientIdentifier: clientIdentifier,
      deviceName: deviceName,
      platform: platform,
    );
    return _constantTimeEquals(expected, authTag);
  }

  /// Build the auth transcript message bytes.
  List<int> _buildAuthTranscript({
    required List<int> hostNonce,
    required List<int> clientNonce,
    required String hostClientId,
    required String userUUID,
    required String clientIdentifier,
    required String deviceName,
    required String platform,
  }) {
    final buf = BytesWriter();
    buf.writeBytes(utf8.encode('plezy-auth-v1|'));
    // Fixed-length nonces (32 bytes each) — no prefix needed
    buf.writeBytes(hostNonce);
    buf.writeBytes(clientNonce);
    // Variable-length strings — length-prefixed to prevent field boundary shifting
    _writeLengthPrefixed(buf, utf8.encode(hostClientId));
    _writeLengthPrefixed(buf, utf8.encode(userUUID));
    _writeLengthPrefixed(buf, utf8.encode(clientIdentifier));
    _writeLengthPrefixed(buf, utf8.encode(deviceName));
    _writeLengthPrefixed(buf, utf8.encode(platform));
    return buf.toBytes();
  }

  /// Compute HMAC for discovery beacon over canonical binary layout.
  /// Fields in fixed order: v, homeHash, name, platform, clientId, port, ips (sorted, comma-joined).
  String computeBeaconHmac({
    required List<int> discoveryKey,
    required int version,
    required String homeHash,
    required String name,
    required String platform,
    required String clientId,
    required int port,
    required List<String> ips,
  }) {
    final buf = BytesWriter();
    _writeLengthPrefixed(buf, utf8.encode(version.toString()));
    _writeLengthPrefixed(buf, utf8.encode(homeHash));
    _writeLengthPrefixed(buf, utf8.encode(name));
    _writeLengthPrefixed(buf, utf8.encode(platform));
    _writeLengthPrefixed(buf, utf8.encode(clientId));
    _writeLengthPrefixed(buf, utf8.encode(port.toString()));
    final sortedIps = List<String>.from(ips)..sort();
    _writeLengthPrefixed(buf, utf8.encode(sortedIps.join(',')));

    final hmac = crypto.Hmac(crypto.sha256, discoveryKey);
    return hmac.convert(buf.toBytes()).toString();
  }

  /// Verify a beacon's HMAC.
  bool verifyBeaconHmac({
    required String receivedHmac,
    required List<int> discoveryKey,
    required int version,
    required String homeHash,
    required String name,
    required String platform,
    required String clientId,
    required int port,
    required List<String> ips,
  }) {
    final expected = computeBeaconHmac(
      discoveryKey: discoveryKey,
      version: version,
      homeHash: homeHash,
      name: name,
      platform: platform,
      clientId: clientId,
      port: port,
      ips: ips,
    );
    return _constantTimeEquals(expected, receivedHmac);
  }

  // ── AES-256-GCM Encryption ──

  static const int _directionHost = 0x01;
  static const int _directionClient = 0x02;

  /// Build the 12-byte GCM nonce from direction + counter.
  static Uint8List buildNonce(int direction, int counter) {
    final nonce = Uint8List(12);
    // 4-byte direction (big-endian)
    nonce[0] = (direction >> 24) & 0xFF;
    nonce[1] = (direction >> 16) & 0xFF;
    nonce[2] = (direction >> 8) & 0xFF;
    nonce[3] = direction & 0xFF;
    // 8-byte counter (big-endian)
    nonce[4] = (counter >> 56) & 0xFF;
    nonce[5] = (counter >> 48) & 0xFF;
    nonce[6] = (counter >> 40) & 0xFF;
    nonce[7] = (counter >> 32) & 0xFF;
    nonce[8] = (counter >> 24) & 0xFF;
    nonce[9] = (counter >> 16) & 0xFF;
    nonce[10] = (counter >> 8) & 0xFF;
    nonce[11] = counter & 0xFF;
    return nonce;
  }

  /// Encrypt plaintext with AES-256-GCM.
  /// Returns ciphertext + auth tag (nonce is implicit from counters).
  Future<List<int>> encrypt(
    List<int> sessionEncKey,
    List<int> plaintext, {
    required bool isHost,
    required int counter,
  }) async {
    final algo = _aesGcm;
    final nonce = buildNonce(isHost ? _directionHost : _directionClient, counter);

    final secretBox = await algo.encrypt(plaintext, secretKey: SecretKey(sessionEncKey), nonce: nonce);

    // Return ciphertext + mac (nonce is implicit)
    return [...secretBox.cipherText, ...secretBox.mac.bytes];
  }

  /// Decrypt ciphertext + auth tag with AES-256-GCM.
  /// Receiver reconstructs the nonce from its own expected counter.
  Future<List<int>> decrypt(
    List<int> data,
    List<int> sessionEncKey, {
    required bool fromHost,
    required int expectedCounter,
  }) async {
    final algo = _aesGcm;
    final nonce = buildNonce(fromHost ? _directionHost : _directionClient, expectedCounter);

    if (data.length < 16) {
      throw ArgumentError('Encrypted data too short');
    }

    final cipherText = data.sublist(0, data.length - 16);
    final mac = Mac(data.sublist(data.length - 16));

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    return algo.decrypt(secretBox, secretKey: SecretKey(sessionEncKey));
  }

  // ── Utility ──

  static void _writeLengthPrefixed(BytesWriter buf, List<int> bytes) {
    buf.writeUint32BE(bytes.length);
    buf.writeBytes(bytes);
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// Clear cached home secret (e.g. on logout).
  void clearCache() {
    _cachedHomeSecret = null;
    _cachedHomeId = null;
    _cachedAdminUUID = null;
  }

  // Static direction constants for external use
  static int get directionHost => _directionHost;
  static int get directionClient => _directionClient;
}

/// Helper for building byte arrays.
class BytesWriter {
  final _bytes = <int>[];

  void writeBytes(List<int> data) => _bytes.addAll(data);

  void writeUint32BE(int value) {
    _bytes.add((value >> 24) & 0xFF);
    _bytes.add((value >> 16) & 0xFF);
    _bytes.add((value >> 8) & 0xFF);
    _bytes.add(value & 0xFF);
  }

  Uint8List toBytes() => Uint8List.fromList(_bytes);
}
