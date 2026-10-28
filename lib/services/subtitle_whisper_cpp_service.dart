import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_whisper_ggml/flutter_whisper.dart' as whisper;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'subtitle_retimer.dart';

final class SubtitleWhisperResult {
  const SubtitleWhisperResult({
    required this.cues,
    required this.durationMs,
    required this.detectedLanguage,
    required this.runtimeProvider,
    required this.fellBackToCpu,
    required this.translatedToEnglish,
  });

  final List<SubtitleCue> cues;
  final int durationMs;
  final String detectedLanguage;
  final String runtimeProvider;
  final bool fellBackToCpu;
  final bool translatedToEnglish;
}

/// whisper.cpp provides the multilingual CPU baseline and optional compiled
/// CUDA/Vulkan devices. GPU use is selected only from devices reported by the
/// native runtime; a failed GPU load or inference is retried on CPU.
abstract final class SubtitleWhisperCppService {
  static final SubtitleWhisperCppService instance = SubtitleWhisperCppService._();
  SubtitleWhisperCppService._();

  static const int _maximumAudioHours = 8;
  static const int _maximumCues = 50000;
  static const int _maximumCueCharacters = 600;
  static const int _maximumWavBytes = 1024 * 1024 * 1024;
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');
  static const bool _tizenBuild = bool.fromEnvironment('PLEZY_TIZEN');
  static const bool _webOsBuild = bool.fromEnvironment('PLEZY_WEBOS');

