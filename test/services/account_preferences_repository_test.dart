import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/account_preferences_source.dart';
import 'package:plezy/media/account_ref.dart';
import 'package:plezy/services/account_preferences_repository.dart';

void main() {
  const ref = AccountRef.plex(accountConnectionId: 'parent', homeUserUuid: 'home');
  const oldPreferences = AccountPreferences(preferredAudioLanguage: 'jpn');
  const currentPreferences = AccountPreferences(preferredAudioLanguage: 'fra');

  test('clear detaches a pending read and its completion cannot replace the new scope', () async {
    final old = _PendingSource();
    final current = _PendingSource();
    AccountPreferencesSource source = old;
    final repository = AccountPreferencesRepository(sourceFor: (_) async => source);
    addTearDown(repository.dispose);
    final changes = <AccountRef>[];
    repository.changes.listen(changes.add);

    final oldLoad = repository.load(ref);
    await old.readStarted.future;
    repository.clear();
    source = current;
    final currentLoad = repository.load(ref);
    await current.readStarted.future;
    current.readResult.complete(currentPreferences);
    await currentLoad;
    await pumpEventQueue();
    changes.clear();

    old.readResult.complete(oldPreferences);
    expect((await oldLoad).defaultAudioLanguage, 'jpn');
    await pumpEventQueue();
    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
    expect(changes, isEmpty);
  });

  test('invalidate fences source acquisition and does not deduplicate the replacement token read', () async {
    final sourceGate = Completer<AccountPreferencesSource?>();
    final old = _PendingSource();
    final current = _PendingSource();
    var first = true;
    final repository = AccountPreferencesRepository(
      sourceFor: (_) {
        if (first) {
          first = false;
          return sourceGate.future;
        }
        return Future.value(current);
      },
    );
    addTearDown(repository.dispose);

    final oldLoad = repository.load(ref);
    repository.invalidate(ref);
    final currentLoad = repository.load(ref);
    await current.readStarted.future;
    current.readResult.complete(currentPreferences);
    await currentLoad;
    sourceGate.complete(old);
    await old.readStarted.future;
    old.readResult.complete(oldPreferences);
    await oldLoad;

    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
    expect(repository.isAvailable(ref), isTrue);
  });

  for (final clearAll in [false, true]) {
    test(
      '${clearAll ? 'clear' : 'invalidate'} lets a started write finish only against its original account',
      () async {
        final old = _PendingSource();
        final current = _PendingSource();
        AccountPreferencesSource source = old;
        final repository = AccountPreferencesRepository(sourceFor: (_) async => source);
        addTearDown(repository.dispose);

        final write = repository.update(
          ref,
          AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'jpn'),
        );
        await old.writeStarted.future;
        if (clearAll) {
          repository.clear();
        } else {
          repository.invalidate(ref);
        }
        source = current;
        final currentLoad = repository.load(ref);
        await current.readStarted.future;
        current.readResult.complete(currentPreferences);
        await currentLoad;
        old.writeResult.complete(oldPreferences);
        expect((await write).defaultAudioLanguage, 'jpn');

        expect(old.written?.languageAt(AccountPreferenceKey.preferredAudioLanguage), 'jpn');
        expect(current.written, isNull);
        expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
      },
    );
  }

  test('a revoked source lookup cannot mark a successfully reloaded account unavailable', () async {
    final sourceGate = Completer<AccountPreferencesSource?>();
    final current = _PendingSource();
    var first = true;
    final repository = AccountPreferencesRepository(
      sourceFor: (_) {
        if (first) {
          first = false;
          return sourceGate.future;
        }
        return Future.value(current);
      },
    );
    addTearDown(repository.dispose);
    final oldLoad = repository.load(ref);
    final rejected = expectLater(oldLoad, throwsA(isA<AccountPreferencesUnavailableException>()));
    repository.clear();
    final currentLoad = repository.load(ref);
    await current.readStarted.future;
    current.readResult.complete(currentPreferences);
    await currentLoad;
    sourceGate.complete(null);
    await rejected;

    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
    expect(repository.isAvailable(ref), isTrue);
  });
}

class _PendingSource extends AccountPreferencesSource {
  final readStarted = Completer<void>();
  final writeStarted = Completer<void>();
  final readResult = Completer<AccountPreferences>();
  final writeResult = Completer<AccountPreferences>();
  AccountPreferencesPatch? written;

  @override
  AccountPreferencesCapabilities get capabilities => AccountPreferencesCapabilities.plex;

  @override
  Future<AccountPreferences> read() {
    readStarted.complete();
    return readResult.future;
  }

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch) {
    written = patch;
    writeStarted.complete();
    return writeResult.future;
  }
}
