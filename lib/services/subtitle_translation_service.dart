import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../utils/platform_detector.dart';
import 'subtitle_retimer.dart';

/// On-device text translation. ML Kit does not expose whether the native
/// implementation used CPU, GPU, or another accelerator.
abstract final class SubtitleTranslationService {
  static const bool _tvOsBuild = bool.fromEnvironment('TVOS_BUILD');

  static bool get platformSupported =>
      !kIsWeb && !_tvOsBuild && (Platform.isAndroid || Platform.isIOS);

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
    if (!platformSupported) return false;
    if (Platform.isAndroid) {
      final detector = await TvDetectionService.getInstance();
      if (detector.isTVDevice || detector.isAutomotive || detector.isAppleTV) return false;
    }
    // ML Kit's published terms restrict the on-device Translation API to
    // phones and tablets. The Flutter bridge exists only on
    // Android/iOS; this app gates embedded Android TV/automotive and tvOS.
    return true;
  }

  static Future<List<SubtitleCue>> translateCues({
    required List<SubtitleCue> cues,
    required TranslateLanguage sourceLanguage,
    required TranslateLanguage targetLanguage,
    bool allowMobileData = false,
    void Function(int completed, int total)? onProgress,
  }) async {
    if (!await isSupportedOnCurrentDevice()) {
      throw UnsupportedError('On-device translation is available on phones and tablets only.');
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
    return List.unmodifiable(translated);
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
