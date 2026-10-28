import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_whisper_ggml/flutter_whisper.dart' as whisper;

import '../mpv/player/platform/player_android.dart';
import 'subtitle_ai_service.dart';
import 'subtitle_retimer.dart';
import 'subtitle_whisper_cpp_service.dart';

@immutable
final class SubtitleLiveCaption {
  const SubtitleLiveCaption({required this.startMs, required this.endMs, required this.text});
  final int startMs;
  final int endMs;
  final String text;
}

/// Opt-in Android ExoPlayer caption capture. PCM remains in a bounded queue
/// and is transcribed on-device; no recording file is created.
final class SubtitlePlaybackTranscriptionService extends ChangeNotifier {
  SubtitlePlaybackTranscriptionService._();
  static final SubtitlePlaybackTranscriptionService instance = SubtitlePlaybackTranscriptionService._();

  static const int _sampleRate = 16000;
  static const int _windowSamples = _sampleRate * 5;
  static const int _strideSamples = _sampleRate * 4;
  static const int _maximumQueuedSamples = _sampleRate * 24;
  static const int _minimumFinalSamples = _sampleRate * 2;
  static const int _maximumCueCount = 50000;

  final ValueNotifier<SubtitleLiveCaption?> liveCaption = ValueNotifier<SubtitleLiveCaption?>(null);
  final List<double> _samples = <double>[];
  final List<SubtitleCue> _cues = <SubtitleCue>[];

  PlayerAndroid? _player;
  int? _playerGeneration;
  String? _audioTrackId;
  whisper.FlutterWhisper? _session;
  Timer? _timer;
  Future<void>? _inferenceFuture;
  bool _running = false;
  bool _starting = false;
  bool _polling = false;
  String? _status;
  Object? _lastError;
  String _detectedLanguage = 'auto';
  double? _streamStartMs;
  int? _nextExpectedPtsUs;
  int? _lastSampleRate;
  int? _lastChannels;
  String? _lastEncoding;
  int _packetsReceived = 0;
  int _audioGeneration = 0;
  DateTime? _startedAt;
  DateTime? _lastPacketAt;
  SubtitleTranscriptionResult? _recentTranscript;

  bool get isRunning => _running;
  bool get isStarting => _starting;
  bool get hasActiveSession => _session != null;
  String? get status => _status;
  SubtitleTranscriptionResult? get recentTranscript => _recentTranscript;
  bool get hasRecentTranscript => _recentTranscript?.cues.isNotEmpty == true;

