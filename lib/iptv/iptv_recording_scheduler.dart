import 'dart:async';
import 'dart:io';

import 'package:disk_usage/disk_usage.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';
import '../media/live_tv_support.dart';
import '../sources/source_models.dart';
import 'iptv_models.dart';
import 'iptv_scheduled_stream_recorder.dart';
import 'iptv_source_repository.dart';

/// Runs one-off local IPTV schedules while PlezyNG is running. Dispatcharr
/// remains the durable server-side scheduler for devices that may be offline.
class IptvRecordingScheduler with WidgetsBindingObserver {
  IptvRecordingScheduler(this._repository) {
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_recovered ? _tick() : _recoverAndTick());
    });
    unawaited(_recoverAndTick());
  }

  final IptvSourceRepository _repository;
  final Map<String, IptvScheduledStreamRecorder> _active = {};
  final Set<String> _starting = {};
  final _uuid = const Uuid();
  Timer? _timer;
  bool _ticking = false;
  bool _disposed = false;
  bool _recovered = false;
  bool _recovering = false;

  Future<void> _recoverAndTick() async {
    if (_disposed || _recovered || _recovering) return;
    _recovering = true;
    try {
      await _repository.recoverLocalRecordingSchedules();
      await _removeInterruptedPartials();
      _recovered = true;
      await _tick();
    } on Object catch (error, stackTrace) {
      appLogger.w('Could not recover IPTV recording schedules', error: error, stackTrace: stackTrace);
    } finally {
      _recovering = false;
    }
  }

  Future<void> _removeInterruptedPartials() async {
    try {
      final root = await getApplicationSupportDirectory();
      final folder = Directory(p.join(root.path, 'iptv-recordings'));
      if (!await folder.exists()) return;
      await for (final entity in folder.list(recursive: true, followLinks: false)) {
        if (entity is File && p.basename(entity.path).startsWith('.') && p.basename(entity.path).contains('.partial.')) {
          try {
            await entity.delete();
          } on Object {
            // A stale partial is harmless and can be removed manually later.
          }
        }
      }
    } on Object catch (error, stackTrace) {
      appLogger.w('Could not clean interrupted IPTV recording files', error: error, stackTrace: stackTrace);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_tick());
  }

  Future<void> _tick() async {
    if (_disposed || !_recovered || _ticking) return;
    _ticking = true;
    try {
      final schedules = await _repository.dueLocalRecordingSchedules();
      final now = DateTime.now();
      for (final schedule in schedules) {
        if (_disposed || _starting.contains(schedule.id) || _active.containsKey(schedule.id)) continue;
        if (!schedule.endsAt.isAfter(now)) {
          await _repository.updateLocalRecordingSchedule(schedule.id, state: 'missed', errorCode: 'app_not_running');
        } else if (!schedule.startsAt.isAfter(now)) {
          unawaited(_record(schedule));
        }
      }
    } catch (error, stackTrace) {
      appLogger.w('IPTV recording scheduler tick failed', error: error, stackTrace: stackTrace);
    } finally {
      _ticking = false;
    }
  }

  Future<void> _record(IptvLocalRecordingSchedule schedule) async {
    if (_disposed || !_starting.add(schedule.id)) return;
    String? recordingId;
    String? profileId;
    DateTime? startedAt;
    File? partial;
    File? target;
    IptvScheduledStreamRecorder? recorder;
    LiveTvPlaybackSession? session;
    try {
      await _repository.updateLocalRecordingSchedule(schedule.id, state: 'starting');
      final config = await _repository.configuration(schedule.profileId, schedule.sourceId);
      if (config == null) throw const IptvImportException('source_missing');
      session = await _repository.startPlayback(schedule.profileId, schedule.sourceId, schedule.channelId);
      if (session == null) throw const IptvImportException('source_missing');
      final streamUrl = await session.streamUrlAt();
      final uri = streamUrl == null ? null : Uri.tryParse(streamUrl);
      if (uri == null || uri.host.isEmpty || !const {'http', 'https'}.contains(uri.scheme)) {
        throw const IptvImportException('invalid_stream_address');
      }

      final now = DateTime.now();
      final duration = schedule.endsAt.difference(now);
      if (duration <= Duration.zero || duration > const Duration(hours: 12)) {
        throw const IptvImportException('recording_schedule_invalid');
      }
      final root = await getApplicationSupportDirectory();
      final folder = Directory(p.join(root.path, 'iptv-recordings', _safePath(schedule.profileId)));
      await folder.create(recursive: true);
      try {
        final available = await DiskUsage.freeSpace(folder.path).timeout(const Duration(seconds: 3));
        if (available != null && available < 512 * 1024 * 1024) throw const IptvImportException('storage_low');
      } on IptvImportException {
        rethrow;
      } on Object {
        // Embedded targets may not expose a free-space probe.
      }
      final id = _uuid.v4();
      final slug = _safePath(schedule.programmeTitle?.isNotEmpty == true ? schedule.programmeTitle! : schedule.title);
      final stamp = now.toUtc().millisecondsSinceEpoch;
      final recordingTarget = File(p.join(folder.path, '${stamp}_${slug}_${id.substring(0, 8)}.ts'));
      final recordingPartial = File(p.join(folder.path, '.$id.partial.ts'));
      recordingId = id;
      profileId = schedule.profileId;
      startedAt = now;
      target = recordingTarget;
      partial = recordingPartial;
      await _repository.beginLocalRecording(
        IptvLocalRecording(
          id: id,
          profileId: schedule.profileId,
          sourceId: schedule.sourceId,
          channelId: schedule.channelId,
          title: schedule.title,
          programmeTitle: schedule.programmeTitle,
          filePath: recordingTarget.path,
          startedAt: now,
          state: 'recording',
        ),
      );
      await _repository.updateLocalRecordingSchedule(schedule.id, state: 'recording', recordingId: id);
      final capture = IptvScheduledStreamRecorder(
        uri: uri,
        allowHttp: config.allowHttp,
        headers: session.streamHeaders,
        outputFile: recordingPartial,
        endsAt: schedule.endsAt,
      );
      recorder = capture;
      _active[schedule.id] = capture;
      final extension = await capture.record();
      if (_disposed) throw const IptvImportException('recording_interrupted');
      if (!await recordingPartial.exists() || await recordingPartial.length() == 0) {
        throw const IptvImportException('recording_empty');
      }
      final size = await recordingPartial.length();
      final extensionlessTarget = recordingTarget.path.substring(0, recordingTarget.path.lastIndexOf('.'));
      final completedTarget = File('$extensionlessTarget$extension');
      if (await completedTarget.exists()) throw const IptvImportException('recording_conflict');
      await recordingPartial.rename(completedTarget.path);
      target = completedTarget;
      if (completedTarget.path != recordingTarget.path) {
        await _repository.updateLocalRecordingFilePath(
          profileId: schedule.profileId,
          recordingId: id,
          filePath: completedTarget.path,
        );
      }
      await _repository.finishLocalRecording(
        profileId: schedule.profileId,
        recordingId: id,
        completed: true,
        durationSeconds: DateTime.now().difference(now).inSeconds,
        sizeBytes: size,
      );
      await _repository.updateLocalRecordingSchedule(schedule.id, state: 'completed', recordingId: id);
    } on Object catch (error, stackTrace) {
      appLogger.w('IPTV scheduled recording failed', error: error, stackTrace: stackTrace);
      final errorCode = _captureErrorCode(error);
      try {
        if (partial != null && await partial.exists()) await partial.delete();
        if (recordingId != null && profileId != null) {
          final retainedSize = target != null && await target.exists() ? await target.length() : null;
          await _repository.finishLocalRecording(
            profileId: profileId,
            recordingId: recordingId,
            completed: false,
            durationSeconds: startedAt == null ? null : DateTime.now().difference(startedAt).inSeconds,
            sizeBytes: retainedSize,
            errorCode: errorCode,
          );
        }
        await _repository.updateLocalRecordingSchedule(
          schedule.id,
          state: 'failed',
          recordingId: recordingId,
          errorCode: errorCode,
        );
      } on Object catch (finalizeError, finalizeStackTrace) {
        appLogger.w('Could not finalize IPTV scheduled recording', error: finalizeError, stackTrace: finalizeStackTrace);
      }
    } finally {
      _active.remove(schedule.id);
      _starting.remove(schedule.id);
      if (recorder != null && !_disposed) await recorder.stop();
      if (session != null) await session.discard();
    }
  }

  static String _captureErrorCode(Object error) => switch (error) {
    IptvImportException(:final code) => code,
    UnsupportedError() => 'recording_encrypted_hls',
    SourceException(reason: SourceFailure.authentication) => 'authentication',
    SourceException(reason: SourceFailure.permission) => 'permission',
    SourceException(reason: SourceFailure.invalidData) => 'invalid_data',
    SourceException() => 'capture_failed',
    _ => 'capture_failed',
  };

  static String _safePath(String value) {
    final normalized = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    if (normalized.isEmpty) return 'iptv';
    return normalized.length <= 64 ? normalized : normalized.substring(0, 64);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final recorder in _active.values.toList(growable: false)) {
      await recorder.stop();
    }
    _active.clear();
  }
}
