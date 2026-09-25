import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../mpv/mpv.dart';
import 'scoped_player_prefs.dart';

/// The audio and subtitle sync offsets one video [Player] is applying, in
/// milliseconds.
///
/// Both backends keep `audio-delay`/`sub-delay` across an in-place item swap,
/// so the native value outlives the item it was tuned for — and under the
/// "Don't save" scope it is stored nowhere else. This record, not the stored
/// pref, is what the player UI shows and what an item change compares against.
///
/// Attached to the player instance: a new player starts with no delay, and
/// the record goes away with the player.
final class PlayerSyncOffsets extends ChangeNotifier {
  PlayerSyncOffsets._(this._player);

  factory PlayerSyncOffsets.of(Player player) => _byPlayer[player] ??= PlayerSyncOffsets._(player);

  static final Expando<PlayerSyncOffsets> _byPlayer = Expando<PlayerSyncOffsets>('PlayerSyncOffsets');

  static const audioProperty = 'audio-delay';
  static const subtitleProperty = 'sub-delay';

  final Player _player;
  int _audioMs = 0;
  int _subtitleMs = 0;

  int get audioMs => _audioMs;
  int get subtitleMs => _subtitleMs;

  /// Make the player apply [item]'s scope-resolved offsets.
  ///
  /// Every item starts from its own resolved value, so a change made under
  /// "Don't save" stays with the item it was made on instead of following the
  /// player into the next episode (#2449). An offset the player already
  /// applies is not rewritten.
  Future<void> applyFor(MediaItem item) async {
    await _apply(audioProperty, ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, item));
    await _apply(subtitleProperty, ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, item));
  }

  Future<void> _apply(String property, int offsetMs) async {
    final applied = property == audioProperty ? _audioMs : _subtitleMs;
    if (offsetMs == applied) return;
    await _player.setProperty(property, (offsetMs / 1000.0).toString());
    recordApplied(property, offsetMs);
  }

  /// Record an offset the caller has already written to the player.
  void recordApplied(String property, int offsetMs) {
    switch (property) {
      case audioProperty:
        if (_audioMs == offsetMs) return;
        _audioMs = offsetMs;
      case subtitleProperty:
        if (_subtitleMs == offsetMs) return;
        _subtitleMs = offsetMs;
      default:
        throw ArgumentError.value(property, 'property', 'not a sync offset property');
    }
    notifyListeners();
  }
}