  static bool get supportedPlatform =>
      !_tvOsBuild &&
      !_tizenBuild &&
      !_webOsBuild &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isWindows ||
          Platform.isMacOS ||
          Platform.isLinux);

  /// Loads the same verified multilingual model used by WAV transcription for
  /// repeated, in-memory Android PCM windows. The caller owns and disposes it.
  Future<whisper.FlutterWhisper> loadLiveCpuSession({
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    if (!supportedPlatform) {
      throw UnsupportedError('Local Whisper inference is unavailable on this platform.');
    }
    final modelDirectory =
        p.join((await getApplicationSupportDirectory()).path, 'subtitle_models', 'whisper_cpp');
    final model = whisper.WhisperModels.baseQ5_1;
    return whisper.FlutterWhisper.loadModel(
      model: model,
      modelDirectory: modelDirectory,
      config: const whisper.WhisperModelConfig(useGpu: false),
      onDownloadProgress: (progress) {
        onProgress?.call('Downloading multilingual ' + model.id, progress.receivedBytes, progress.totalBytes);
      },
      onModelProgress: (progress) => onProgress?.call('Loading Whisper model', progress, 100),
    );
  }

  Future<SubtitleWhisperResult> transcribeWav(
    String wavPath, {
    required bool requestGpu,
    bool translateToEnglish = false,
    String? languageCode,
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    if (!supportedPlatform) throw UnsupportedError('Local Whisper inference is unavailable on this platform.');
    final normalizedLanguageCode = languageCode?.trim().toLowerCase().split(RegExp(r'[-_]')).first ?? '';
    final selectedLanguage = normalizedLanguageCode.isEmpty || normalizedLanguageCode == 'auto' ? 'auto' : normalizedLanguageCode;
    if (selectedLanguage != 'auto' && !RegExp(r'^[a-z]{2,3}$').hasMatch(selectedLanguage)) {
      throw ArgumentError.value(languageCode, 'languageCode', 'Use a two or three letter language code or auto.');
    }
    final durationMs = await _WavDurationReader.readDurationMs(wavPath);
    if (durationMs <= 0 || durationMs > _maximumAudioHours * 60 * 60 * 1000) {
      throw const FormatException('WAV duration must be between one millisecond and eight hours.');
    }
    final modelDirectory = p.join((await getApplicationSupportDirectory()).path, 'subtitle_models', 'whisper_cpp');
    final model = whisper.WhisperModels.baseQ5_1;
    List<whisper.WhisperDevice> devices = [];
    if (requestGpu) {
      try {
        devices = whisper.FlutterWhisper.availableDevices.where((device) => device.isGpu).toList();
      } catch (_) {
        devices = [];
      }
    }
    final selectedDevice = devices.isEmpty ? null : devices.first;
    if (requestGpu && selectedDevice == null) {
      return _run(
        wavPath,
        durationMs,
        modelDirectory,
        model,
        const whisper.WhisperModelConfig(useGpu: false),
        translated: translateToEnglish,
        onProgress: onProgress,
        runtimeProvider: 'CPU (no compiled GPU device detected)',
        fellBackToCpu: true,
        languageCode: selectedLanguage,
      );
    }

    try {
      return await _run(
        wavPath,
        durationMs,
        modelDirectory,
        model,
        selectedDevice == null
            ? const whisper.WhisperModelConfig(useGpu: false)
            : whisper.WhisperModelConfig.forDevice(selectedDevice),
        translated: translateToEnglish,
        onProgress: onProgress,
        runtimeProvider: selectedDevice?.name ?? 'CPU',
        fellBackToCpu: false,
        languageCode: selectedLanguage,
      );
    } catch (error) {
      if (selectedDevice == null) rethrow;
      onProgress?.call('GPU inference failed; restarting with CPU', 0, 0);
      return _run(
        wavPath,
        durationMs,
        modelDirectory,
        model,
        const whisper.WhisperModelConfig(useGpu: false),
        translated: translateToEnglish,
        onProgress: onProgress,
        runtimeProvider: 'CPU (GPU fallback)',
        fellBackToCpu: true,
        languageCode: selectedLanguage,
      );
    }
  }

  Future<SubtitleWhisperResult> _run(
    String wavPath,
    int durationMs,
    String modelDirectory,
    whisper.WhisperModel model,
    whisper.WhisperModelConfig config, {
    required bool translated,
    required String runtimeProvider,
    required bool fellBackToCpu,
    required String languageCode,
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    final session = await whisper.FlutterWhisper.loadModel(
      model: model,
      modelDirectory: modelDirectory,
      config: config,
      onDownloadProgress: (progress) {
        onProgress?.call('Downloading multilingual ${model.id}', progress.receivedBytes, progress.totalBytes);
      },
      onModelProgress: (progress) => onProgress?.call('Loading Whisper model', progress, 100),
    );
    try {
      onProgress?.call(translated ? 'Translating audio to English' : 'Transcribing multilingual audio', 0, 0);
      final result = await session.transcribeFile(
        wavPath,
        config: whisper.WhisperTranscribeConfig(
          language: languageCode,
          translate: translated,
          threads: Platform.numberOfProcessors.clamp(1, 8).toInt(),
          noSpeechThreshold: 0.6,
          splitOnWord: true,
        ),
        onProgress: (progress) => onProgress?.call('Whisper inference', progress, 100),
      );
      final cues = <SubtitleCue>[];
      for (final segment in result.segments) {
        final text = segment.text.trim().replaceAll(RegExp(r'\s+'), ' ');
        final startRaw = segment.start.inMilliseconds;
        if (text.isEmpty || text.length > _maximumCueCharacters || startRaw >= durationMs) continue;
        final startMs = startRaw.clamp(0, durationMs).toInt();
        final endMs = segment.end.inMilliseconds.clamp(startMs + 1, durationMs).toInt();
        if (endMs <= startMs) continue;
        cues.add(SubtitleCue(index: cues.length + 1, startMs: startMs, endMs: endMs, text: text));
        if (cues.length >= _maximumCues) break;
      }
      if (cues.isEmpty) throw const FormatException('Whisper did not produce any speech cues.');
      return SubtitleWhisperResult(
        cues: List.unmodifiable(cues),
        durationMs: durationMs,
        detectedLanguage: result.language,
        runtimeProvider: runtimeProvider,
        fellBackToCpu: fellBackToCpu,
        translatedToEnglish: translated,
      );
    } finally {
      await session.dispose();
    }
  }
}

abstract final class _WavDurationReader {
  static Future<int> readDurationMs(String path) async {
    final file = await File(path).open(mode: FileMode.read);
    try {
      final length = await file.length();
      if (length < 44) throw const FormatException('WAV file is too short.');
      if (length > _maximumWavBytes) {
        throw const FormatException('WAV file exceeds the 1 GiB Whisper processing limit.');
      }
      final header = await file.read(12);
      if (header.length != 12 ||
          ascii.decode(header.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
          ascii.decode(header.sublist(8, 12), allowInvalid: true) != 'WAVE') {
        throw const FormatException('Choose a standard RIFF/WAVE audio file.');
      }

      var sampleRate = 0;
      var blockAlign = 0;
      var dataBytes = -1;
      while (await file.position() + 8 <= length) {
        final chunkHeader = await file.read(8);
        if (chunkHeader.length != 8) break;
        final name = ascii.decode(chunkHeader.sublist(0, 4), allowInvalid: true);
        final size = ByteData.sublistView(Uint8List.fromList(chunkHeader)).getUint32(4, Endian.little);
        final contentStart = await file.position();
        if (size > length || contentStart + size > length) {
          throw const FormatException('WAV contains an invalid chunk length.');
        }
        if (name == 'fmt ') {
          if (size < 16 || size > 4096) throw const FormatException('WAV format chunk is invalid.');
          final format = await file.read(size);
          if (format.length != size) throw const FormatException('WAV ended inside its format header.');
          final view = ByteData.sublistView(Uint8List.fromList(format));
          final audioFormat = view.getUint16(0, Endian.little);
          final channels = view.getUint16(2, Endian.little);
          sampleRate = view.getUint32(4, Endian.little);
          blockAlign = view.getUint16(12, Endian.little);
          final bitsPerSample = view.getUint16(14, Endian.little);
          final supportedPcmDepth = audioFormat == 1 && const {8, 16, 24, 32}.contains(bitsPerSample);
          final supportedFloatDepth = audioFormat == 3 && const {32, 64}.contains(bitsPerSample);
          final bytesPerSample = (bitsPerSample + 7) ~/ 8;
          if ((!supportedPcmDepth && !supportedFloatDepth) ||
              channels < 1 ||
              blockAlign < channels * bytesPerSample) {
            throw const FormatException('Choose an uncompressed PCM or IEEE-float WAV file.');
          }
        } else if (name == 'data') {
          dataBytes = size;
        }
        final next = contentStart + size + (size.isOdd ? 1 : 0);
        if (await file.position() != next) await file.setPosition(next);
        if (sampleRate > 0 && dataBytes >= 0) break;
      }

      if (sampleRate < 8000 || sampleRate > 192000 || blockAlign <= 0 || dataBytes <= 0) {
        throw const FormatException('WAV sample rate or audio data is invalid.');
      }
      return ((dataBytes ~/ blockAlign) * 1000 / sampleRate).round();
    } finally {
      await file.close();
    }
  }
}
