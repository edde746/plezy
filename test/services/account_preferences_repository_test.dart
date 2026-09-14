import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/account_preferences.dart';
import 'package:plezy/media/account_preferences_source.dart';
import 'package:plezy/media/account_ref.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/models/jellyfin/jellyfin_account_preferences.dart';
import 'package:plezy/services/account_preferences_repository.dart';

void main() {
  const ref = AccountRef.plex(accountConnectionId: 'parent', homeUserUuid: 'home');
  const oldPreferences = AccountPreferences(preferredAudioLanguage: 'jpn');
  const currentPreferences = AccountPreferences(preferredAudioLanguage: 'fra');

  test('a mixed supported and unsupported patch fails before any account request', () async {
    final source = _PendingSource();
    final repository = AccountPreferencesRepository(sourceFor: (_) async => source);
    addTearDown(repository.dispose);
    await expectLater(
      repository.update(
        ref,
        AccountPreferencesPatch({
          AccountPreferenceKey.autoSelectAudio: false,
          AccountPreferenceKey.hidePlayedInLatest: true,
        }),
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(source.written, isNull);
    expect(repository.cached(ref), isNull);
  });

  test('only language preferences accept null as no preference', () {
    expect(() => AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, null), throwsArgumentError);
    final patch = AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, null);
    expect(patch.contains(AccountPreferenceKey.preferredAudioLanguage), isTrue);
    expect(patch.languageAt(AccountPreferenceKey.preferredAudioLanguage), isNull);
  });

  test('a read started during a write cannot replace its authoritative cache result', () async {
    final source = _PendingSource();
    final repository = AccountPreferencesRepository(sourceFor: (_) async => source);
    addTearDown(repository.dispose);
    final update = repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));
    await source.writeStarted.future;
    final staleRead = repository.load(ref);
    await source.readStarted.future;
    source.writeResult.complete(currentPreferences);
    await update;
    source.readResult.complete(oldPreferences);
    await staleRead;
    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
  });

  test('concurrent account updates preserve disjoint full-configuration changes', () async {
    const account = AccountRef.mediaBrowser(backend: MediaBackend.jellyfin, connectionId: 'server/user');
    final source = _ConfigurationSource();
    final sourceGate = Completer<AccountPreferencesSource?>();
    var sourceLookups = 0;
    final repository = AccountPreferencesRepository(
      sourceFor: (_) {
        sourceLookups++;
        return sourceGate.future;
      },
    );
    addTearDown(repository.dispose);

    final first = repository.update(account, AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));
    final second = repository.update(
      account,
      AccountPreferencesPatch.of(AccountPreferenceKey.hidePlayedInLatest, true),
    );
    final updates = Future.wait([first, second]);
    await pumpEventQueue();
    expect(sourceLookups, 1);
    sourceGate.complete(source);
    await source.firstReadStarted.future;
    await pumpEventQueue();
    expect(sourceLookups, 1);
    source.firstWriteGate.complete();
    await updates;

    expect(source.configuration, {
      'PlayDefaultAudioTrack': false,
      'HidePlayedInLatest': true,
      'OrderedViews': ['movies', 'shows'],
    });
    final cached = repository.cached(account)!;
    expect(cached.autoSelectAudio, isFalse);
    expect(cached.hidePlayedInLatest, isTrue);
    expect(sourceLookups, 2);
  });

  test('a failed source lookup releases the next queued writer', () async {
    final sourceGate = Completer<AccountPreferencesSource?>();
    final current = _PendingSource();
    var sourceLookups = 0;
    final repository = AccountPreferencesRepository(
      sourceFor: (_) {
        sourceLookups++;
        return sourceLookups == 1 ? sourceGate.future : Future.value(current);
      },
    );
    addTearDown(repository.dispose);

    final failed = repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));
    final rejected = expectLater(failed, throwsStateError);
    final next = repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'fr'));
    sourceGate.completeError(StateError('source lookup failed'));
    await rejected;
    await current.writeStarted.future;
    current.writeResult.complete(currentPreferences);
    await next;

    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
  });

  for (final action in ['invalidate', 'clear', 'dispose']) {
    test('$action revokes queued writers without overlapping the replacement account', () async {
      final old = _PendingSource();
      final current = _PendingSource();
      AccountPreferencesSource source = old;
      var sourceLookups = 0;
      final repository = AccountPreferencesRepository(
        sourceFor: (_) async {
          sourceLookups++;
          return source;
        },
      );
      if (action != 'dispose') addTearDown(repository.dispose);

      final first = repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));
      final firstRejected = expectLater(first, throwsA(isA<AccountPreferencesUnavailableException>()));
      await old.writeStarted.future;
      final queued = repository.update(
        ref,
        AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'ja'),
      );
      final queuedRejected = expectLater(queued, throwsA(isA<AccountPreferencesUnavailableException>()));

      switch (action) {
        case 'invalidate':
          repository.invalidate(ref);
        case 'clear':
          repository.clear();
        case 'dispose':
          repository.dispose();
      }
      source = current;
      final replacement = action == 'dispose'
          ? null
          : repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'fr'));
      await pumpEventQueue();
      expect(sourceLookups, 1);
      expect(current.written, isNull);

      old.writeResult.complete(oldPreferences);
      await firstRejected;
      await queuedRejected;
      if (replacement != null) {
        await current.writeStarted.future;
        current.writeResult.complete(currentPreferences);
        await replacement;
        expect(current.written?.languageAt(AccountPreferenceKey.preferredAudioLanguage), 'fr');
        expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
        expect(sourceLookups, 2);
      } else {
        expect(repository.cached(ref), isNull);
        expect(sourceLookups, 1);
      }
    });
  }

  test('concurrent reads still share a source read', () async {
    final source = _PendingSource();
    final repository = AccountPreferencesRepository(sourceFor: (_) async => source);
    addTearDown(repository.dispose);

    final reads = Future.wait([repository.load(ref), repository.load(ref)]);
    await source.readStarted.future;
    source.readResult.complete(currentPreferences);
    expect(await reads, [currentPreferences, currentPreferences]);
    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
  });

  test('a source lookup detached by a successful write cannot mark the account unavailable', () async {
    final sourceGate = Completer<AccountPreferencesSource?>();
    final current = _PendingSource();
    var sourceLookups = 0;
    final repository = AccountPreferencesRepository(
      sourceFor: (_) {
        sourceLookups++;
        return sourceLookups == 1 ? sourceGate.future : Future.value(current);
      },
    );
    addTearDown(repository.dispose);

    final staleRead = repository.load(ref);
    final rejected = expectLater(staleRead, throwsA(isA<AccountPreferencesUnavailableException>()));
    final update = repository.update(ref, AccountPreferencesPatch.of(AccountPreferenceKey.autoSelectAudio, false));
    await current.writeStarted.future;
    current.writeResult.complete(currentPreferences);
    await update;
    sourceGate.complete(null);
    await rejected;

    expect(repository.cached(ref)?.defaultAudioLanguage, 'fra');
    expect(repository.isAvailable(ref), isTrue);
  });

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
          AccountPreferencesPatch.of(AccountPreferenceKey.preferredAudioLanguage, 'ja'),
        );
        final rejected = expectLater(write, throwsA(isA<AccountPreferencesUnavailableException>()));
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
        await rejected;

        expect(old.written?.languageAt(AccountPreferenceKey.preferredAudioLanguage), 'ja');
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
  Future<AccountPreferences> write(AccountPreferencesPatch patch, {void Function()? checkCurrent}) {
    checkCurrent?.call();
    written = patch;
    writeStarted.complete();
    return writeResult.future;
  }
}

class _ConfigurationSource extends AccountPreferencesSource {
  Map<String, dynamic> configuration = {
    'PlayDefaultAudioTrack': true,
    'HidePlayedInLatest': false,
    'OrderedViews': ['movies', 'shows'],
  };
  final firstReadStarted = Completer<void>();
  final firstWriteGate = Completer<void>();

  @override
  AccountPreferencesCapabilities get capabilities => AccountPreferencesCapabilities.jellyfin;

  @override
  Future<AccountPreferences> read() async => JellyfinAccountPreferences.fromConfiguration(configuration);

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch, {void Function()? checkCurrent}) async {
    // A MediaBrowser POST replaces the entire Configuration from a fresh
    // read. Delay the first POST so an overlapping write would lose a key.
    final merged = JellyfinAccountPreferences.mergePatch(configuration, patch);
    if (!firstReadStarted.isCompleted) {
      firstReadStarted.complete();
      await firstWriteGate.future;
    }
    checkCurrent?.call();
    configuration = merged;
    return read();
  }
}
