import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'visualizer_catalog_entry.dart';

/// The trust root is supplied by the release build, never by the downloaded
/// envelope. Rotation uses overlapping independently pinned keys and a quorum.
class VisualizerCatalogTrust {
  const VisualizerCatalogTrust({required this.keys, this.threshold = 1});
  final Map<String, List<int>> keys;
  final int threshold;

  static VisualizerCatalogTrust release() {
    const encoded = String.fromEnvironment('MILKRUST_CATALOG_KEYS');
    const threshold = int.fromEnvironment('MILKRUST_CATALOG_THRESHOLD', defaultValue: 1);
    if (encoded.isEmpty) return const VisualizerCatalogTrust(keys: {});
    final data = jsonDecode(encoded);
    if (data is! Map<String, dynamic> || data.isEmpty || data.length > 16) {
      throw const FormatException('Invalid release catalog trust root');
    }
    final keys = <String, List<int>>{};
    for (final item in data.entries) {
      if (!RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(item.key) || item.value is! String) {
        throw const FormatException('Invalid catalog signing key');
      }
      final key = base64Decode(item.value as String);
      if (key.length != 32) throw const FormatException('Catalog signing keys must be Ed25519 keys');
      keys[item.key] = key;
    }
    if (threshold < 1 || threshold > keys.length) throw const FormatException('Invalid catalog signature quorum');
    return VisualizerCatalogTrust(keys: Map.unmodifiable(keys), threshold: threshold);
  }
}

class VisualizerCatalogSnapshot {
  const VisualizerCatalogSnapshot({required this.sequence, required this.digest, required this.expires,
    required this.entries, required this.revoked, required this.envelope});
  final int sequence;
  final String digest;
  final DateTime expires;
  final List<VisualizerPackCatalogEntry> entries;
  final Set<String> revoked;
  final List<int> envelope;
  bool freshAt(DateTime now) => expires.isAfter(now.toUtc());
  bool isRevoked(VisualizerPackCatalogEntry entry) => revoked.contains(entry.identity) || revoked.contains('${entry.id}@*');
}

/// Signatures cover the exact decoded payload bytes plus a protocol prefix.
/// No JSON reserialization, network key discovery, or unsigned fallback occurs.
class VisualizerCatalogVerifier {
  VisualizerCatalogVerifier(this.trust);
  final VisualizerCatalogTrust trust;
  static const maxEnvelopeBytes = 2 * 1024 * 1024;
  static const maxPayloadBytes = 1024 * 1024;
  static const domain = 'MilkRust.catalog.v1\n';

  Future<VisualizerCatalogSnapshot> verify(List<int> bytes, DateTime now, {bool allowExpired = false}) async {
    if (trust.keys.isEmpty || trust.keys.length > 16 || trust.threshold < 1 ||
        trust.threshold > trust.keys.length || trust.keys.values.any((key) => key.length != 32)) {
      throw const FormatException('This build has no catalog signing trust root');
    }
    if (bytes.isEmpty || bytes.length > maxEnvelopeBytes) throw const FormatException('Catalog envelope exceeds its limit');
    final wrapper = jsonDecode(utf8.decode(bytes));
    if (wrapper is! Map<String, dynamic> || wrapper['schemaVersion'] != 1 || wrapper['payload'] is! String ||
        wrapper['signatures'] is! List || (wrapper['signatures'] as List).length > 16) {
      throw const FormatException('Invalid signed catalog envelope');
    }
    final payload = base64Decode(wrapper['payload'] as String);
    if (payload.isEmpty || payload.length > maxPayloadBytes) throw const FormatException('Catalog payload exceeds its limit');
    final message = [...utf8.encode(domain), ...payload];
    final accepted = <String>{};
    for (final signature in wrapper['signatures'] as List) {
      if (signature is! Map || signature['keyId'] is! String || signature['signature'] is! String) {
        throw const FormatException('Malformed catalog signature');
      }
      final keyId = signature['keyId'] as String, key = trust.keys[keyId];
      if (key == null || accepted.contains(keyId)) continue;
      final raw = base64Decode(signature['signature'] as String);
      if (raw.length != 64) continue;
      if (await Ed25519().verify(message, signature: Signature(raw,
          publicKey: SimplePublicKey(key, type: KeyPairType.ed25519)))) accepted.add(keyId);
    }
    if (accepted.length < trust.threshold) throw const FormatException('Catalog signature quorum was not met');
    final data = jsonDecode(utf8.decode(payload));
    if (data is! Map<String, dynamic> || data['schemaVersion'] != 1 || data['sequence'] is! int ||
        data['sequence'] <= 0 || data['sequence'] > 9007199254740991 || data['entries'] is! List ||
        (data['entries'] as List).length > 1000 || data['revoked'] is! List || (data['revoked'] as List).length > 2000) {
      throw const FormatException('Unsupported catalog schema or size');
    }
    DateTime date(String key) {
      final value = data[key];
      if (value is! String || !value.endsWith('Z')) throw FormatException('Catalog $key must be UTC');
      return DateTime.parse(value).toUtc();
    }
    final issued = date('issuedAt'), expires = date('expiresAt');
    if (issued.isAfter(now.toUtc().add(const Duration(minutes: 5))) || !expires.isAfter(issued) ||
        expires.difference(issued) > const Duration(days: 31) || (!allowExpired && !expires.isAfter(now.toUtc()))) {
      throw const FormatException('Catalog is expired or has an invalid validity window');
    }
    final entries = <VisualizerPackCatalogEntry>[], identities = <String>{}, ids = <String>{};
    for (final item in data['entries'] as List) {
      if (item is! Map<String, dynamic> || item['distributionStatus'] != 'redistributable') {
        throw const FormatException('Catalog contains an uncleared pack');
      }
      final entry = VisualizerPackCatalogEntry.fromJson(item);
      if (entry.license == 'NOASSERTION' || !identities.add(entry.identity) || !ids.add(entry.id)) {
        throw const FormatException('Duplicate or uncleared catalog entry');
      }
      entries.add(entry);
    }
    final revoked = <String>{};
    for (final item in data['revoked'] as List) {
      if (item is! String || !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,79}@(?:[A-Za-z0-9][A-Za-z0-9._-]{0,79}|\*)$').hasMatch(item)) {
        throw const FormatException('Invalid catalog revocation');
      }
      revoked.add(item);
    }
    return VisualizerCatalogSnapshot(sequence: data['sequence'] as int,
      digest: hashes.sha256.convert(payload).toString(), expires: expires,
      entries: List.unmodifiable(entries), revoked: Set.unmodifiable(revoked), envelope: List.unmodifiable(bytes));
  }
}

