import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../source_models.dart';

/// A multi-value register: only causally newer values replace older values.
/// Wall clocks and percentage played never decide which device wins.
class SyncVersion {
  SyncVersion(this.clock, this.value, {this.actor});
  final Map<String, int> clock;
  final Map<String, dynamic> value;
  final String? actor;
  Map<String, dynamic> toJson() => {'clock': clock, 'value': value, if (actor != null) 'actor': actor};
  factory SyncVersion.fromJson(Map<String, dynamic> json) {
    final raw = sourceMap(json['clock']);
    final rawActor = json['actor'];
    String? actor;
    if (rawActor != null) {
      if (rawActor is! String) {
        throw const SourceException(SourceFailure.invalidData);
      }
      if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(rawActor)) {
        throw const SourceException(SourceFailure.invalidData);
      }
      actor = rawActor;
    }
    if (raw.isEmpty || raw.length > 128 || json['value'] is! Map) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final clock = <String, int>{};
    for (final e in raw.entries) {
      if (!RegExp(r'^[a-f0-9]{32}$').hasMatch(e.key) || e.value is! int || e.value <= 0 || e.value > 9007199254740991) {
        throw const SourceException(SourceFailure.invalidData);
      }
      clock[e.key] = e.value as int;
    }
    return SyncVersion(clock, sourceMap(json['value']), actor: actor);
  }
}

String canonicalSyncJson(Object? value) {
  Object? sorted(Object? v) {
    if (v is Map) {
      final keys = v.keys.cast<String>().toList()..sort();
      return {for (final k in keys) k: sorted(v[k])};
    }
    if (v is List) return v.map(sorted).toList();
    return v;
  }

  return jsonEncode(sorted(value));
}

Map<String, int> joinedClock(Iterable<SyncVersion> values) {
  final result = <String, int>{};
  for (final v in values) {
    for (final e in v.clock.entries) {
      if (e.value > (result[e.key] ?? 0)) result[e.key] = e.value;
    }
  }
  return result;
}

bool _covers(Map<String, int> a, Map<String, int> b) => b.entries.every((e) => (a[e.key] ?? 0) >= e.value);

class SyncDocument {
  SyncDocument([Map<String, List<SyncVersion>>? records]) : records = records ?? {};
  final Map<String, List<SyncVersion>> records;
  static const maxRecords = 20000;
  static const maxBytes = 4 * 1024 * 1024;

  void merge(SyncDocument other) {
    for (final e in other.records.entries) {
      for (final incoming in e.value) {
        final current = records.putIfAbsent(e.key, () => []);
        var covered = false;
        for (final old in current) {
          if (_covers(old.clock, incoming.clock)) {
            if (_covers(incoming.clock, old.clock) &&
                canonicalSyncJson(old.value) != canonicalSyncJson(incoming.value)) {
              throw const SourceException(SourceFailure.invalidData);
            }
            covered = true;
          }
        }
        if (covered) continue;
        current.removeWhere((old) => _covers(incoming.clock, old.clock));
        current.add(incoming);
        current.sort((a, b) => canonicalSyncJson(a.clock).compareTo(canonicalSyncJson(b.clock)));
        if (current.length > 128 || records.length > maxRecords) {
          throw const SourceException(SourceFailure.invalidData);
        }
      }
    }
  }

  /// [basis] is the last value applied locally, NOT all downloaded values.
  /// A remote value deferred by an active reader must remain concurrent.
  SyncVersion edit(String key, String device, Map<String, dynamic> value, Map<String, int> basis) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(key) || !RegExp(r'^[a-f0-9]{32}$').hasMatch(device)) {
      throw const SourceException(SourceFailure.invalidData);
    }
    final existing = records[key] ?? [];
    final clock = Map<String, int>.from(basis);
    final seen = joinedClock(existing)[device] ?? 0;
    clock[device] = (seen > (clock[device] ?? 0) ? seen : (clock[device] ?? 0)) + 1;
    final next = SyncVersion(clock, value, actor: device);
    merge(
      SyncDocument({
        key: [next],
      }),
    );
    return next;
  }

  bool conflicted(String key) => (records[key] ?? []).map((v) => canonicalSyncJson(v.value)).toSet().length > 1;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'records': records.map((k, v) => MapEntry(k, v.map((x) => x.toJson()).toList())),
  };
  factory SyncDocument.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const SourceException(SourceFailure.unsupported);
    final raw = sourceMap(json['records']);
    if (raw.length > maxRecords) throw const SourceException(SourceFailure.invalidData);
    final result = SyncDocument();
    for (final e in raw.entries) {
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(e.key) ||
          e.value is! List ||
          (e.value as List).isEmpty ||
          (e.value as List).length > 128) {
        throw const SourceException(SourceFailure.invalidData);
      }
      result.merge(SyncDocument({e.key: (e.value as List).map((v) => SyncVersion.fromJson(sourceMap(v))).toList()}));
    }
    return result;
  }
}

/// The join code is a random 256-bit encryption key. It is never an OAuth token.
/// File names and authenticated metadata contain no book titles or profile IDs.
class SyncCipher {
  SyncCipher(String code) : keyBytes = decodeCode(code);
  final List<int> keyBytes;
  static final _algorithm = AesGcm.with256bits();
  static String newCode() => base64UrlEncode(
    _algorithm.newNonce() + _algorithm.newNonce() + _algorithm.newNonce().take(8).toList(),
  ).replaceAll('=', '');
  static List<int> decodeCode(String code) {
    try {
      final bytes = base64Url.decode(base64Url.normalize(code.trim()));
      if (bytes.length != 32) throw const FormatException();
      return bytes;
    } catch (_) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }

  String get namespace => sourceDigest(base64UrlEncode(keyBytes)).substring(0, 24);
  Future<String> seal(SyncDocument document, String name) async {
    final bytes = utf8.encode(canonicalSyncJson(document.toJson()));
    if (bytes.length > SyncDocument.maxBytes) throw const SourceException(SourceFailure.invalidData);
    final box = await _algorithm.encrypt(bytes, secretKey: SecretKey(keyBytes), aad: utf8.encode(name));
    return jsonEncode({
      'version': 1,
      'nonce': base64Encode(box.nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<SyncDocument> open(String text, String name) async {
    try {
      if (utf8.encode(text).length > 6 * 1024 * 1024) throw const FormatException();
      final json = sourceMap(jsonDecode(text));
      if (json['version'] != 1) throw const SourceException(SourceFailure.unsupported);
      final nonce = base64Decode(json['nonce'] as String), mac = base64Decode(json['mac'] as String);
      if (nonce.length != 12 || mac.length != 16) throw const FormatException();
      final clear = await _algorithm.decrypt(
        SecretBox(base64Decode(json['ciphertext'] as String), nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(keyBytes),
        aad: utf8.encode(name),
      );
      if (clear.length > SyncDocument.maxBytes) throw const FormatException();
      return SyncDocument.fromJson(sourceMap(jsonDecode(utf8.decode(clear))));
    } on SourceException {
      rethrow;
    } catch (_) {
      throw const SourceException(SourceFailure.invalidData);
    }
  }
}
