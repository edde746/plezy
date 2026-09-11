import 'package:flutter/foundation.dart';

import '../models/audio_equalizer.dart';
import '../utils/app_logger.dart';
import '../utils/latest_async_write.dart';
import 'settings_service.dart';

/// One write queue and optimistic snapshot per settings store, across editors.
/// Reopening an editor sees pending edits; an old editor cannot write behind it.
class EqualizerPreferences extends ChangeNotifier {
  static final _instances = Expando<EqualizerPreferences>();

  factory EqualizerPreferences.forSettings(SettingsService settings) => _instances[settings] ??= EqualizerPreferences._(
    settings.listenable(SettingsService.audioEqualizer),
    (value) => settings.write(SettingsService.audioEqualizer, value),
  );

  EqualizerPreferences._(this._store, this._write) {
    _value = _confirmed = _store.value;
    _store.addListener(_refresh);
  }

  @visibleForTesting
  factory EqualizerPreferences.forTesting(
    ValueListenable<EqualizerSettings> store,
    Future<void> Function(EqualizerSettings) write,
  ) => EqualizerPreferences._(store, write);

  final ValueListenable<EqualizerSettings> _store;
  final Future<void> Function(EqualizerSettings) _write;
  final _writes = LatestAsyncWrite<int>();
  late EqualizerSettings _value;
  late EqualizerSettings _confirmed;
  int _generation = 0;
  bool _pending = false;

  EqualizerSettings get value => _value;

  void _refresh() {
    if (_pending) return;
    _value = _confirmed = _store.value;
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_refresh);
    super.dispose();
  }

  Future<void> update(EqualizerSettings Function(EqualizerSettings current) change) async {
    final snapshot = change(_value);
    if (snapshot == _value) return;
    _value = snapshot;
    _pending = true;
    final generation = ++_generation;
    final token = _writes.begin(0);
    notifyListeners();
    try {
      await _writes.commitIfLatest(0, token, () async {
        try {
          await _write(snapshot);
          _confirmed = snapshot;
        } catch (error, stack) {
          // Preference backends may update their cache before the disk write
          // fails. Repair it on the same queue before accepting another edit.
          if (generation == _generation) {
            try {
              await _write(_confirmed);
            } catch (rollbackError, rollbackStack) {
              appLogger.w('Could not restore equalizer preferences', error: rollbackError, stackTrace: rollbackStack);
            }
          }
          Error.throwWithStackTrace(error, stack);
        }
      });
    } finally {
      if (generation == _generation) {
        _pending = false;
        _value = _confirmed;
        notifyListeners();
      }
    }
  }
}
