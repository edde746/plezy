import 'package:flutter_whisper_ggml/flutter_whisper.dart' as whisper;

import 'subtitle_retimer.dart';

enum SubtitleWordTimingUnit { word, token }

/// A token-derived lexical timing. [confidence] is Whisper's mean token
/// probability, not a calibrated probability that the word is correct.
final class SubtitleWordTiming {
  const SubtitleWordTiming({
    required this.startMs,
    required this.endMs,
    required this.text,
    required this.confidence,
    required this.unit,
    this.cueIndex,
  });

  final int startMs;
  final int endMs;
  final String text;
  final double confidence;
  final SubtitleWordTimingUnit unit;

  /// One-based SRT cue index, assigned only when the timed span overlaps a cue.
  final int? cueIndex;

  SubtitleWordTiming withCueIndex(int? value) => SubtitleWordTiming(
        startMs: startMs,
        endMs: endMs,
        text: text,
        confidence: confidence,
        unit: unit,
        cueIndex: value,
      );
}

/// Converts Whisper token timestamps into whitespace-delimited word timings
/// when the recognized segment has word separators. Segments without separators
/// retain honest token timings instead of inventing word boundaries.
abstract final class SubtitleWordTimingBuilder {
  static const int _maximumWordTimings = 250000;

  static List<SubtitleWordTiming> fromWhisperSegments(
    Iterable<whisper.WhisperSegment> segments, {
    required int durationMs,
    int offsetMs = 0,
  }) {
    if (durationMs <= 0 || durationMs > SubtitleRetimer.maximumTimeMs) return const [];
    final output = <SubtitleWordTiming>[];
    for (final segment in segments) {
      final hasWordSeparators = RegExp(r'\s').hasMatch(segment.text.trim());
      StringBuffer? textBuffer;
      int? startMs;
      int? endMs;
      var probabilityTotal = 0.0;
      var probabilityCount = 0;

      void flush() {
        if (textBuffer == null || startMs == null || endMs == null || endMs! <= startMs!) {
          textBuffer = null;
          startMs = null;
          endMs = null;
          probabilityTotal = 0;
          probabilityCount = 0;
          return;
        }
        final text = textBuffer.toString().trim();
        if (text.isNotEmpty) {
          output.add(SubtitleWordTiming(
            startMs: startMs!,
            endMs: endMs!,
            text: text,
            confidence: probabilityCount == 0 ? 0 : (probabilityTotal / probabilityCount).clamp(0.0, 1.0).toDouble(),
            unit: hasWordSeparators ? SubtitleWordTimingUnit.word : SubtitleWordTimingUnit.token,
          ));
        }
        textBuffer = null;
        startMs = null;
        endMs = null;
        probabilityTotal = 0;
        probabilityCount = 0;
      }

      for (final token in segment.tokens) {
        final raw = token.text;
        final tokenText = raw.trim();
        if (tokenText.isEmpty || RegExp(r'^<\|.*\|>$').hasMatch(tokenText)) {
          if (RegExp(r'\s').hasMatch(raw)) flush();
          continue;
        }
        final relativeStart = token.start.inMilliseconds;
        final relativeEnd = token.end.inMilliseconds;
        if (relativeStart < 0 || relativeEnd <= relativeStart) continue;
        final start = (offsetMs + relativeStart).clamp(0, durationMs).toInt();
        final end = (offsetMs + relativeEnd).clamp(0, durationMs).toInt();
        if (end <= start) continue;

        final beginsWithWhitespace = RegExp(r'^\s').hasMatch(raw);
        final punctuationOnly = RegExp(r'^[\p{P}\p{S}]+$', unicode: true).hasMatch(tokenText);
        if (beginsWithWhitespace && !punctuationOnly) flush();

        // A native token that contains multiple whitespace-separated words
        // has no internal per-word timestamps, so retain it as a token span.
        if (RegExp(r'\s').hasMatch(tokenText)) {
          flush();
          output.add(SubtitleWordTiming(
            startMs: start,
            endMs: end,
            text: tokenText,
            confidence: token.probability.isFinite ? token.probability.clamp(0.0, 1.0).toDouble() : 0.0,
            unit: SubtitleWordTimingUnit.token,
          ));
          continue;
        }

        textBuffer ??= StringBuffer();
        startMs ??= start;
        endMs = endMs == null || end > endMs! ? end : endMs;
        textBuffer!.write(tokenText);
        final probability = token.probability;
        if (probability.isFinite) {
          probabilityTotal += probability.clamp(0.0, 1.0).toDouble();
          probabilityCount++;
        }
        if (output.length >= _maximumWordTimings) return List.unmodifiable(output);
      }
      flush();
      if (output.length >= _maximumWordTimings) break;
    }
    output.sort((a, b) {
      final time = a.startMs.compareTo(b.startMs);
      return time != 0 ? time : a.endMs.compareTo(b.endMs);
    });
    return List.unmodifiable(output);
  }

  static List<SubtitleWordTiming> attachCueIndices(
    List<SubtitleWordTiming> wordTimings,
    List<SubtitleCue> cues,
  ) {
    if (wordTimings.isEmpty || cues.isEmpty) return List.unmodifiable(wordTimings);
    final result = <SubtitleWordTiming>[];
    var firstPossibleCue = 0;
    for (final word in wordTimings) {
      while (firstPossibleCue < cues.length && cues[firstPossibleCue].endMs < word.startMs) {
        firstPossibleCue++;
      }
      var bestIndex = -1;
      var bestOverlap = 0;
      for (var index = firstPossibleCue; index < cues.length && cues[index].startMs <= word.endMs; index++) {
        final overlap = (cues[index].endMs < word.endMs ? cues[index].endMs : word.endMs) -
            (cues[index].startMs > word.startMs ? cues[index].startMs : word.startMs);
        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          bestIndex = index;
        }
      }
      result.add(word.withCueIndex(bestIndex < 0 ? null : cues[bestIndex].index));
    }
    return List.unmodifiable(result);
  }
}
