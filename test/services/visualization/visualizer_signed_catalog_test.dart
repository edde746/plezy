import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/visualization/visualizer_catalog_entry.dart';
import 'package:plezy/services/visualization/visualizer_signed_catalog.dart';

void main() {
  final now = DateTime.utc(2026, 10, 28);
  late SimpleKeyPair key;
  late VisualizerCatalogTrust trust;
  late Directory directory;
  final entry = VisualizerPackCatalogEntry.available.single.toJson();

  Future<List<int>> envelope(int sequence, {DateTime? expires, List<String> revoked = const [],
      List<Map<String, Object>>? entries, String keyId = 'test'}) async {
    final payload = utf8.encode(jsonEncode({'schemaVersion': 1, 'sequence': sequence,
      'issuedAt': now.subtract(const Duration(hours: 1)).toIso8601String(),
      'expiresAt': (expires ?? now.add(const Duration(days: 7))).toIso8601String(),
      'entries': entries ?? [entry], 'revoked': revoked}));
    final signature = await Ed25519().sign([...utf8.encode(VisualizerCatalogVerifier.domain), ...payload], keyPair: key);
    return utf8.encode(jsonEncode({'schemaVersion': 1, 'payload': base64Encode(payload),
      'signatures': [{'keyId': keyId, 'signature': base64Encode(signature.bytes)}]}));
  }

  setUp(() async {
    // Deterministic test-only key. Never a production trust root.
    key = await Ed25519().newKeyPairFromSeed(List<int>.generate(32, (i) => i));
    trust = VisualizerCatalogTrust(keys: {'test': (await key.extractPublicKey()).bytes});
    directory = await Directory.systemTemp.createTemp('visualizer-catalog-test-');
  });
  tearDown(() async => directory.delete(recursive: true));

  test('verifies exact signed payload and rejects tampering, unknown keys and missing quorum', () async {
    final verifier = VisualizerCatalogVerifier(trust);
    final bytes = await envelope(4);
    expect((await verifier.verify(bytes, now)).sequence, 4);
    final changed = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    changed['payload'] = base64Encode(utf8.encode('{}'));
    await expectLater(verifier.verify(utf8.encode(jsonEncode(changed)), now), throwsFormatException);
    await expectLater(verifier.verify(await envelope(4, keyId: 'untrusted'), now), throwsFormatException);
    final quorum = VisualizerCatalogVerifier(VisualizerCatalogTrust(
      keys: {...trust.keys, 'second': List.filled(32, 1)}, threshold: 2));
    // Repeating the same valid signature must not satisfy a quorum of two.
    final repeated = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    repeated['signatures'] = [...repeated['signatures'], ...repeated['signatures']];
    await expectLater(quorum.verify(utf8.encode(jsonEncode(repeated)), now), throwsFormatException);
  });

  test('expiry denies download, but cache verification retains the sequence watermark', () async {
    final bytes = await envelope(7, expires: now.subtract(const Duration(minutes: 1)));
    final verifier = VisualizerCatalogVerifier(trust);
    await expectLater(verifier.verify(bytes, now), throwsFormatException);
    expect((await verifier.verify(bytes, now, allowExpired: true)).sequence, 7);
  });

  test('rejects mutable archives and uncleared pack declarations', () async {
    final verifier = VisualizerCatalogVerifier(trust);
    await expectLater(verifier.verify(await envelope(1, entries: [
      {...entry, 'archiveUrl': 'https://raw.githubusercontent.com/snapetech-org/MilkRust/main/content/downloads/a.rmpack'}
    ]), now), throwsFormatException);
    await expectLater(verifier.verify(await envelope(1, entries: [
      {...entry, 'license': 'NOASSERTION'}
    ]), now), throwsFormatException);
  });

  test('refresh persists rollback protection and revocations across restart', () async {
    var response = await envelope(12, revoked: ['milkrust-sample-pack@*']);
    final client = MockClient((_) async => http.Response.bytes(response, 200));
    addTearDown(client.close);
    VisualizerSignedCatalog open() => VisualizerSignedCatalog(trust: trust, client: client,
      directory: () async => directory, clock: () => now);
    final catalog = open();
    await catalog.refresh();
    expect(catalog.authorizes(VisualizerPackCatalogEntry.available.single), isFalse);
    final restarted = open();
    await restarted.loadCached();
    expect(restarted.snapshot?.sequence, 12);
    expect(restarted.authorizes(VisualizerPackCatalogEntry.available.single), isFalse);
    response = await envelope(11);
    await expectLater(restarted.refresh(), throwsFormatException);
    response = await envelope(12); // Same number, different signed contents.
    await expectLater(restarted.refresh(), throwsFormatException);
    expect(restarted.snapshot?.sequence, 12);
  });

  test('network failure retains cached metadata and fresh authorization', () async {
    final remoteEntry = {...entry, 'id': 'remote-sample'};
    var offline = false;
    final bytes = await envelope(2, entries: [remoteEntry]);
    final client = MockClient((_) async {
      if (offline) throw const SocketException('offline');
      return http.Response.bytes(bytes, 200);
    });
    addTearDown(client.close);
    final catalog = VisualizerSignedCatalog(trust: trust, client: client,
      directory: () async => directory, clock: () => now);
    await catalog.refresh();
    offline = true;
    await expectLater(catalog.refresh(), throwsA(isA<SocketException>()));
    expect(catalog.authorizes(VisualizerPackCatalogEntry.fromJson(remoteEntry)), isTrue);
    expect(catalog.authorizes(VisualizerPackCatalogEntry.fromJson({...remoteEntry, 'archiveBytes': 12})), isFalse);
  });

  test('conflicting authenticated cache checkpoints fail closed for remote packs', () async {
    final verifier = VisualizerCatalogVerifier(trust);
    for (final bytes in [await envelope(8), await envelope(8, revoked: ['removed@*'])]) {
      final snapshot = await verifier.verify(bytes, now);
      await File('${directory.path}/catalog-${snapshot.sequence}-${snapshot.digest}.json').writeAsBytes(bytes);
    }
    final client = MockClient((_) async => throw StateError('Network must not be contacted'));
    addTearDown(client.close);
    final catalog = VisualizerSignedCatalog(trust: trust, client: client,
      directory: () async => directory, clock: () => now);
    await catalog.loadCached(); // Offline inventory can continue.
    await expectLater(catalog.refresh(), throwsFormatException);
  });
}
