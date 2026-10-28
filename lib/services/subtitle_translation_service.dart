import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../utils/platform_detector.dart';
import 'subtitle_retimer.dart';
import 'settings_service.dart';

/// Subtitle text translated on-device, using ML Kit on mobile or an optional
/// locally installed Argos Translate runtime on desktop.
final class SubtitleTranslationResult {
  const SubtitleTranslationResult({
    required this.cues,
    required this.backendLabel,
    required this.fellBackToCpu,
    required this.qualityWarnings,
  });

  final List<SubtitleCue> cues;
  final String backendLabel;
  final bool fellBackToCpu;
  final List<String> qualityWarnings;
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

  static String _glossaryPairKey(TranslateLanguage source, TranslateLanguage target) =>
      '${_normalizedLanguageCode(source)}>${_normalizedLanguageCode(target)}';

  static String _normalizedLanguageCode(TranslateLanguage language) =>
      language.bcpCode.toLowerCase().split('-').first;

  /// Read this profile's local terminology for the selected language pair.
  static String _seriesGlossaryEntryKey(
    String seriesId,
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) {
    final normalizedSeriesId = seriesId.trim();
    if (normalizedSeriesId.isEmpty || utf8.encode(normalizedSeriesId).length > 512) {
      throw ArgumentError.value(seriesId, 'seriesId', 'Use a non-empty series identifier up to 512 bytes.');
    }
    final encodedSeriesId = base64Url.encode(utf8.encode(normalizedSeriesId));
    return '$encodedSeriesId|${_glossaryPairKey(sourceLanguage, targetLanguage)}';
  }

  /// Read the series override when present, otherwise inherit the profile glossary for the pair.
  static Map<String, String> loadGlossaryForProfile({
    required String profileId,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    String? seriesId,
  }) {
    if (seriesId != null && seriesId.trim().isNotEmpty) {
      try {
        final seriesEntries = SettingsService.instance.read(
          SettingsService.subtitleTranslationSeriesGlossariesForProfile(profileId),
        );
        final encoded = seriesEntries[_seriesGlossaryEntryKey(seriesId, sourceLanguage, targetLanguage)];
        if (encoded != null) {
          final decoded = jsonDecode(encoded);
          if (decoded is Map) {
            final glossary = <String, String>{};
            for (final entry in decoded.entries) {
              if (entry.key is String && entry.value is String) {
                glossary[entry.key as String] = entry.value as String;
              }
            }
            return _validateGlossary(glossary);
          }
        }
      } catch (_) {
        // A malformed override falls back to the safe profile glossary.
      }
    }
    final saved = SettingsService.instance.read(
      SettingsService.subtitleTranslationGlossariesForProfile(profileId),
    );
    return Map.unmodifiable(saved[_glossaryPairKey(sourceLanguage, targetLanguage)] ?? const {});
  }

