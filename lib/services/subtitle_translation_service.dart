import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../utils/platform_detector.dart';
import 'subtitle_retimer.dart';

/// Subtitle text translated on-device, using ML Kit on mobile or an optional
/// locally installed Argos Translate runtime on desktop.
final class SubtitleTranslationResult {
  const SubtitleTranslationResult({
    required this.cues,
    required this.backendLabel,
    required this.fellBackToCpu,
  });

  final List<SubtitleCue> cues;
  final String backendLabel;
  final bool fellBackToCpu;
}

abstract final class SubtitleTranslationService {
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');

  static bool get mobilePlatformSupported =>
      !kIsWeb && !_tvOsBuild && (Platform.isAndroid || Platform.isIOS);

  static bool get desktopPlatformSupported =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static bool get platformSupported => mobilePlatformSupported || desktopPlatformSupported;

  static String get _pythonExecutable {
    final configured = Platform.environment['PLEZY_ARGOS_PYTHON']?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    return Platform.isWindows ? 'python' : 'python3';
  }

  static const String _argosBatchScript = r'''
import json
import sys
from argostranslate import translate as argos_translate

from_code = sys.argv[1]
to_code = sys.argv[2]
source_texts = json.load(sys.stdin)
translated = [argos_translate.translate(text, from_code, to_code) for text in source_texts]
json.dump(translated, sys.stdout, ensure_ascii=False)
''';

  static List<TranslateLanguage> get languages => TranslateLanguage.values;

  static TranslateLanguage? languageForCode(String code) {
    final normalized = code.trim().toLowerCase().split('-').first;
    for (final language in TranslateLanguage.values) {
      if (language.bcpCode.toLowerCase() == normalized) return language;
    }
    return null;
  }

