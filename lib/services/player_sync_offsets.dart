import 'package:flutter/foundation.dart';

import '../media/media_item.dart';
import '../mpv/mpv.dart';
import 'scoped_player_prefs.dart';

/// The audio, primary-subtitle, and secondary-subtitle sync offsets one video
/// [Player] is applying, in milliseconds, plus MPV's primary subtitle timestamp
/// multiplier used for gradual drift correction.
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
  static const secondarySubtitleProperty = 'secondary-sub-delay';
  static const subtitleRateProperty = 'sub-speed';

  final Player _player;
  int _audioMs = 0;
  int _subtitleMs = 0;
  int _secondarySubtitleMs = 0;
  double _subtitleRate = 1.0;

  int get audioMs => _audioMs;
  int get subtitleMs => _subtitleMs;
  int get secondarySubtitleMs => _secondarySubtitleMs;
  double get subtitleRate => _subtitleRate;

  /// Make the player apply [item]'s scope-resolved offsets.
  ///
  /// Every item starts from its own resolved value, so a change made under
  /// "Don't save" stays with the item it was made on instead of following the
  /// player into the next episode (#2449). An offset the player already
  /// applies is not rewritten.
  Future<void> applyFor(MediaItem item) async {
    await _apply(audioProperty, ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, item));
    await _apply(subtitleProperty, ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, item));
    if (_player.supportsSecondarySubtitles) {
      await _apply(
        secondarySubtitleProperty,
        ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.secondarySubtitleSyncOffset, item),
      );
    }
    if (_player.supportsSubtitleStepSync) {
      await _applySubtitleRate(ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncRate, item));
    }
  }

  Future<void> _applySubtitleRate(double rate) async {
    if ((rate - _subtitleRate).abs() < 0.000001) return;
    await _player.setProperty(subtitleRateProperty, rate.toStringAsFixed(6));
    recordSubtitleRate(rate);
  }

  /// Record a subtitle timestamp multiplier already written to the player.
  void recordSubtitleRate(double rate) {
    if (!rate.isFinite ||
        rate < ScopedPlayerPrefs.minimumSubtitleSyncRate ||
        rate > ScopedPlayerPrefs.maximumSubtitleSyncRate) {
      throw ArgumentError.value(rate, 'rate', 'outside the supported subtitle sync range');
    }
    if ((_subtitleRate - rate).abs() < 0.000001) return;
    _subtitleRate = rate;
    notifyListeners();
  }

  Future<void> _apply(String property, int offsetMs) async {
    final int applied = switch (property) {
      audioProperty => _audioMs,
      subtitleProperty => _subtitleMs,
      secondarySubtitleProperty => _secondarySubtitleMs,
      _ => throw ArgumentError.value(property, 'property', 'not a sync offset property'),
    };
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
      case secondarySubtitleProperty:
        if (_secondarySubtitleMs == offsetMs) return;
        _secondarySubtitleMs = offsetMs;
      default:
        throw ArgumentError.value(property, 'property', 'not a sync offset property');
    }
    notifyListeners();
  }
}
