import 'dart:math';

import '../../media/media_item.dart';
import 'music_playback_service.dart';

/// Pure, deterministic queue state for the music session — no I/O, no player.
///
/// Holds the canonical track list ([_items], insertion order) plus a playback
/// order ([_order], indexes into the canonical list; the identity permutation
/// while unshuffled) and the [cursor] into that playback order. Every index a
/// caller passes in ([jumpTo], [removeAt], [move]) is a *playback-order*
/// index — the same flat list the queue UI renders via [queue].
///
/// The controller only mutates state; deciding what to do about it (open a
/// new track, re-arm gapless, stop) is the service's job.
class MusicQueueController {
  MusicQueueController({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Canonical tracks in the order they were loaded/enqueued. Restored as
  /// the playback order when shuffle turns off.
  final List<MediaItem> _items = [];

  /// Playback order: indexes into [_items]. Identity when unshuffled.
  List<int> _order = [];

  int _cursor = -1;
  bool _shuffled = false;

  MusicRepeatMode repeatMode = MusicRepeatMode.off;

  bool get isEmpty => _items.isEmpty;
  int get length => _order.length;
  bool get shuffled => _shuffled;

  /// Position of the current track within the playback order; -1 when empty.
  int get cursor => _cursor;

  MediaItem? get current => trackAt(_cursor);

  /// Full queue in playback order (what the UI renders).
  List<MediaItem> get queue => [for (final i in _order) _items[i]];

  MediaItem? trackAt(int queueIndex) =>
      queueIndex >= 0 && queueIndex < _order.length ? _items[_order[queueIndex]] : null;

  /// Replace the queue with [tracks], starting at [startIndex]. With
  /// [shuffle] the start track is anchored first and the rest shuffle after
  /// it (it keeps playing / plays first).
  void load(List<MediaItem> tracks, {int startIndex = 0, bool shuffle = false}) {
    _items
      ..clear()
      ..addAll(tracks);
    _order = List.generate(tracks.length, (i) => i);
    _shuffled = false;
    _cursor = tracks.isEmpty ? -1 : startIndex.clamp(0, tracks.length - 1);
    if (shuffle && tracks.isNotEmpty) _shuffleAnchoringCurrent();
  }

  void clear() {
    _items.clear();
    _order = [];
    _cursor = -1;
    _shuffled = false;
  }

  /// Playback-order position that plays after the current one, or null when
  /// playback should end there. Natural advancement (`manual: false`)
  /// honors repeat-one by returning the cursor itself; a user-initiated
  /// next (`manual: true`) always steps to the following entry.
  int? nextIndex({bool manual = false}) {
    if (_order.isEmpty || _cursor < 0) return null;
    if (repeatMode == MusicRepeatMode.one && !manual) return _cursor;
    final next = _cursor + 1;
    if (next < _order.length) return next;
    return repeatMode == MusicRepeatMode.all ? 0 : null;
  }

  /// Playback-order position before the current one, or null when there is
  /// none (the service restarts the current track in that case).
  int? previousIndex() {
    if (_order.isEmpty || _cursor < 0) return null;
    final prev = _cursor - 1;
    if (prev >= 0) return prev;
    return repeatMode == MusicRepeatMode.all ? _order.length - 1 : null;
  }

  void jumpTo(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= _order.length) return;
    _cursor = queueIndex;
  }

  /// Insert [tracks] directly after the current entry.
  void addNext(List<MediaItem> tracks) {
    if (tracks.isEmpty) return;
    _order.insertAll(_cursor < 0 ? 0 : _cursor + 1, _append(tracks));
    if (_cursor < 0) _cursor = 0;
  }

  void addToEnd(List<MediaItem> tracks) {
    if (tracks.isEmpty) return;
    _order.addAll(_append(tracks));
    if (_cursor < 0) _cursor = 0;
  }

  List<int> _append(List<MediaItem> tracks) {
    final first = _items.length;
    _items.addAll(tracks);
    return List.generate(tracks.length, (i) => first + i);
  }

  /// Remove the queue entry at playback-order [queueIndex]. Returns true
  /// when the removed entry was the current track — the cursor then points
  /// at what used to be the next entry (or the new last entry when the
  /// current one was last; -1 when the queue emptied), and the caller
  /// decides whether to open it.
  bool removeAt(int queueIndex) {
    if (queueIndex < 0 || queueIndex >= _order.length) return false;
    final wasCurrent = queueIndex == _cursor;
    final itemIndex = _order.removeAt(queueIndex);
    _items.removeAt(itemIndex);
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] > itemIndex) _order[i]--;
    }
    if (queueIndex < _cursor) {
      _cursor--;
    } else if (_cursor >= _order.length) {
      _cursor = _order.length - 1;
    }
    return wasCurrent;
  }

  /// Reorder the playback queue: move the entry at [from] to [to] (both
  /// playback-order indexes). The cursor keeps tracking the current track.
  void move(int from, int to) {
    if (from < 0 || from >= _order.length || to < 0 || to >= _order.length || from == to) {
      return;
    }
    final entry = _order.removeAt(from);
    _order.insert(to, entry);
    if (from == _cursor) {
      _cursor = to;
    } else if (from < _cursor && to >= _cursor) {
      _cursor--;
    } else if (from > _cursor && to <= _cursor) {
      _cursor++;
    }
  }

  /// Toggle shuffle. Turning it on anchors the current track first and
  /// shuffles the rest after it; turning it off restores canonical order
  /// with the cursor following the current track.
  void toggleShuffle() {
    if (_items.isEmpty) return;
    if (_shuffled) {
      final currentItem = _order[_cursor];
      _order = List.generate(_items.length, (i) => i);
      _cursor = currentItem;
      _shuffled = false;
    } else {
      _shuffleAnchoringCurrent();
    }
  }

  void _shuffleAnchoringCurrent() {
    final anchor = _order[_cursor < 0 ? 0 : _cursor];
    final rest = [
      for (final i in _order)
        if (i != anchor) i,
    ]..shuffle(_random);
    _order = [anchor, ...rest];
    _cursor = 0;
    _shuffled = true;
  }

  /// Drop everything after the current entry (playback order), including
  /// the underlying canonical items.
  void clearUpcoming() {
    if (_cursor < 0 || _cursor >= _order.length - 1) return;
    final removedItemIndexes = _order.sublist(_cursor + 1)..sort();
    _order.removeRange(_cursor + 1, _order.length);
    for (final itemIndex in removedItemIndexes.reversed) {
      _items.removeAt(itemIndex);
      for (var i = 0; i < _order.length; i++) {
        if (_order[i] > itemIndex) _order[i]--;
      }
    }
  }
}
