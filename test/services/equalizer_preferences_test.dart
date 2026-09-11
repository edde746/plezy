import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/audio_equalizer.dart';
import 'package:plezy/services/equalizer_preferences.dart';

void main() {
  test('reopened editor shares pending changes; older queued writes cannot win', () async {
    final store = ValueNotifier(const EqualizerSettings.empty());
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    final writes = <EqualizerSettings>[];
    final preferences = EqualizerPreferences.forTesting(store, (value) async {
      writes.add(value);
      if (writes.length == 1) {
        firstStarted.complete();
        await releaseFirst.future;
      }
      store.value = value;
    });
    addTearDown(preferences.dispose);
    addTearDown(store.dispose);
    final first = preferences.update((s) => s.withProfile(EqualizerAudioType.global, EqualizerProfile(preampDb: 1)));
    await firstStarted.future;
    final oldQueued = preferences.update(
      (s) => s.withProfile(EqualizerAudioType.global, s.resolve(EqualizerAudioType.global).copyWith(bassDb: 2)),
    );
    // A new editor sees the in-flight desired values and changes another profile.
    expect(preferences.value.resolve(EqualizerAudioType.global).bassDb, 2);
    final newest = preferences.update((s) => s.withProfile(EqualizerAudioType.eac3, EqualizerProfile(preampDb: -3)));
    releaseFirst.complete();
    await Future.wait([first, oldQueued, newest]);
    expect(writes, hasLength(2));
    expect(store.value.resolve(EqualizerAudioType.global).preampDb, 1);
    expect(store.value.resolve(EqualizerAudioType.global).bassDb, 2);
    expect(store.value.resolve(EqualizerAudioType.eac3).preampDb, -3);
    expect(preferences.value, store.value);
  });

  test('failed disk write repairs optimistic cache and remains retryable', () async {
    final store = ValueNotifier(const EqualizerSettings.empty());
    var fail = true;
    final preferences = EqualizerPreferences.forTesting(store, (value) async {
      store.value = value;
      if (fail) {
        fail = false;
        throw StateError('disk failure');
      }
    });
    addTearDown(preferences.dispose);
    addTearDown(store.dispose);
    await expectLater(
      preferences.update((s) => s.withProfile(EqualizerAudioType.global, EqualizerProfile(bassDb: 2))),
      throwsStateError,
    );
    expect(preferences.value, const EqualizerSettings.empty());
    expect(store.value, const EqualizerSettings.empty());
    await preferences.update((s) => s.withProfile(EqualizerAudioType.global, EqualizerProfile(bassDb: 3)));
    expect(store.value.resolve(EqualizerAudioType.global).bassDb, 3);
  });
}
