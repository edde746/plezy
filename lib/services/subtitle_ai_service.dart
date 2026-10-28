import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../utils/app_logger.dart';
import 'subtitle_retimer.dart';
import 'subtitle_word_timing.dart';
import 'subtitle_whisper_cpp_service.dart';

enum SubtitleInferenceProvider { cpu, desktopGpu, coreMl, qnn, rknn }

extension SubtitleInferenceProviderName on SubtitleInferenceProvider {
  String get runtimeName => switch (this) {
    SubtitleInferenceProvider.cpu || SubtitleInferenceProvider.desktopGpu => 'cpu',
    SubtitleInferenceProvider.coreMl => 'coreml',
    SubtitleInferenceProvider.qnn => 'qnn',
    SubtitleInferenceProvider.rknn => 'rknn',
  };

  String get displayName => switch (this) {
    SubtitleInferenceProvider.cpu => 'CPU (multilingual Whisper)',
    SubtitleInferenceProvider.desktopGpu => 'Desktop GPU (compiled CUDA/Vulkan)',
    SubtitleInferenceProvider.coreMl => 'Core ML / Apple acceleration request',
    SubtitleInferenceProvider.qnn => 'QNN / Qualcomm NPU request',
    SubtitleInferenceProvider.rknn => 'RKNN / Rockchip NPU request',
  };
}

final class SubtitleTranscriptionResult {
  const SubtitleTranscriptionResult({
    required this.cues,
    required this.durationMs,
    required this.requestedProvider,
    required this.runtimeProvider,
    required this.fellBackToCpu,
    required this.detectedLanguage,
    required this.translatedToEnglish,
    this.wordTimings = const <SubtitleWordTiming>[],
  });

  final List<SubtitleCue> cues;
  final List<SubtitleWordTiming> wordTimings;
  final int durationMs;
  final SubtitleInferenceProvider requestedProvider;

  /// Provider string accepted while the native recognizer and VAD initialized.
  /// The packaged runtime does not report per-node execution placement.
  final String runtimeProvider;

  final bool fellBackToCpu;
  final String detectedLanguage;
  final bool translatedToEnglish;
}

final class SubtitleAiService {
  SubtitleAiService._();

  static final SubtitleAiService instance = SubtitleAiService._();

  static const String _modelId = 'sherpa-onnx-moonshine-tiny-en-quantized-2026-02-27';
  static const String _modelArchiveUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$_modelId.tar.bz2';
  static const int _modelArchiveBytes = 29858559;
  static const String _modelArchiveSha256 =
      '9ec31b342d8fa3240c3b81b8f82e1cf7e3ac467c93ca5a999b741d5887164f8d';
  static const String _vadUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.int8.onnx';
  static const int _vadBytes = 212860;
  static const String _vadSha256 = 'c36d490aff5ab924ca6c7aeec4d8f6bd3d22db6fa17611b9c5b17eae58ac3a20';
  static const int _maximumExpandedArchiveBytes = 256 * 1024 * 1024;
  static const int _maximumAudioHours = 8;
  static const int _maximumCueCount = 50000;
  static const int _sampleRate = 16000;
  static const bool _tizenBuild = bool.fromEnvironment('PLEZY_TIZEN');
  static const bool _webOsBuild = bool.fromEnvironment('PLEZY_WEBOS');
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');