/// A shared device catalog. Opening playback reads only verified local metadata;
/// a remote refresh happens only through the library's explicit update action.
class VisualizerSignedCatalog {
  VisualizerSignedCatalog({VisualizerCatalogTrust? trust, http.Client? client,
    Future<Directory> Function()? directory, DateTime Function()? clock, Uri? endpoint})
      : verifier = VisualizerCatalogVerifier(trust ?? VisualizerCatalogTrust.release()),
        _client = client ?? http.Client(), _directory = directory ?? _defaultDirectory,
        _clock = clock ?? DateTime.now, endpoint = endpoint ?? Uri.parse(
          'https://raw.githubusercontent.com/snapetech-org/MilkRust/catalog/visualizer-catalog.json');

  static final shared = VisualizerSignedCatalog();
  final VisualizerCatalogVerifier verifier;
  final http.Client _client;
  final Future<Directory> Function() _directory;
  final DateTime Function() _clock;
  final Uri endpoint;
  Future<void> _tail = Future<void>.value();
  Future<void>? _loaded;
  VisualizerCatalogSnapshot? _snapshot;
  VisualizerCatalogSnapshot? get snapshot => _snapshot;
  String? _cacheError;
  final Map<String, VisualizerCatalogSnapshot> _checkpoints = {};
  final Map<String, VisualizerPackCatalogEntry> _history = {};
  bool get configured => verifier.trust.keys.isNotEmpty;
  bool get fresh => snapshot?.freshAt(_clock()) ?? false;
  String get status => !configured ? 'Remote pack updates are not configured in this build.'
      : _cacheError != null ? 'Saved catalog could not be verified. Installed presets remain available.'
      : snapshot == null ? 'Check for signed pack updates.'
      : fresh ? 'Signed catalog ${snapshot!.sequence}' : 'Saved catalog expired. Installed presets remain available.';

  List<VisualizerPackCatalogEntry> get entries {
    final result = {for (final e in VisualizerPackCatalogEntry.available) e.id: e};
    for (final e in snapshot?.entries ?? const <VisualizerPackCatalogEntry>[]) { result[e.id] = e; }
    return result.values.where((e) => !(snapshot?.isRevoked(e) ?? false)).toList();
  }

  List<VisualizerPackCatalogEntry> get knownEntries => [
    ...VisualizerPackCatalogEntry.available, ..._history.values, ...entries,
  ];