  /// Save the validated profile glossary or an independent per-series override.
  static Future<void> saveGlossaryForProfile({
    required String profileId,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    required Map<String, String> glossary,
    String? seriesId,
  }) async {
    final normalized = _validateGlossary(glossary);
    if (seriesId == null || seriesId.trim().isEmpty) {
      final pref = SettingsService.subtitleTranslationGlossariesForProfile(profileId);
      final pairs = Map<String, Map<String, String>>.from(SettingsService.instance.read(pref));
      final key = _glossaryPairKey(sourceLanguage, targetLanguage);
      pairs.remove(key);
      if (normalized.isNotEmpty) pairs[key] = normalized;
      while (pairs.length > 16) {
        pairs.remove(pairs.keys.first);
      }
      await SettingsService.instance.write(pref, Map.unmodifiable(pairs));
      return;
    }

    final entryKey = _seriesGlossaryEntryKey(seriesId, sourceLanguage, targetLanguage);
    final pref = SettingsService.subtitleTranslationSeriesGlossariesForProfile(profileId);
    final entries = Map<String, String>.from(SettingsService.instance.read(pref));
    entries.remove(entryKey);
    if (normalized.isNotEmpty) entries[entryKey] = jsonEncode(normalized);
    final seriesPrefix = entryKey.substring(0, entryKey.lastIndexOf('|') + 1);
    var pairKeys = entries.keys.where((key) => key.startsWith(seriesPrefix)).toList(growable: false);
    while (pairKeys.length > 16) {
      entries.remove(pairKeys.first);
      pairKeys = entries.keys.where((key) => key.startsWith(seriesPrefix)).toList(growable: false);
    }

    final seriesOrder = <String>[];
    for (final key in entries.keys) {
      final separator = key.lastIndexOf('|');
      if (separator < 0) continue;
      final prefix = key.substring(0, separator + 1);
      if (!seriesOrder.contains(prefix)) seriesOrder.add(prefix);
    }
    while (seriesOrder.length > 32) {
      final oldestSeries = seriesOrder.removeAt(0);
      entries.removeWhere((key, _) => key.startsWith(oldestSeries));
    }
    int serializedBytes() => utf8.encode(jsonEncode(entries)).length;
    while (serializedBytes() > 1024 * 1024) {
      final oldest = entries.keys.firstWhere((key) => key != entryKey, orElse: () => '');
      if (oldest.isEmpty) {
        throw const FormatException('Series glossary storage exceeds the 1 MiB profile bound.');
      }
      entries.remove(oldest);
    }
    await SettingsService.instance.write(pref, Map.unmodifiable(entries));
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
    bool bilingual = false,
    Map<String, String> glossary = const {},
    void Function(int completed, int total)? onProgress,
  }) async {
    if (!await isSupportedOnCurrentDevice()) {
      throw UnsupportedError(
        desktopPlatformSupported
            ? 'Install Argos Translate and the selected language pair to translate locally on desktop.'
            : 'On-device translation is available on supported phones and tablets only.',
      );
    }
    final normalizedGlossary = _validateGlossary(glossary);
    final glossaryChecks = _buildGlossaryChecks(normalizedGlossary);
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
        bilingual: bilingual,
        glossary: normalizedGlossary,
        glossaryChecks: glossaryChecks,
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
    var protectedInputBytes = 0;
    final qualityWarnings = <String>[];
    try {
      for (var index = 0; index < cues.length; index++) {
        final source = cues[index];
        final protected = _protectGlossaryMarkupAware(source.text, normalizedGlossary, source.index);
        protectedInputBytes += utf8.encode(protected.text).length;
        if (protectedInputBytes > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Glossary placeholders expand subtitle input beyond the 5 MiB translation bound.');
        }
        final machineText = await _translateMarkupAware(translator, protected.text);
        final translatedText = _restoreGlossary(machineText, protected.markers);
        _collectGlossaryWarnings(source, translatedText, glossaryChecks, qualityWarnings);
        if (translatedText.trim().isEmpty) {
          throw FormatException('Translation returned empty text for cue ${source.index}.');
        }
        final outputText = _composeBilingual(source.text, translatedText, bilingual);
        if (outputText.length > 4000) {
          throw FormatException('Translation expanded cue ${source.index} beyond the 4000-character limit.');
        }
        translatedBytes += utf8.encode(outputText).length;
        if (translatedBytes > SubtitleRetimer.maximumInputBytes) {
          throw const FormatException('Translated subtitles exceed the 5 MiB output bound.');
        }
        translated.add(SubtitleCue(
          index: index + 1,
          startMs: source.startMs,
          endMs: source.endMs,
          text: outputText,
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
      qualityWarnings: List.unmodifiable(qualityWarnings),
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
    required bool bilingual,
    required Map<String, String> glossary,
    required List<_GlossaryTermCheck> glossaryChecks,
    void Function(int completed, int total)? onProgress,
  }) async {
    final pieces = <List<(bool, String)>>[];
    final protectedCues = <_ProtectedGlossary>[];
    final textToTranslate = <String>[];
    var protectedInputBytes = 0;
    final markup = RegExp(r'<[^>]{0,160}>|\{[^}]{0,160}\}|\\[Nnh]');
    for (final cue in cues) {
      final protected = _protectGlossaryMarkupAware(cue.text, glossary, cue.index);
      protectedInputBytes += utf8.encode(protected.text).length;
      if (protectedInputBytes > SubtitleRetimer.maximumInputBytes) {
        throw const FormatException('Glossary placeholders expand subtitle input beyond the 5 MiB translation bound.');
      }
      protectedCues.add(protected);
      final matches = markup.allMatches(protected.text).toList(growable: false);
      final row = <(bool, String)>[];
      var cursor = 0;
      for (final match in matches) {
        if (match.start > cursor) {
          final text = protected.text.substring(cursor, match.start);
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
      if (cursor < protected.text.length) {
        final text = protected.text.substring(cursor);
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
        textToTranslate.add(protected.text);
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
    final qualityWarnings = <String>[];
    var translatedBytes = 0;
    for (var cueIndex = 0; cueIndex < cues.length; cueIndex++) {
      final source = cues[cueIndex];
      final output = StringBuffer();
      for (final piece in pieces[cueIndex]) {
        output.write(piece.$1 ? translatedText[int.parse(piece.$2)] : piece.$2);
      }
      final restoredText = _restoreGlossary(output.toString(), protectedCues[cueIndex].markers);
      _collectGlossaryWarnings(source, restoredText, glossaryChecks, qualityWarnings);
      if (restoredText.trim().isEmpty) {
        throw FormatException('Local translation returned invalid text for cue ${source.index}.');
      }
      final outputText = _composeBilingual(source.text, restoredText, bilingual);
      if (outputText.length > 4000) {
        throw FormatException('Local translation expanded cue ${source.index} beyond the 4000-character limit.');
      }
      translatedBytes += utf8.encode(outputText).length;
      if (translatedBytes > SubtitleRetimer.maximumInputBytes) {
        throw const FormatException('Translated subtitles exceed the 5 MiB output bound.');
      }
      translated.add(SubtitleCue(index: cueIndex + 1, startMs: source.startMs, endMs: source.endMs, text: outputText));
    }
    onProgress?.call(cues.length, cues.length);
    return SubtitleTranslationResult(
      cues: List.unmodifiable(translated),
      backendLabel: backendLabel,
      fellBackToCpu: fellBack,
      qualityWarnings: List.unmodifiable(qualityWarnings),
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

  static List<_GlossaryTermCheck> _buildGlossaryChecks(Map<String, String> glossary) =>
      List.unmodifiable(glossary.entries.map((entry) {
        RegExp pattern(String value) => RegExp(
              r'(?<![\p{L}\p{N}\p{M}\p{Pc}])' +
                  RegExp.escape(value) +
                  r'(?![\p{L}\p{N}\p{M}\p{Pc}])',
              caseSensitive: false,
              unicode: true,
            );
        return _GlossaryTermCheck(entry.key, entry.value, pattern(entry.key), pattern(entry.value));
      }));

  static void _collectGlossaryWarnings(
    SubtitleCue source,
    String translatedText,
    List<_GlossaryTermCheck> checks,
    List<String> warnings,
  ) {
    for (final check in checks) {
      if (warnings.length >= 100) return;
      if (check.sourcePattern.hasMatch(source.text) && !check.targetPattern.hasMatch(translatedText)) {
        warnings.add(
          'Cue ' + source.index.toString() + ': “' + check.source + '” may be missing its glossary translation “' + check.target + '”.',
        );
      }
    }
  }

  static Map<String, String> _validateGlossary(Map<String, String> glossary) {
    if (glossary.length > 200) {
      throw const FormatException('A translation glossary may contain at most 200 terms.');
    }
    final output = <String, String>{};
    final normalizedTerms = <String>{};
    for (final entry in glossary.entries) {
      final source = entry.key.trim();
      final target = entry.value.trim();
      if (source.isEmpty ||
          target.isEmpty ||
          source.runes.length > 128 ||
          target.runes.length > 128 ||
          source.contains('\n') ||
          source.contains('\r') ||
          target.contains('\n') ||
          target.contains('\r') ||
          source.contains('<') ||
          source.contains('>') ||
          target.contains('<') ||
          target.contains('>')) {
        throw const FormatException('Glossary terms and translations must be single-line plain text of at most 128 characters.');
      }
      if (!normalizedTerms.add(source.toLowerCase())) {
        throw const FormatException('Glossary source terms must be unique without regard to case.');
      }
      output[source] = target;
    }
    return Map.unmodifiable(output);
  }

  static _ProtectedGlossary _protectGlossaryMarkupAware(
    String source,
    Map<String, String> glossary,
    int cueIndex,
  ) {
    if (glossary.isEmpty) return _ProtectedGlossary(source, const {});
    final entries = glossary.entries.toList()
      ..sort((left, right) => right.key.runes.length.compareTo(left.key.runes.length));
    var markerPrefix = '<QXPLEZYTERM${cueIndex}X';
    while (source.contains(markerPrefix)) {
      markerPrefix += 'X';
    }
    final markers = <String, String>{};
    final markup = RegExp(r'<[^>]{0,160}>|\{[^}]{0,160}\}|\\[Nnh]');

    String protectPlainText(String text) {
      var protectedText = text;
      for (final entry in entries) {
        final pattern = RegExp(
          r'(?<![\p{L}\p{N}\p{M}\p{Pc}])' + RegExp.escape(entry.key) + r'(?![\p{L}\p{N}\p{M}\p{Pc}])',
          caseSensitive: false,
          unicode: true,
        );
        protectedText = protectedText.replaceAllMapped(pattern, (_) {
          final marker = '$markerPrefix${markers.length}QX>';
          markers[marker] = entry.value;
          return marker;
        });
      }
      return protectedText;
    }

    final output = StringBuffer();
    var cursor = 0;
    for (final match in markup.allMatches(source)) {
      if (match.start > cursor) output.write(protectPlainText(source.substring(cursor, match.start)));
      output.write(match.group(0));
      cursor = match.end;
    }
    if (cursor < source.length) output.write(protectPlainText(source.substring(cursor)));
    return _ProtectedGlossary(output.toString(), Map.unmodifiable(markers));
  }

  static String _restoreGlossary(String text, Map<String, String> markers) {
    for (final marker in markers.entries) {
      if (marker.key.allMatches(text).length != 1) {
        throw const FormatException('Translation changed a protected glossary term; the source subtitle was left intact.');
      }
      text = text.replaceFirst(marker.key, marker.value);
    }
    return text;
  }

  static String _composeBilingual(String source, String translation, bool bilingual) =>
      bilingual ? '$source\n$translation' : translation;

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


final class _GlossaryTermCheck {
  const _GlossaryTermCheck(this.source, this.target, this.sourcePattern, this.targetPattern);

  final String source;
  final String target;
  final RegExp sourcePattern;
  final RegExp targetPattern;
}

final class _ProtectedGlossary {
  const _ProtectedGlossary(this.text, this.markers);

  final String text;
  final Map<String, String> markers;
}
