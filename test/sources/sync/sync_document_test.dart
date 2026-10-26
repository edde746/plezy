import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_models.dart';
import 'package:plezy/sources/sync/sync_document.dart';
import 'package:plezy/sources/sync/sync_store.dart';

void main() {
  final a = 'a' * 32, b = 'b' * 32, key = 'f' * 64;
  test('merge is commutative, associative and idempotent; reset beats seen progress', () {
    final one = SyncDocument()..edit(key, a, {'position': 100}, {});
    expect(one.records[key]!.single.actor, a);
    expect(SyncDocument.fromJson(one.toJson()).records[key]!.single.actor, a);
    final two = SyncDocument.fromJson(one.toJson());
    two.edit(key, b, {'position': 0}, joinedClock(two.records[key]!));
    final left = SyncDocument()
      ..merge(one)
      ..merge(two)
      ..merge(one);
    final right = SyncDocument()
      ..merge(two)
      ..merge(one)
      ..merge(two);
    expect(canonicalSyncJson(left.toJson()), canonicalSyncJson(right.toJson()));
    expect(left.records[key]!.single.value['position'], 0);
    expect(left.conflicted(key), isFalse);
  });
  test('independent offline edits are retained, explicit choice converges', () {
    final one = SyncDocument()..edit(key, a, {'position': 100}, {});
    final two = SyncDocument()..edit(key, b, {'position': 20}, {});
    one.merge(two);
    expect(one.conflicted(key), isTrue);
    one.edit(key, a, {'position': 20}, joinedClock(one.records[key]!));
    two.merge(one);
    expect(two.records[key]!.single.value['position'], 20);
    expect(two.conflicted(key), isFalse);
  });
  test('deferred remote values do not become ancestors of local edits', () {
    final doc = SyncDocument();
    final basis = doc.edit(key, a, {'position': 100}, {}).clock;
    final remote = SyncDocument.fromJson(doc.toJson());
    remote.edit(key, b, {'position': 200}, joinedClock(remote.records[key]!));
    doc.merge(remote);
    doc.edit(key, a, {'position': 110}, basis);
    expect(doc.conflicted(key), isTrue);
  });
  test('equal vector with different data is corruption, not a tie breaker', () {
    final doc = SyncDocument()..edit(key, a, {'position': 1}, {});
    expect(
      () => doc.merge(
        SyncDocument({
          key: [
            SyncVersion({a: 1}, {'position': 2}),
          ],
        }),
      ),
      throwsA(isA<SourceException>()),
    );
  });
  test('encrypted documents require the key and exact authenticated filename', () async {
    final cipher = SyncCipher(SyncCipher.newCode());
    final doc = SyncDocument()..edit(key, a, {'note': 'private annotation'}, {});
    final name = SyncFile.filename(cipher.namespace, a, 1);
    final encrypted = await cipher.seal(doc, name);
    expect(encrypted, isNot(contains('private annotation')));
    expect(canonicalSyncJson((await cipher.open(encrypted, name)).toJson()), canonicalSyncJson(doc.toJson()));
    await expectLater(cipher.open(encrypted, '$name.changed'), throwsA(isA<SourceException>()));
    await expectLater(SyncCipher(SyncCipher.newCode()).open(encrypted, name), throwsA(isA<SourceException>()));
    await expectLater(cipher.open('{}', name), throwsA(isA<SourceException>()));
  });
  test('rejects bad keys, unknown schemas and unbounded clock payloads', () {
    expect(() => SyncCipher('password'), throwsA(isA<SourceException>()));
    expect(() => SyncDocument.fromJson({'version': 2, 'records': {}}), throwsA(isA<SourceException>()));
    expect(
      () => SyncDocument.fromJson({
        'version': 1,
        'records': {'../escape': []},
      }),
      throwsA(isA<SourceException>()),
    );
    expect(
      () => SyncVersion.fromJson({
        'clock': {a: -1},
        'value': {},
      }),
      throwsA(isA<SourceException>()),
    );
    expect(
      () => SyncVersion.fromJson({
        'clock': {a: 1},
        'value': {},
        'actor': 'invalid',
      }),
      throwsA(isA<SourceException>()),
    );
  });
}