  bool authorizes(VisualizerPackCatalogEntry entry) {
    if (snapshot?.isRevoked(entry) ?? false) return false;
    if (VisualizerPackCatalogEntry.available.any((e) => e.sameArtifact(entry))) return true;
    return _cacheError == null && fresh && snapshot!.entries.any((e) => e.sameArtifact(entry));
  }

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    final folder = Directory(p.join(support.path, 'visualizer', 'catalog'));
    await folder.create(recursive: true);
    return folder;
  }

  Future<void> loadCached() => _loaded ??= _readCache().catchError((Object error) {
    // Catalog failures must never hide installed files or prevent offline use.
    // Refresh stays blocked if the rollback checkpoint cannot be established.
    _cacheError = error.toString();
  });

  Future<void> _readCache() async {
    if (!configured) return;
    final directory = await _directory();
    if (!await directory.exists()) return;
    var examined = 0;
    final sequences = <int, String>{};
    await for (final file in directory.list(followLinks: false)) {
      if (file is! File || !RegExp(r'^catalog-[0-9]+-[a-f0-9]{64}\.json$').hasMatch(p.basename(file.path))) continue;
      if (++examined > 64) throw const FormatException('Too many catalog checkpoints');
      if (await file.length() > VisualizerCatalogVerifier.maxEnvelopeBytes) continue;
      VisualizerCatalogSnapshot next;
      try {
        next = await verifier.verify(await file.readAsBytes(), _clock(), allowExpired: true);
      } on FormatException { continue; } // Invalid files never authorize downloads.
      if (p.basename(file.path) != 'catalog-${next.sequence}-${next.digest}.json') continue;
      final prior = sequences.putIfAbsent(next.sequence, () => next.digest);
      if (prior != next.digest) throw const FormatException('Conflicting signed catalog revisions');
      _checkpoints[file.path] = next;
      for (final entry in next.entries) { _history[entry.identity] = entry; }
      if (snapshot == null || next.sequence > snapshot!.sequence) _snapshot = next;
    }
  }

  Future<void> refresh() {
    final operation = _tail.then((_) => _refresh());
    _tail = operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<void> _refresh() async {
    await loadCached();
    if (!configured) throw const FormatException('This build has no catalog signing trust root');
    if (_cacheError != null) throw FormatException('Catalog checkpoint unavailable: $_cacheError');
    if (endpoint.scheme != 'https' || endpoint.host != 'raw.githubusercontent.com' || endpoint.userInfo.isNotEmpty) {
      throw const FormatException('Invalid catalog origin');
    }
    final abort = Completer<void>();
    final deadline = Timer(const Duration(seconds: 60), () { if (!abort.isCompleted) abort.complete(); });
    try {
      final request = http.AbortableRequest('GET', endpoint, abortTrigger: abort.future)..followRedirects = false;
      final response = await _client.send(request).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw HttpException('Catalog request failed: ${response.statusCode}');
      if ((response.contentLength ?? 0) > VisualizerCatalogVerifier.maxEnvelopeBytes) throw const FormatException('Catalog response is too large');
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(const Duration(seconds: 20))) {
        if (bytes.length + chunk.length > VisualizerCatalogVerifier.maxEnvelopeBytes) throw const FormatException('Catalog response is too large');
        bytes.addAll(chunk);
      }
      final next = await verifier.verify(bytes, _clock());
      final previous = snapshot;
      if (previous != null && (next.sequence < previous.sequence ||
          (next.sequence == previous.sequence && next.digest != previous.digest))) {
        throw const FormatException('Catalog rollback or revision replacement was rejected');
      }
      final directory = await _directory();
      await directory.create(recursive: true);
      final target = File(p.join(directory.path, 'catalog-${next.sequence}-${next.digest}.json'));
      if (!_checkpoints.containsKey(target.path)) {
        final temporary = File('${target.path}.partial');
        if (await FileSystemEntity.type(temporary.path, followLinks: false) == FileSystemEntityType.link ||
            await FileSystemEntity.type(target.path, followLinks: false) == FileSystemEntityType.link) {
          throw const FormatException('Linked catalog checkpoint is not allowed');
        }
        try {
          await temporary.writeAsBytes(bytes, flush: true);
          // The name is content addressed. Replace an invalid file left at this
          // name, retaining every previously verified rollback checkpoint.
          if (await target.exists()) await target.delete();
          await temporary.rename(target.path);
        } finally { if (await temporary.exists()) await temporary.delete(); }
      }
      _checkpoints[target.path] = next;
      _snapshot = next; // Only after the authenticated checkpoint is durable.
      for (final entry in next.entries) { _history[entry.identity] = entry; }
      final old = _checkpoints.entries.toList()
        ..sort((a, b) => b.value.sequence.compareTo(a.value.sequence));
      // Only verified files participate in retention. Forged filenames cannot
      // evict the highest authenticated sequence or crowd the retention set.
      for (final checkpoint in old.skip(8)) {
        if (checkpoint.key == target.path) continue;
        try {
          await File(checkpoint.key).delete();
          _checkpoints.remove(checkpoint.key);
        } on FileSystemException { /* Retry on a later refresh. */ }
      }
    } finally { deadline.cancel(); if (!abort.isCompleted) abort.complete(); }
  }
}