  static bool get supportedPlatform =>
      !kIsWeb &&
      !_tizenBuild &&
      !_webOsBuild &&
      !_tvOsBuild &&
      (Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static List<SubtitleInferenceProvider> get availableProviderRequests {
    if (Platform.isAndroid) {
      return const [SubtitleInferenceProvider.cpu, SubtitleInferenceProvider.qnn, SubtitleInferenceProvider.rknn];
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return const [SubtitleInferenceProvider.cpu, SubtitleInferenceProvider.coreMl];
    }
    if (Platform.isWindows || Platform.isLinux) {
      return const [SubtitleInferenceProvider.cpu, SubtitleInferenceProvider.desktopGpu];
    }
    return const [SubtitleInferenceProvider.cpu];
  }

  Future<String> _modelDirectoryPath() async {
    final directory = await getApplicationSupportDirectory();
    return p.join(directory.path, 'subtitle_models', _modelId);
  }

  Future<bool> isModelInstalled() async {
    if (!supportedPlatform) return false;
    try {
      final root = Directory(await _modelDirectoryPath());
      final marker = File(p.join(root.path, 'model.json'));
      if (!await marker.exists()) return false;
      final manifest = jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
      if (manifest['model'] != _modelId || manifest['archiveSha256'] != _modelArchiveSha256) return false;
      for (final name in const ['encoder_model.ort', 'decoder_model_merged.ort', 'tokens.txt', 'silero_vad.int8.onnx']) {
        final file = File(p.join(root.path, name));
        if (!await file.exists() || await file.length() == 0) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadModel({
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    if (!supportedPlatform) throw UnsupportedError('Local speech generation is unavailable on this platform.');
    if (await isModelInstalled()) return;

    final targetPath = await _modelDirectoryPath();
    final target = Directory(targetPath);
    final staging = Directory('$targetPath.staging');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final archiveBytes = await _downloadVerified(
        _modelArchiveUrl,
        expectedBytes: _modelArchiveBytes,
        expectedSha256: _modelArchiveSha256,
        phase: 'English speech model',
        onProgress: onProgress,
      );
      await Isolate.run(() => _extractMoonshineArchive(archiveBytes, staging.path));

      final vadBytes = await _downloadVerified(
        _vadUrl,
        expectedBytes: _vadBytes,
        expectedSha256: _vadSha256,
        phase: 'Speech detector',
        onProgress: onProgress,
      );
      await File(p.join(staging.path, 'silero_vad.int8.onnx')).writeAsBytes(vadBytes, flush: true);
      await File(p.join(staging.path, 'model.json')).writeAsString(
        jsonEncode({
          'model': _modelId,
          'archiveSha256': _modelArchiveSha256,
          'vadSha256': _vadSha256,
          'language': 'en',
          'task': 'transcribe',
          'downloadedAt': DateTime.now().toUtc().toIso8601String(),
        }),
        flush: true,
      );

      if (await target.exists()) await target.delete(recursive: true);
      await staging.rename(targetPath);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<Uint8List> _downloadVerified(
    String url, {
    required int expectedBytes,
    required String expectedSha256,
    required String phase,
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] = 'PlezyNG subtitle model manager';
      final response = await client.send(request).timeout(const Duration(minutes: 10));
      if (response.statusCode != 200) {
        await response.stream.drain<void>();
        throw HttpException('Model server returned HTTP ${response.statusCode}.');
      }
      if (response.contentLength != null && response.contentLength != expectedBytes) {
        await response.stream.drain<void>();
        throw const FormatException('Model download has an unexpected declared size.');
      }

      final output = BytesBuilder(copy: false);
      var received = 0;
      await for (final chunk in response.stream.timeout(const Duration(seconds: 60))) {
        received += chunk.length;
        if (received > expectedBytes) {
          throw const FormatException('Model download exceeded its pinned size.');
        }
        output.add(chunk);
        onProgress?.call(phase, received, expectedBytes);
      }

      final bytes = output.takeBytes();
      if (bytes.lengthInBytes != expectedBytes || sha256.convert(bytes).toString() != expectedSha256) {
        throw const FormatException('Model checksum verification failed.');
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  Future<SubtitleTranscriptionResult> transcribeWav(
    String wavPath, {
    SubtitleInferenceProvider provider = SubtitleInferenceProvider.cpu,
    int numThreads = 2,
    bool translateToEnglish = false,
    String? languageCode,
    void Function(String phase, int received, int total)? onProgress,
  }) async {
    if (!supportedPlatform) throw UnsupportedError('Local speech generation is unavailable on this platform.');
    final requested = availableProviderRequests.contains(provider) ? provider : SubtitleInferenceProvider.cpu;
    final rawLanguage = languageCode?.trim().toLowerCase().split(RegExp(r'[-_]')).first;
    final languageOverride = rawLanguage == null || rawLanguage.isEmpty || rawLanguage == 'auto' ? null : rawLanguage;
    if (languageOverride != null && !RegExp(r'^[a-z]{2,3}$').hasMatch(languageOverride)) {
      throw ArgumentError.value(languageCode, 'languageCode', 'Use a two or three letter language code or auto.');
    }
    if (requested == SubtitleInferenceProvider.cpu || requested == SubtitleInferenceProvider.desktopGpu) {
      final whisperResult = await SubtitleWhisperCppService.instance.transcribeWav(
        wavPath,
        requestGpu: requested == SubtitleInferenceProvider.desktopGpu,
        translateToEnglish: translateToEnglish,
        languageCode: languageOverride,
        onProgress: onProgress,
      );
      return SubtitleTranscriptionResult(
        cues: whisperResult.cues,
        durationMs: whisperResult.durationMs,
        requestedProvider: requested,
        runtimeProvider: whisperResult.runtimeProvider,
        fellBackToCpu: whisperResult.fellBackToCpu,
        detectedLanguage: whisperResult.detectedLanguage,
        translatedToEnglish: whisperResult.translatedToEnglish,
        wordTimings: whisperResult.wordTimings,
      );
    }
    if (languageOverride != null && languageOverride != 'en') {
      throw UnsupportedError('The installed accelerator speech model is English-only; choose English or Auto-detect.');
    }
    if (translateToEnglish) {
      throw UnsupportedError('Speech translation uses the multilingual CPU/GPU Whisper model. Select CPU or desktop GPU.');
    }
    if (!await isModelInstalled()) {
      await downloadModel(onProgress: onProgress);
    }
    final root = await _modelDirectoryPath();
    final result = await Isolate.run(
      () => _runSubtitleTranscriptionWorker(
        wavPath: wavPath,
        modelDirectory: root,
        provider: requested.runtimeName,
        numThreads: numThreads.clamp(1, 8).toInt(),
      ),
    );
    final rawCues = result['cues'] as List<dynamic>;
    final cues = rawCues
        .map((value) {
          final cue = value as Map<dynamic, dynamic>;
          return SubtitleCue(
            index: cue['index'] as int,
            startMs: cue['startMs'] as int,
            endMs: cue['endMs'] as int,
            text: cue['text'] as String,
          );
        })
        .toList(growable: false);
    return SubtitleTranscriptionResult(
      cues: List.unmodifiable(cues),
      durationMs: result['durationMs'] as int,
      requestedProvider: requested,
      runtimeProvider: result['runtimeProvider'] as String,
      fellBackToCpu: result['fellBackToCpu'] as bool,
      detectedLanguage: 'en',
      translatedToEnglish: false,
    );
  }
}

void _extractMoonshineArchive(Uint8List compressed, String stagingPath) {
  final uncompressed = BZip2Decoder().decodeBytes(
    compressed,
    verify: true,
    maxOutputSize: SubtitleAiService._maximumExpandedArchiveBytes,
  );
  final archive = TarDecoder().decodeBytes(uncompressed, verify: true);
  final files = <String, ArchiveFile>{};
  for (final entry in archive.files) {
    if (entry.isSymbolicLink) throw const FormatException('Model package contains a symbolic link.');
    if (entry.isDirectory) continue;
    final name = entry.name.replaceAll('\\', '/').split('/').last;
    if (const {'encoder_model.ort', 'decoder_model_merged.ort', 'tokens.txt'}.contains(name)) {
      if (files.containsKey(name)) throw const FormatException('Model package contains duplicate required files.');
      files[name] = entry;
    }
  }

  for (final name in const ['encoder_model.ort', 'decoder_model_merged.ort', 'tokens.txt']) {
    final entry = files[name];
    if (entry == null || entry.size <= 0 || entry.size > 160 * 1024 * 1024) {
      throw const FormatException('Model package is missing a bounded required file.');
    }
    final content = entry.content;
    final bytes = content is Uint8List ? content : Uint8List.fromList(content as List<int>);
    if (bytes.lengthInBytes != entry.size) throw const FormatException('Model member size does not match its header.');
    File(p.join(stagingPath, name)).writeAsBytesSync(bytes, flush: true);
  }
}

Future<Map<String, Object?>> _runSubtitleTranscriptionWorker({
  required String wavPath,
  required String modelDirectory,
  required String provider,
  required int numThreads,
}) async {
  await sherpa.initBindingsAsync();

  Future<(sherpa.OfflineRecognizer, sherpa.VoiceActivityDetector)> createEngine(String requestedProvider) async {
    final model = sherpa.OfflineModelConfig(
      moonshine: sherpa.OfflineMoonshineModelConfig(
        encoder: p.join(modelDirectory, 'encoder_model.ort'),
        mergedDecoder: p.join(modelDirectory, 'decoder_model_merged.ort'),
      ),
      tokens: p.join(modelDirectory, 'tokens.txt'),
      numThreads: numThreads,
      debug: false,
      provider: requestedProvider,
    );
    final recognizer = sherpa.OfflineRecognizer(sherpa.OfflineRecognizerConfig(model: model));
    try {
      final vad = sherpa.VoiceActivityDetector(
        config: sherpa.VadModelConfig(
          sileroVad: sherpa.SileroVadModelConfig(
            model: p.join(modelDirectory, 'silero_vad.int8.onnx'),
            threshold: 0.5,
            minSilenceDuration: 0.4,
            minSpeechDuration: 0.25,
            windowSize: 512,
            maxSpeechDuration: 10,
          ),
          sampleRate: SubtitleAiService._sampleRate,
          numThreads: numThreads,
          provider: requestedProvider,
          debug: false,
        ),
        bufferSizeInSeconds: 30,
      );
      return (recognizer, vad);
    } catch (_) {
      recognizer.free();
      rethrow;
    }
  }

  Future<Map<String, Object?>> run(String requestedProvider, {required bool fellBackToCpu}) async {
    final wav = await _PcmWavReader.open(wavPath);
    sherpa.OfflineRecognizer? recognizer;
    sherpa.VoiceActivityDetector? vad;
    try {
      final engine = await createEngine(requestedProvider);
      recognizer = engine.$1;
      vad = engine.$2;
      final output = <Map<String, Object?>>[];

      Future<void> drainVad() async {
        while (!vad!.isEmpty()) {
          final segment = vad.front();
          final startMs = (segment.start * 1000 / SubtitleAiService._sampleRate).round();
          final endMs = ((segment.start + segment.samples.length) * 1000 / SubtitleAiService._sampleRate).round();
          if (segment.samples.isEmpty || endMs <= startMs) {
            vad.pop();
            continue;
          }

          final stream = recognizer!.createStream();
          try {
            stream.acceptWaveform(samples: segment.samples, sampleRate: SubtitleAiService._sampleRate);
            recognizer.decode(stream);
            final text = recognizer.getResult(stream).text.replaceAll(RegExp(r'\s+'), ' ').trim();
            if (text.isNotEmpty && text.runes.length <= 600 && output.length < SubtitleAiService._maximumCueCount) {
              final previous = output.isEmpty ? null : output.last;
              if (previous == null ||
                  previous['text'] != text ||
                  startMs - (previous['endMs'] as int) > 1200) {
                output.add({
                  'index': output.length + 1,
                  'startMs': startMs,
                  'endMs': endMs,
                  'text': text,
                });
              }
            }
          } finally {
            stream.free();
            vad.pop();
          }
        }
      }

      await wav.forEachMono16kChunk((samples) async {
        vad!.acceptWaveform(samples);
        await drainVad();
      });
      vad.flush();
      await drainVad();
      final durationMs = wav.durationMs;
      if (output.isEmpty) throw const FormatException('No speech was detected in this WAV file.');
      return {
        'cues': output,
        'durationMs': durationMs,
        'runtimeProvider': requestedProvider,
        'fellBackToCpu': fellBackToCpu,
        'detectedLanguage': 'en',
      };
    } finally {
      vad?.free();
      recognizer?.free();
      await wav.close();
    }
  }

  try {
    return await run(provider, fellBackToCpu: false);
  } catch (error) {
    if (provider == 'cpu') rethrow;
    appLogger.i('Subtitle inference provider $provider failed; retrying the full file with CPU: $error');
    return run('cpu', fellBackToCpu: true);
  }
}

final class _PcmWavReader {
  _PcmWavReader._({
    required this.file,
    required this.dataOffset,
    required this.dataBytes,
    required this.sampleRate,
    required this.channels,
    required this.blockAlign,
  });

  final RandomAccessFile file;
  final int dataOffset;
  final int dataBytes;
  final int sampleRate;
  final int channels;
  final int blockAlign;

  int get sourceFrames => dataBytes ~/ blockAlign;
  int get outputFrames => (sourceFrames * SubtitleAiService._sampleRate) ~/ sampleRate;
  int get durationMs => (sourceFrames * 1000) ~/ sampleRate;

  static Future<_PcmWavReader> open(String path) async {
    final file = await File(path).open(mode: FileMode.read);
    try {
      final fileLength = await file.length();
      final header = await _readExact(file, 12);
      if (ascii.decode(header.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
          ascii.decode(header.sublist(8, 12), allowInvalid: true) != 'WAVE') {
        throw const FormatException('Choose a standard RIFF/WAVE audio file.');
      }

      var sampleRate = 0;
      var channels = 0;
      var blockAlign = 0;
      var bitsPerSample = 0;
      var format = 0;
      var dataOffset = -1;
      var dataBytes = -1;

      while (await file.position() + 8 <= fileLength) {
        final chunkHeader = await _readExact(file, 8);
        final chunkName = ascii.decode(chunkHeader.sublist(0, 4), allowInvalid: true);
        final chunkSize = ByteData.sublistView(chunkHeader).getUint32(4, Endian.little);
        final contentStart = await file.position();
        if (chunkSize > fileLength || contentStart + chunkSize > fileLength) {
          throw const FormatException('WAV contains an invalid chunk length.');
        }

        if (chunkName == 'fmt ') {
          if (chunkSize < 16 || chunkSize > 4096) throw const FormatException('WAV format chunk is invalid.');
          final fmt = await _readExact(file, chunkSize);
          final data = ByteData.sublistView(fmt);
          format = data.getUint16(0, Endian.little);
          channels = data.getUint16(2, Endian.little);
          sampleRate = data.getUint32(4, Endian.little);
          blockAlign = data.getUint16(12, Endian.little);
          bitsPerSample = data.getUint16(14, Endian.little);
        } else if (chunkName == 'data') {
          dataOffset = contentStart;
          dataBytes = chunkSize;
        }

        final next = contentStart + chunkSize + (chunkSize.isOdd ? 1 : 0);
        if (await file.position() != next) await file.setPosition(next);
        if (sampleRate != 0 && dataOffset >= 0) break;
      }

      if (format != 1 || bitsPerSample != 16 || (channels != 1 && channels != 2)) {
        throw const FormatException('Use uncompressed 16-bit PCM WAV audio with one or two channels.');
      }
      if (sampleRate < 8000 || sampleRate > 96000 || blockAlign != channels * 2 || dataBytes <= 0) {
        throw const FormatException('WAV sample rate or audio data is invalid.');
      }

      final reader = _PcmWavReader._(
        file: file,
        dataOffset: dataOffset,
        dataBytes: dataBytes - (dataBytes % blockAlign),
        sampleRate: sampleRate,
        channels: channels,
        blockAlign: blockAlign,
      );
      final totalMs = reader.durationMs;
      if (totalMs <= 0 || totalMs > SubtitleAiService._maximumAudioHours * 60 * 60 * 1000) {
        throw const FormatException('WAV duration must be between one millisecond and eight hours.');
      }
      return reader;
    } catch (_) {
      await file.close();
      rethrow;
    }
  }

  Future<void> forEachMono16kChunk(Future<void> Function(Float32List samples) callback) async {
    const outputChunkFrames = 16000;
    for (var outputStart = 0; outputStart < outputFrames; outputStart += outputChunkFrames) {
      final count = (outputFrames - outputStart).clamp(0, outputChunkFrames).toInt();
      if (count == 0) break;
      final sourceStart = (outputStart * sampleRate) ~/ SubtitleAiService._sampleRate;
      final lastPosition = ((outputStart + count - 1) * sampleRate) / SubtitleAiService._sampleRate;
      final sourceEnd = (lastPosition.floor() + 2).clamp(sourceStart + 1, sourceFrames).toInt();
      final frameCount = sourceEnd - sourceStart;

      await file.setPosition(dataOffset + sourceStart * blockAlign);
      final bytes = await _readExact(file, frameCount * blockAlign);
      final view = ByteData.sublistView(bytes);
      double monoAt(int frame) {
        var total = 0.0;
        for (var channel = 0; channel < channels; channel++) {
          total += view.getInt16(frame * blockAlign + channel * 2, Endian.little) / 32768.0;
        }
        return total / channels;
      }

      final output = Float32List(count);
      for (var index = 0; index < count; index++) {
        final sourcePosition =
            ((outputStart + index) * sampleRate / SubtitleAiService._sampleRate) - sourceStart;
        final lower = sourcePosition.floor().clamp(0, frameCount - 1).toInt();
        final upper = (lower + 1).clamp(0, frameCount - 1).toInt();
        final fraction = (sourcePosition - lower).clamp(0.0, 1.0);
        final first = monoAt(lower);
        final second = monoAt(upper);
        output[index] = (first + (second - first) * fraction).clamp(-1.0, 1.0);
      }
      await callback(output);
    }
  }

  Future<void> close() => file.close();
}

Future<Uint8List> _readExact(RandomAccessFile file, int count) async {
  final bytes = BytesBuilder(copy: false);
  var read = 0;
  while (read < count) {
    final chunk = await file.read(count - read);
    if (chunk.isEmpty) throw const FormatException('WAV ended unexpectedly.');
    bytes.add(chunk);
    read += chunk.length;
  }
  return bytes.takeBytes();
}