  Future<void> start(
    PlayerAndroid player, {
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    if (_starting || _running || _session != null) {
      throw StateError('A live subtitle capture session is already active.');
    }
    if (player.usingMpvFallback) {
      throw UnsupportedError('The Android MPV fallback does not expose decoded PCM to live subtitles.');
    }
    if (player.isLivePlayback) {
      throw UnsupportedError('Live TV capture is not supported; use a VOD playback session.');
    }

    _starting = true;
    final startGeneration = player.mediaSessionGeneration;
    final startAudioTrackId = player.state.track.audio?.id;
    whisper.FlutterWhisper? loadedSession;
    var captureEnabled = false;
    try {
      _setStatus('Loading the local Whisper model…');
      _lastError = null;
      _detectedLanguage = 'auto';
      _samples.clear();
      _cues.clear();
      _streamStartMs = null;
      _nextExpectedPtsUs = null;
      _lastSampleRate = null;
      _lastChannels = null;
      _lastEncoding = null;
      _packetsReceived = 0;
      _recentTranscript = null;
      liveCaption.value = null;

      loadedSession = await SubtitleWhisperCppService.instance.loadLiveCpuSession(
        onProgress: (phase, received, total) {
          onProgress?.call(phase, received, total);
          _setStatus(phase);
        },
      );
      if (player.disposed ||
          player.usingMpvFallback ||
          player.isLivePlayback ||
          player.mediaSessionGeneration != startGeneration ||
          player.state.track.audio?.id != startAudioTrackId) {
        throw StateError('Playback changed while Whisper was loading. Start live captions again.');
      }
      captureEnabled = await player.setSubtitlePcmCaptureEnabled(true);
      if (!captureEnabled) {
        throw UnsupportedError('This Android player session cannot capture decoded PCM.');
      }
      if (player.disposed ||
          player.usingMpvFallback ||
          player.isLivePlayback ||
          player.mediaSessionGeneration != startGeneration ||
          player.state.track.audio?.id != startAudioTrackId) {
        throw StateError('Playback changed while live capture was starting. Start again on the current audio track.');
      }

      _session = loadedSession;
      loadedSession = null;
      _player = player;
      _playerGeneration = startGeneration;
      _audioTrackId = startAudioTrackId;
      _running = true;
      _startedAt = DateTime.now();
      _lastPacketAt = null;
      _setStatus('Capturing decoded audio locally; captions appear after a few seconds.');
      _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        _publishCurrentCaption();
        unawaited(_poll());
      });
    } catch (error) {
      if (captureEnabled) {
        try {
          await player.setSubtitlePcmCaptureEnabled(false);
        } catch (_) {}
      }
      await loadedSession?.dispose();
      _setStatus('Could not start live captions: $error');
      rethrow;
    } finally {
      _starting = false;
    }
  }

  Future<SubtitleTranscriptionResult?> stop() async {
    _timer?.cancel();
    _timer = null;
    final player = _player;
    _running = false;

    var invalidReason = _invalidCaptureSessionReason(player);
    if (invalidReason != null) _discardCapturedTimeline();

    if (player != null) {
      try {
        await player.setSubtitlePcmCaptureEnabled(false);
      } catch (_) {}
    }
    while (_polling) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    invalidReason ??= _invalidCaptureSessionReason(player);
    if (invalidReason == null && player != null) {
      try {
        _appendPackets(await player.drainSubtitlePcmCapture());
      } catch (_) {}
    } else {
      _discardCapturedTimeline();
    }

    while (_inferenceFuture != null) {
      await _inferenceFuture;
    }
    invalidReason ??= _invalidCaptureSessionReason(player);
    if (invalidReason != null) _discardCapturedTimeline();

    while (invalidReason == null &&
        _lastError == null &&
        _samples.length >= _windowSamples &&
        _invalidCaptureSessionReason(player) == null) {
      _startInference(finalChunk: false);
      final inference = _inferenceFuture;
      if (inference == null) break;
      await inference;
      invalidReason ??= _invalidCaptureSessionReason(player);
      if (invalidReason != null) _discardCapturedTimeline();
    }
    if (invalidReason == null &&
        _lastError == null &&
        _samples.length >= _minimumFinalSamples &&
        _invalidCaptureSessionReason(player) == null) {
      _startInference(finalChunk: true);
      final inference = _inferenceFuture;
      if (inference != null) await inference;
    }
    invalidReason ??= _invalidCaptureSessionReason(player);
    if (invalidReason != null) _discardCapturedTimeline();

    if (invalidReason == null) _publishTranscript();
    final session = _session;
    _session = null;
    if (session != null) await session.dispose();
    _player = null;
    _playerGeneration = null;
    _audioTrackId = null;
    liveCaption.value = null;

    if (_lastError != null) {
      _setStatus('Capture ended with an inference error: ' + _lastError.toString());
      throw StateError('Live subtitle transcription failed: ' + _lastError.toString());
    }
    if (invalidReason != null) {
      _setStatus(invalidReason);
    } else if (_recentTranscript == null || _recentTranscript!.cues.isEmpty) {
      _setStatus('No speech captions were produced. Check the audio track and try again.');
    } else {
      _setStatus('Captured ' + _recentTranscript!.cues.length.toString() + ' speech cues from the watched portion.');
    }
    return _recentTranscript;
  }

  String? _invalidCaptureSessionReason(PlayerAndroid? player) {
    if (player == null) return 'Playback session ended; captured transcript was discarded.';
    if (player.disposed || player.usingMpvFallback || player.mediaSessionGeneration != _playerGeneration) {
      return 'Playback session changed; captured transcript was discarded.';
    }
    if (player.state.track.audio?.id != _audioTrackId) {
      return 'Selected audio track changed; captured transcript was discarded. Start capture again on the new track.';
    }
    return null;
  }

  bool _isCurrentInference(int generation) =>
      generation == _audioGeneration && _invalidCaptureSessionReason(_player) == null;

  void _discardCapturedTimeline() {
    _audioGeneration++;
    _samples.clear();
    _cues.clear();
    _streamStartMs = null;
    _nextExpectedPtsUs = null;
    _lastSampleRate = null;
    _lastChannels = null;
    _lastEncoding = null;
    _recentTranscript = null;
    liveCaption.value = null;
  }

  Future<void> _poll() async {
    if (!_running || _polling || _starting) return;
    final player = _player;
    if (player == null) return;
    final invalidReason = _invalidCaptureSessionReason(player);
    if (invalidReason != null) {
      _running = false;
      _timer?.cancel();
      _timer = null;
      _discardCapturedTimeline();
      _setStatus(invalidReason);
      unawaited(stop());
      return;
    }
    _polling = true;
    try {
      final packets = await player.drainSubtitlePcmCapture();
      if (packets.isNotEmpty) {
        _appendPackets(packets);
        _packetsReceived += packets.length;
        _lastPacketAt = DateTime.now();
        _setStatus('Listening locally on CPU; captured ' + _packetsReceived.toString() + ' audio packets.');
      } else {
        final started = _startedAt;
        final lastPacket = _lastPacketAt;
        if (started != null && lastPacket == null && DateTime.now().difference(started) > const Duration(seconds: 8)) {
          _setStatus('No decoded PCM is reaching the capture tap. Tunneling/offload or this audio route may prevent capture.');
        } else if (lastPacket != null && DateTime.now().difference(lastPacket) > const Duration(seconds: 8)) {
          _setStatus('No recent PCM packets. Playback may be paused or the route may not expose decoded audio.');
        }
      }
      _startInference(finalChunk: false);
    } catch (error) {
      _lastError = error;
      _running = false;
      _timer?.cancel();
      _timer = null;
      try {
        await player.setSubtitlePcmCaptureEnabled(false);
      } catch (_) {}
      _setStatus('Live capture stopped: ' + error.toString());
    } finally {
      _polling = false;
    }
  }

  void _appendPackets(List<Map<String, Object?>> packets) {
    for (final packet in packets) {
      final raw = packet['pcm'];
      if (raw is! Uint8List) continue;
      final ptsUs = (packet['presentationTimeUs'] as num?)?.toInt();
      final sampleRate = (packet['sampleRate'] as num?)?.toInt();
      final channels = (packet['channels'] as num?)?.toInt();
      final encoding = packet['encoding']?.toString();
      if (ptsUs == null ||
          sampleRate == null ||
          sampleRate < 8000 ||
          sampleRate > 192000 ||
          channels == null ||
          channels < 1 ||
          channels > 8 ||
          (encoding != 'pcm16' && encoding != 'float32')) {
        continue;
      }
      final bytesPerSample = encoding == 'pcm16' ? 2 : 4;
      final bytesPerFrame = bytesPerSample * channels;
      final frames = raw.length ~/ bytesPerFrame;
      if (frames <= 0) continue;

      final changedFormat = (_lastSampleRate != null && _lastSampleRate != sampleRate) ||
          (_lastChannels != null && _lastChannels != channels) ||
          (_lastEncoding != null && _lastEncoding != encoding);
      final expected = _nextExpectedPtsUs;
      final gapUs = expected == null ? 0 : ptsUs - expected;
      if (changedFormat || (expected != null && (gapUs < -150000 || gapUs > 1500000))) {
        _resetAudioWindow(ptsUs);
      } else if (_streamStartMs == null) {
        _streamStartMs = ptsUs / 1000.0;
      } else if (gapUs > 40000 && gapUs <= 250000) {
        final silenceSamples = (gapUs * _sampleRate / 1000000).round();
        if (silenceSamples > 0 && silenceSamples <= _sampleRate ~/ 4) {
          _samples.addAll(List<double>.filled(silenceSamples, 0));
        }
      }

      _lastSampleRate = sampleRate;
      _lastChannels = channels;
      _lastEncoding = encoding;
      _nextExpectedPtsUs = ptsUs + (frames * 1000000 / sampleRate).round();
      final data = ByteData.sublistView(raw);
      final mono = Float32List(frames);
      for (var frame = 0; frame < frames; frame++) {
        var total = 0.0;
        for (var channel = 0; channel < channels; channel++) {
          final offset = frame * bytesPerFrame + channel * bytesPerSample;
          final value = encoding == 'pcm16'
              ? data.getInt16(offset, Endian.little) / 32768.0
              : data.getFloat32(offset, Endian.little);
          total += value.isFinite ? value.clamp(-1.0, 1.0) : 0.0;
        }
        mono[frame] = (total / channels).clamp(-1.0, 1.0);
      }

      final outputLength = (frames * _sampleRate / sampleRate).round();
      for (var index = 0; index < outputLength; index++) {
        final sourcePosition = index * sampleRate / _sampleRate;
        final left = sourcePosition.floor().clamp(0, frames - 1).toInt();
        final right = (left + 1).clamp(0, frames - 1).toInt();
        final fraction = sourcePosition - left;
        _samples.add((mono[left] * (1.0 - fraction) + mono[right] * fraction).clamp(-1.0, 1.0));
      }
      if (_streamStartMs == null) _streamStartMs = ptsUs / 1000.0;
      _trimOldSamples();
    }
  }

  void _trimOldSamples() {
    if (_samples.length <= _maximumQueuedSamples) return;
    final trim = _samples.length - _maximumQueuedSamples;
    _samples.removeRange(0, trim);
    _streamStartMs = (_streamStartMs ?? 0) + trim * 1000.0 / _sampleRate;
  }

  void _resetAudioWindow(int ptsUs) {
    _audioGeneration++;
    _samples.clear();
    _streamStartMs = ptsUs / 1000.0;
    _nextExpectedPtsUs = null;
    _lastSampleRate = null;
    _lastChannels = null;
    _lastEncoding = null;
  }

  void _startInference({required bool finalChunk}) {
    if (_inferenceFuture != null || _session == null || _streamStartMs == null) return;
    if (_samples.length < _windowSamples && !(finalChunk && _samples.length >= _minimumFinalSamples)) return;
    final count = math.min(_windowSamples, _samples.length).toInt();
    final samples = Float32List.fromList(_samples.take(count).toList(growable: false));
    final startMs = _streamStartMs!.round();
    final consume = finalChunk ? count : math.min(_strideSamples, count).toInt();
    final generation = _audioGeneration;
    final session = _session!;
    _inferenceFuture = _transcribeWindow(session, samples, startMs, generation)
        .then<void>((_) {
          if (generation != _audioGeneration) return;
          if (consume <= _samples.length) {
            _samples.removeRange(0, consume);
            _streamStartMs = (_streamStartMs ?? startMs.toDouble()) + consume * 1000.0 / _sampleRate;
          }
        })
        .catchError((Object error) {
          _lastError = error;
          _running = false;
          _timer?.cancel();
          _timer = null;
          final player = _player;
          if (player != null) unawaited(player.setSubtitlePcmCaptureEnabled(false));
          _setStatus('Whisper inference failed: ' + error.toString());
        })
        .whenComplete(() {
          _inferenceFuture = null;
          _publishTranscript();
          if (_running && _isCurrentInference(generation)) _startInference(finalChunk: false);
        });
  }

  Future<void> _transcribeWindow(
    whisper.FlutterWhisper session,
    Float32List samples,
    int startMs,
    int generation,
  ) async {
    if (samples.length < _minimumFinalSamples) return;
    final result = await session.transcribe(
      samples,
      config: const whisper.WhisperTranscribeConfig(
        language: 'auto',
        threads: 2,
        splitOnWord: true,
        noSpeechThreshold: 0.6,
      ),
    );
    if (!_isCurrentInference(generation)) return;
    final language = result.language.trim();
    if (language.isNotEmpty && language.toLowerCase() != 'auto') _detectedLanguage = language;
    for (final segment in result.segments) {
      final text = segment.text.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (text.isEmpty || text.length > 600) continue;
      final start = startMs + segment.start.inMilliseconds;
      final end = startMs + segment.end.inMilliseconds;
      if (start < 0 || end <= start || end > SubtitleRetimer.maximumTimeMs) continue;
      _mergeCue(SubtitleCue(index: 0, startMs: start, endMs: end, text: text));
    }
  }

  void _mergeCue(SubtitleCue cue) {
    final normalized = _normalize(cue.text);
    final existingIndex = _cues.indexWhere((existing) {
      final overlap = math.max(0, math.min(existing.endMs, cue.endMs) - math.max(existing.startMs, cue.startMs));
      final shorterDuration = math.max(1, math.min(existing.endMs - existing.startMs, cue.endMs - cue.startMs));
      if (overlap / shorterDuration < 0.35) return false;
      final left = _normalize(existing.text);
      if (left == normalized) return true;
      final leftWords = left.split(' ').where((word) => word.isNotEmpty).toSet();
      final rightWords = normalized.split(' ').where((word) => word.isNotEmpty).toSet();
      if (leftWords.isEmpty || rightWords.isEmpty) return false;
      final similarity = leftWords.intersection(rightWords).length / leftWords.union(rightWords).length;
      return similarity >= 0.68;
    });
    if (existingIndex >= 0) {
      final old = _cues[existingIndex];
      _cues[existingIndex] = SubtitleCue(
        index: old.index,
        startMs: math.min(old.startMs, cue.startMs).toInt(),
        endMs: math.max(old.endMs, cue.endMs).toInt(),
        text: cue.text.length > old.text.length ? cue.text : old.text,
      );
    } else if (_cues.length < _maximumCueCount) {
      _cues.add(cue);
    }
    _cues.sort((left, right) => left.startMs.compareTo(right.startMs));
    for (var index = 0; index < _cues.length; index++) {
      final cue = _cues[index];
      _cues[index] = SubtitleCue(index: index + 1, startMs: cue.startMs, endMs: cue.endMs, text: cue.text);
    }
    _publishTranscript();
  }

  void _publishTranscript() {
    final player = _player;
    if (_cues.isEmpty) return;
    final cueEnd = _cues.map((cue) => cue.endMs).reduce((left, right) => left > right ? left : right);
    final playerDuration = player?.state.duration.inMilliseconds ?? 0;
    final duration = math.max(cueEnd, playerDuration);
    _recentTranscript = SubtitleTranscriptionResult(
      cues: List.unmodifiable(_cues),
      durationMs: duration.clamp(1, SubtitleRetimer.maximumTimeMs).toInt(),
      requestedProvider: SubtitleInferenceProvider.cpu,
      runtimeProvider: 'Android ExoPlayer decoded PCM; whisper.cpp CPU',
      fellBackToCpu: false,
      detectedLanguage: _detectedLanguage,
      translatedToEnglish: false,
    );
    notifyListeners();
  }

  void _publishCurrentCaption() {
    final player = _player;
    if (!_running || player == null || _cues.isEmpty) {
      if (liveCaption.value != null) liveCaption.value = null;
      return;
    }
    final position = player.currentPosition.inMilliseconds;
    SubtitleCue? current;
    for (final cue in _cues.reversed) {
      if (position >= cue.startMs - 1600 && position <= cue.endMs + 2200) {
        current = cue;
        break;
      }
      if (cue.startMs < position - 5000) break;
    }
    final next = current == null
        ? null
        : SubtitleLiveCaption(startMs: current.startMs, endMs: current.endMs, text: current.text);
    final previous = liveCaption.value;
    if (previous?.startMs != next?.startMs ||
        previous?.endMs != next?.endMs ||
        previous?.text != next?.text) {
      liveCaption.value = next;
    }
  }

  String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'<[^>]*>|\{[^}]*\}'), ' ')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

  void _setStatus(String status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }
}
