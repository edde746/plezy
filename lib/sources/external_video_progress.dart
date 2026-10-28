import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'source_controller.dart';
import 'source_models.dart';

/// Profile-scoped progress owner for one connected-source video in the shared
/// video player. It serializes journal writes and never assigns the source a
/// synthetic server identity.
class ExternalVideoProgressSession {
  ExternalVideoProgressSession._(this._sources, this._profileId, this._generation, this._progress);

  final SourceController _sources;
  final String _profileId;
  final int _generation;
  PublicationProgress _progress;
  Future<void> _writes = Future<void>.value();
  bool _closing = false;
  bool _closed = false;

  int get resumePositionMs => _progress.finished ? 0 : _progress.filePositionMs;

  static Future<ExternalVideoProgressSession> open(
    SourceController sources,
    SourceEntry entry,
    PublicationFile file,
  ) async {
    await sources.ready;
    sources.requireSession();
    final profile = sources.profileId!;
    final generation = sources.generation;
    final initial = PublicationProgress(
      entryKey: entry.key,
      edition: sourceDigest(jsonEncode([file.fingerprint])),
      mode: PublicationMode.watching,
      session: const Uuid().v4(),
    );
    var progress = await sources.openProgress(entry, initial);
    sources.requireSession(generation);
    if (sources.cloudConflict(initial.key) || await sources.repository.remoteConflict(profile, initial.key) != null) {
      throw const SourceException(SourceFailure.conflict);
    }

    sources.holdProgress(progress.key);
    try {
      if (progress.finished) {
        progress = await sources.repository.saveProgress(
          profile,
          progress.copyWith(positionMs: 0, filePositionMs: 0, fraction: 0, finished: false),
          kind: 'restart',
        );
      }
      sources.requireSession(generation);
      return ExternalVideoProgressSession._(sources, profile, generation, progress);
    } catch (_) {
      if (sources.current(generation) && sources.profileId == profile) sources.releaseProgress(progress.key);
      rethrow;
    }
  }

  Future<void> record(String state, Duration position, Duration duration) {
    if (_closing || _closed) return _writes;
    final write = _writes.then((_) async {
      if (_closed || _sources.blocked || _sources.profileId != _profileId || !_sources.current(_generation)) {
        return;
      }
      final durationMs = duration.inMilliseconds;
      if (durationMs <= 0) return;
      final positionMs = position.inMilliseconds.clamp(0, durationMs).toInt();
      final fraction = positionMs / durationMs;
      final finished = state == 'stopped' && fraction >= 0.9;
      _progress = await _sources.repository.saveProgress(
        _profileId,
        _progress.copyWith(positionMs: positionMs, filePositionMs: positionMs, fraction: fraction, finished: finished),
        kind: finished ? 'finished' : 'position',
      );
    });
    // A journal write failure must not interrupt playback. Leave the previous
    // revision intact so a later tick can retry with the same optimistic token.
    _writes = write.catchError((Object _) {});
    return _writes;
  }

  Future<void> close() async {
    if (_closing || _closed) return;
    _closing = true;
    await _writes;
    _closed = true;
    if (!_sources.blocked && _sources.profileId == _profileId && _sources.current(_generation)) {
      _sources.releaseProgress(_progress.key);
      _sources.scheduleSync();
    }
  }
}
