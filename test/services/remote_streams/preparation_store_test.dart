import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/source_database.dart';
import 'package:plezy/services/remote_streams/remote_stream_store.dart';
import 'package:plezy/services/remote_streams/remote_stream_models.dart';
import '../../test_helpers/prefs.dart';

void main() {
  late SourceDatabase database;
  setUp(() {
    resetSharedPreferencesForTest();
    database = SourceDatabase(NativeDatabase.memory());
    RemoteStreamStore.useDatabaseForTesting(database);
  });
  tearDown(() async {
    RemoteStreamStore.useDatabaseForTesting(null);
    await database.close();
  });
  test('transactions preserve concurrent account edits and encrypted state', () async {
    final account = RemoteStreamAccount.create(
      service: RemoteStreamService.realDebrid,
      displayName: 'Test',
      accessToken: 'secret',
    );
    await Future.wait([
      RemoteStreamStore.update('alice', (current) => current.copyWith(accounts: [account])),
      RemoteStreamStore.update('alice', (current) => current.copyWith(nativePeerEnabled: true)),
    ]);
    final state = await RemoteStreamStore.load('alice');
    expect(state.accounts.single.accessToken, 'secret');
    expect(state.nativePeerEnabled, isTrue);
    final raw = (await database.customSelect('SELECT payload FROM remote_stream_state').getSingle()).read<String>(
      'payload',
    );
    expect(raw, startsWith('enc:v2:'));
    expect(raw, isNot(contains('secret')));
    expect((await RemoteStreamStore.load('bob')).accounts, isEmpty);
  });
  test('only one engine claims a job; a stale owner cannot release its successor', () async {
    expect(await RemoteStreamStore.claim('alice', 'job', 'foreground'), isTrue);
    expect(await RemoteStreamStore.claim('alice', 'job', 'worker'), isFalse);
    await database.customStatement('UPDATE remote_preparation_claims SET expires=0');
    expect(await RemoteStreamStore.claim('alice', 'job', 'worker'), isTrue);
    await database.customStatement('UPDATE remote_preparation_claims SET expires=0');
    await RemoteStreamStore.renewClaim('alice', 'job', 'foreground');
    final expired = (await database.customSelect('SELECT expires FROM remote_preparation_claims').getSingle())
        .read<int>('expires');
    expect(expired, 0, reason: 'A stale process cannot renew another owner');
    await RemoteStreamStore.renewClaim('alice', 'job', 'worker');
    await RemoteStreamStore.release('alice', 'job', 'foreground');
    expect(await RemoteStreamStore.claim('alice', 'job', 'foreground'), isFalse);
    await RemoteStreamStore.release('alice', 'job', 'worker');
    expect(await RemoteStreamStore.claim('alice', 'job', 'foreground'), isTrue);
  });
  test('idle cleanup observes durable jobs before removing OS work', () async {
    var cancellations = 0;
    await RemoteStreamStore.update('alice', (state) => state);
    await RemoteStreamStore.cancelRecoveryWhenIdle(() async {
      cancellations++;
    });
    expect(cancellations, 1);
    const job = RemotePreparationJob(
      id: 'job',
      accountId: 'account',
      service: RemoteStreamService.realDebrid,
      infoHash: '0123456789012345678901234567890123456789',
      title: 'Fixture',
      requestId: 'tt1234567',
      requestType: 'movie',
      addonId: 'addon',
      label: 'Video',
      state: RemotePreparationState.interrupted,
      stage: 'preparing',
      createdAt: 0,
      updatedAt: 0,
      providerJobId: '42',
    );
    await RemoteStreamStore.update('alice', (state) => state.copyWith(preparations: [job]));
    await RemoteStreamStore.cancelRecoveryWhenIdle(() async {
      cancellations++;
    });
    expect(cancellations, 1);
    await RemoteStreamStore.update(
      'alice',
      (state) => state.copyWith(preparations: [job.copyWith(state: RemotePreparationState.ready)]),
    );
    await RemoteStreamStore.cancelRecoveryWhenIdle(() async {
      cancellations++;
    });
    expect(cancellations, 2);
  });
  test('independent worker connections preserve concurrent transactions', () async {
    final directory = await Directory.systemTemp.createTemp('preparation-workers-');
    final file = File('${directory.path}/state.sqlite');
    final first = SourceDatabase(
      NativeDatabase.createInBackground(file, setup: (db) => db.execute('PRAGMA busy_timeout=10000')),
    );
    RemoteStreamStore.useDatabaseForTesting(first);
    await RemoteStreamStore.load('alice');
    final second = SourceDatabase(
      NativeDatabase.createInBackground(file, setup: (db) => db.execute('PRAGMA busy_timeout=10000')),
    );
    final account = RemoteStreamAccount.create(
      service: RemoteStreamService.realDebrid,
      displayName: 'Test',
      accessToken: 'private',
    );
    try {
      final foreground = RemoteStreamStore.update('alice', (state) => state.copyWith(accounts: [account]));
      RemoteStreamStore.useDatabaseForTesting(second);
      final worker = RemoteStreamStore.update('alice', (state) => state.copyWith(nativePeerEnabled: true));
      await Future.wait([foreground, worker]);
      final result = await RemoteStreamStore.load('alice');
      expect(result.accounts.single.id, account.id);
      expect(result.nativePeerEnabled, isTrue);
      await SourceRepository(second).forgetProfile('alice');
      await expectLater(
        RemoteStreamStore.update('alice', (state) => state.copyWith(accounts: [account])),
        throwsStateError,
      );
    } finally {
      RemoteStreamStore.useDatabaseForTesting(database);
      await first.close();
      await second.close();
      await directory.delete(recursive: true);
    }
  });
}