  static String languageLabel(TranslateLanguage language) {
    final name = language.name.replaceAll('_', ' ');
    return name.split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  static Future<bool> isSupportedOnCurrentDevice() async {
    if (desktopPlatformSupported) return _isArgosRuntimeAvailable();
    if (!mobilePlatformSupported) return false;
    if (Platform.isAndroid) {
      final detector = await TvDetectionService.getInstance();
      if (detector.isTVDevice || detector.isAutomotive || detector.isAppleTV) return false;
    }
    // ML Kit's translation path is limited here to phones/tablets; Android TV,
    // automotive and tvOS are gated off.
    return true;
  }

  static Future<SubtitleTranslationResult> translateCues({
    required List<SubtitleCue> cues,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    bool allowMobileData = false,
    bool requestDesktopCuda = false,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (!await isSupportedOnCurrentDevice()) {
      throw UnsupportedError(
        desktopPlatformSupported
            ? 'Install Argos Translate and the selected language pair to translate locally on desktop.'
            : 'On-device translation is available on supported phones and tablets only.',
      );
    }
    if (sourceLanguage == targetLanguage) {
      throw ArgumentError('Choose different source and target languages.');
    }
    if (cues.isEmpty || cues.length > SubtitleRetimer.maximumCueCount) {
      throw const FormatException('Subtitle has no cues or exceeds the 50000 cue processing bound.');
    }
    final textBytes = cues.fold<int>(0, (total, cue) => total + utf8.encode(cue.text).length);
    if (textBytes > SubtitleRetimer.maximumInputBytes || cues.any((cue) => cue.text.length > 4000)) {
      throw const FormatException('Subtitle text exceeds the 5 MiB translation bound.');
    }

    if (desktopPlatformSupported) {
      return _translateWithArgos(
        cues: cues,
        sourceCode: sourceLanguage.bcpCode.toLowerCase().split('-').first,
        targetCode: targetLanguage.bcpCode.toLowerCase().split('-').first,
        requestCuda: requestDesktopCuda,
        onProgress: onProgress,
      );
    }

    final manager = OnDeviceTranslatorModelManager();
    for (final language in {sourceLanguage, targetLanguage}) {
      final code = language.bcpCode;
      if (!await manager.isModelDownloaded(code)) {
        await manager.downloadModel(code, isWifiRequired: !allowMobileData);
      }
    }

    final translator = OnDeviceTranslator(sourceLanguage: sourceLanguage, targetLanguage: targetLanguage);
    final translated = <SubtitleCue>[];
    var translatedBytes = 0;
    try {
      for (var index = 0; index < cues.length; index++) {
        final source = cues[index];
        final text = await _translateMarkupAware(translator, source.text);
        if (text.trim().isEmpty) {
          throw FormatException('Translation returned empty text for cue ${source.index}.');
        }
        if (text.length > 4000) {
          throw FormatException('Translation expanded cue ${source.index} beyond the 4000-character limit.');
        }
        translatedBytes += utf8.encode(text).length;
        if (translatedBytes > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Translated subtitles exceed the 5 MiB output bound.');
        }
        translated.add(SubtitleCue(
          index: index + 1,
          startMs: source.startMs,
          endMs: source.endMs,
          text: text,
        ));
        if ((index + 1) % 5 == 0 || index + 1 == cues.length) onProgress?.call(index + 1, cues.length);
      }
    } finally {
      await translator.close();
    }
    return SubtitleTranslationResult(
      cues: List.unmodifiable(translated),
      backendLabel: 'ML Kit on-device; CPU/GPU placement is not reported',
      fellBackToCpu: false,
    );
  }

  static Future<bool> _isArgosRuntimeAvailable() async {
    try {
      final result = await Process.run(
        _pythonExecutable,
        const ['-c', 'import argostranslate.translate'],
        runInShell: false,
      ).timeout(const Duration(seconds: 8));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<SubtitleTranslationResult> _translateWithArgos({
    required List<SubtitleCue> cues,
    required String sourceCode,
    required String targetCode,
    required bool requestCuda,
    void Function(int completed, int total)? onProgress,
  }) async {
    final pieces = <List<(bool, String)>>[];
    final textToTranslate = <String>[];
    final markup = RegExp(r'<[^>]{0,160}>|\{[^}]{0,160}\}|\\[Nnh]');
    for (final cue in cues) {
      final matches = markup.allMatches(cue.text).toList(growable: false);
      final row = <(bool, String)>[];
      var cursor = 0;
      for (final match in matches) {
        if (match.start > cursor) {
          final text = cue.text.substring(cursor, match.start);
          if (text.trim().isEmpty) {
            row.add((false, text));
          } else {
            final index = textToTranslate.length;
            textToTranslate.add(text);
            row.add((true, '$index'));
          }
        }
        row.add((false, match.group(0)!));
        cursor = match.end;
      }
      if (cursor < cue.text.length) {
        final text = cue.text.substring(cursor);
        if (text.trim().isEmpty) {
          row.add((false, text));
        } else {
          final index = textToTranslate.length;
          textToTranslate.add(text);
          row.add((true, '$index'));
        }
      }
      if (row.isEmpty) {
        final index = textToTranslate.length;
        textToTranslate.add(cue.text);
        row.add((true, '$index'));
      }
      pieces.add(row);
    }

    List<String> translatedText;
    var fellBack = false;
    var backendLabel = 'Argos Translate CPU (local)';
    if (requestCuda) {
      try {
        translatedText = await _runArgosBatch(textToTranslate, sourceCode, targetCode, device: 'cuda');
        backendLabel = 'Argos Translate CUDA requested; per-operation placement is not reported';
      } catch (_) {
        translatedText = await _runArgosBatch(textToTranslate, sourceCode, targetCode, device: 'cpu');
        backendLabel = 'Argos Translate CPU (CUDA request failed and retried on CPU)';
        fellBack = true;
      }
    } else {
      translatedText = await _runArgosBatch(textToTranslate, sourceCode, targetCode, device: 'cpu');
    }

    if (translatedText.length != textToTranslate.length) {
      throw const FormatException('Local translation returned an unexpected number of text segments.');
    }
    final translated = <SubtitleCue>[];
    var translatedBytes = 0;
    for (var cueIndex = 0; cueIndex < cues.length; cueIndex++) {
      final source = cues[cueIndex];
      final output = StringBuffer();
      for (final piece in pieces[cueIndex]) {
        output.write(piece.$1 ? translatedText[int.parse(piece.$2)] : piece.$2);
      }
      final text = output.toString();
      if (text.trim().isEmpty || text.length > 4000) {
        throw FormatException('Local translation returned invalid text for cue ${source.index}.');
      }
      translatedBytes += utf8.encode(text).length;
      if (translatedBytes > SubtitleRetimer.maximumInputBytes) {
        throw const FormatException('Translated subtitles exceed the 5 MiB output bound.');
      }
      translated.add(SubtitleCue(index: cueIndex + 1, startMs: source.startMs, endMs: source.endMs, text: text));
    }
    onProgress?.call(cues.length, cues.length);
    return SubtitleTranslationResult(
      cues: List.unmodifiable(translated),
      backendLabel: backendLabel,
      fellBackToCpu: fellBack,
    );
  }

  static Future<List<String>> _runArgosBatch(
    List<String> text,
    String sourceCode,
    String targetCode, {
    required String device,
  }) async {
    final process = await Process.start(
      _pythonExecutable,
      ['-c', _argosBatchScript, sourceCode, targetCode],
      runInShell: false,
      environment: <String, String>{...Platform.environment, 'ARGOS_DEVICE_TYPE': device},
    );
    final stdoutFuture = utf8.decoder.bind(process.stdout).join();
    final stderrFuture = utf8.decoder.bind(process.stderr).join();
    var processFinished = false;
    try {
      process.stdin.add(utf8.encode(jsonEncode(text)));
      await process.stdin.close();
      final exitCode = await process.exitCode.timeout(const Duration(minutes: 30), onTimeout: () {
        process.kill();
        throw TimeoutException('Local subtitle translation exceeded 30 minutes.');
      });
      processFinished = true;
      final output = await stdoutFuture;
      final error = await stderrFuture;
      if (exitCode != 0) {
        final lines = error.trim().split('\n').where((line) => line.trim().isNotEmpty).toList();
        final lastLine = lines.isEmpty ? null : lines.last;
        throw StateError(lastLine == null ? 'Argos Translate exited with code $exitCode.' : 'Argos Translate: $lastLine');
      }
      if (output.length > 12 * 1024 * 1024) {
        throw const FormatException('Local translation output exceeds the 12 MiB processing bound.');
      }
      final value = jsonDecode(output);
      if (value is! List || value.any((item) => item is! String)) {
        throw const FormatException('Local translation returned malformed data.');
      }
      return value.cast<String>();
    } finally {
      if (!processFinished) process.kill();
    }
  }

  static Future<String> _translateMarkupAware(OnDeviceTranslator translator, String source) async {
    final markup = RegExp(r'<[^>]{0,160}>|\{[^}]{0,160}\}|\\[Nnh]');
    final matches = markup.allMatches(source).toList(growable: false);
    if (matches.isEmpty) return translator.translateText(source);

    final output = StringBuffer();
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        final part = source.substring(cursor, match.start);
        output.write(part.trim().isEmpty ? part : await translator.translateText(part));
      }
      output.write(match.group(0));
      cursor = match.end;
    }
    if (cursor < source.length) {
      final part = source.substring(cursor);
      output.write(part.trim().isEmpty ? part : await translator.translateText(part));
    }
    return output.toString();
  }
}
