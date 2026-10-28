import 'dart:convert';
import 'dart:typed_data';

import 'subtitle_retimer.dart';

final class SubtitleSyncResult {
  const SubtitleSyncResult({
    required this.cues,
    required this.matchedCueCount,
    required this.totalCueCount,
    required this.discontinuityCount,
    required this.meanMatchConfidence,
    required this.appliedRate,
    required this.globalOffsetMs,
  });

  final List<SubtitleCue> cues;
  final int matchedCueCount;
  final int totalCueCount;
  final int discontinuityCount;
  final double meanMatchConfidence;
  final double appliedRate;
  final int globalOffsetMs;

  double get matchedFraction => totalCueCount == 0 ? 0 : matchedCueCount / totalCueCount;
}

/// Text-to-speech-anchor alignment for local SRT/VTT/ASS/SSA assets.
///
/// It changes only a derived cue list. Matching is bounded by subtitle parser
/// limits and a fixed candidate budget; weak matches are rejected instead of
/// silently applying a destructive global offset.
abstract final class SubtitleSyncService {
  static const int _minimumMatches = 3;
  static const int _maximumCandidateComparisons = 6000000;
  static const int _cutOffsetJumpMs = 1100;
  static const Set<String> _stopWords = {
    'about', 'after', 'again', 'against', 'being', 'could', 'every', 'from',
    'have', 'into', 'just', 'more', 'most', 'other', 'over', 'same', 'should',
    'some', 'such', 'than', 'that', 'their', 'there', 'these', 'thing', 'this',
    'those', 'through', 'under', 'very', 'want', 'were', 'what', 'when', 'where',
    'which', 'while', 'will', 'with', 'would', 'your',
  };

  /// Align a target subtitle against another already synchronized subtitle
  /// in the same spoken language. The reference cues provide the same
  /// monotonic text/time anchors used by WAV transcription without requiring
  /// a separate audio transcription pass.
  static SubtitleSyncResult synchronizeAgainstReference({
    required List<SubtitleCue> subtitleCues,
    required List<SubtitleCue> referenceCues,
    required int mediaDurationMs,
    required bool repairCuts,
  }) =>
      synchronize(
        subtitleCues: subtitleCues,
        speechCues: referenceCues,
        mediaDurationMs: mediaDurationMs,
        repairCuts: repairCuts,
      );

  static SubtitleSyncResult synchronize({
    required List<SubtitleCue> subtitleCues,
    required List<SubtitleCue> speechCues,
    required int mediaDurationMs,
    required bool repairCuts,
    bool preserveUnmatchedOutsideEvidence = false,
  }) {
    if (subtitleCues.length < _minimumMatches || speechCues.length < _minimumMatches) {
      throw const FormatException('At least three cues are needed in both the target subtitle and its reference text for automatic alignment.');
    }
    if (subtitleCues.length > SubtitleRetimer.maximumCueCount ||
        speechCues.length > SubtitleRetimer.maximumCueCount) {
      throw const FormatException('Subtitle alignment exceeded the cue processing bound.');
    }
    if (mediaDurationMs <= 0 || mediaDurationMs > SubtitleRetimer.maximumTimeMs) {
      throw const FormatException('Audio duration is outside the supported alignment range.');
    }
    final textBytes = [...subtitleCues, ...speechCues]
        .fold<int>(0, (total, cue) => total + utf8.encode(cue.text).length);
    if (textBytes > SubtitleRetimer.maximumInputBytes ||
        [...subtitleCues, ...speechCues].any((cue) =>
            cue.startMs < 0 || cue.endMs <= cue.startMs || cue.endMs > SubtitleRetimer.maximumTimeMs || cue.text.length > 4000)) {
      throw const FormatException('Subtitle alignment input exceeds a text or cue-time safety bound.');
    }

    final orderedSubtitles = [...subtitleCues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final orderedSpeech = [...speechCues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final speechTerms = <Set<String>>[];
    final postings = <String, List<int>>{};
    for (var index = 0; index < orderedSpeech.length; index++) {
      final terms = _terms(orderedSpeech[index].text);
      speechTerms.add(terms);
      for (final term in terms) {
        if (!_isUsableTerm(term) || _stopWords.contains(term)) continue;
        postings.putIfAbsent(term, () => <int>[]).add(index);
      }
    }

    final anchors = <_SubtitleAnchor>[];
    var lastSpeechIndex = -1;
    var comparisons = 0;
    var postingVisits = 0;
    for (var subIndex = 0; subIndex < orderedSubtitles.length; subIndex++) {
      final subtitle = orderedSubtitles[subIndex];
      final terms = _terms(subtitle.text);
      final hits = <int, int>{};
      for (final term in terms) {
        if (!_isUsableTerm(term) || _stopWords.contains(term)) continue;
        final indices = postings[term];
        if (indices == null) continue;
        final stride = indices.length > 256 ? (indices.length / 256).ceil() : 1;
        for (var offset = 0; offset < indices.length; offset += stride) {
          postingVisits++;
          if (postingVisits > _maximumCandidateComparisons) {
            throw const FormatException('Subtitle alignment exceeded its bounded index-search budget.');
          }
          final candidate = indices[offset];
          if (candidate <= lastSpeechIndex) continue;
          hits.update(candidate, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      final expectedIndex = orderedSubtitles.length == 1
          ? 0
          : (subIndex * (orderedSpeech.length - 1) / (orderedSubtitles.length - 1)).round();
      if (hits.isEmpty) {
        for (var delta = -3; delta <= 3; delta++) {
          final candidate = (expectedIndex + delta).clamp(0, orderedSpeech.length - 1).toInt();
          if (candidate > lastSpeechIndex) hits.putIfAbsent(candidate, () => 0);
        }
      }

      final candidates = hits.keys.toList()
        ..sort((a, b) {
          final hitOrder = hits[b]!.compareTo(hits[a]!);
          return hitOrder != 0 ? hitOrder : a.compareTo(b);
        });
      if (candidates.length > 80) candidates.length = 80;

      _SubtitleAnchor? best;
      for (final speechIndex in candidates) {
        comparisons++;
        if (comparisons > _maximumCandidateComparisons) {
          throw const FormatException('Subtitle alignment exceeded its bounded comparison budget.');
        }
        final speech = orderedSpeech[speechIndex];
        final confidence = _similarity(terms, speechTerms[speechIndex]);
        if (confidence < 0.42) continue;
        final temporalPenalty = ((speechIndex - expectedIndex).abs() / orderedSpeech.length * 0.025).clamp(0.0, 0.025);
        final adjustedConfidence = confidence - temporalPenalty;
        if (best == null || adjustedConfidence > best.confidence) {
          best = _SubtitleAnchor(
            subtitleIndex: subIndex,
            speechIndex: speechIndex,
            confidence: adjustedConfidence,
          );
        }
      }

      if (best != null && best.confidence >= 0.44) {
        anchors.add(best);
        lastSpeechIndex = best.speechIndex;
      }
    }

    final minimumRequired = _minimumMatches > (orderedSubtitles.length * 0.03).ceil()
        ? _minimumMatches
        : (orderedSubtitles.length * 0.03).ceil();
    final meanConfidence = anchors.isEmpty
        ? 0.0
        : anchors.map((anchor) => anchor.confidence).reduce((a, b) => a + b) / anchors.length;
    if (anchors.length < minimumRequired || meanConfidence < 0.58) {
      throw FormatException(
        'Only ${anchors.length} reliable speech matches were found '
        '(${(meanConfidence * 100).round()}% average confidence). '
        'Use a subtitle in the same language as the reference text, or align two cues manually.',
      );
    }

    final matchedBySubtitle = <int, _SubtitleAnchor>{for (final anchor in anchors) anchor.subtitleIndex: anchor};
    final rate = repairCuts ? 1.0 : _robustRate(anchors, orderedSubtitles, orderedSpeech);
    final globalOffset = _median(
      anchors
          .map((anchor) => orderedSpeech[anchor.speechIndex].startMs -
              (orderedSubtitles[anchor.subtitleIndex].startMs * rate).round())
          .toList(),
    );
    final discontinuities = repairCuts ? _countDiscontinuities(anchors, orderedSubtitles, orderedSpeech) : 0;

    int offsetAt(int sourceTimeMs) {
      if (!repairCuts) return globalOffset;
      var lower = 0;
      var upper = anchors.length - 1;
      if (sourceTimeMs <= orderedSubtitles[anchors.first.subtitleIndex].startMs) {
        upper = 0;
      } else if (sourceTimeMs >= orderedSubtitles[anchors.last.subtitleIndex].startMs) {
        lower = anchors.length - 1;
      } else {
        while (lower + 1 < upper) {
          final middle = (lower + upper) ~/ 2;
          final middleTime = orderedSubtitles[anchors[middle].subtitleIndex].startMs;
          if (sourceTimeMs < middleTime) {
            upper = middle;
          } else {
            lower = middle;
          }
        }
      }
      final previousAnchor = anchors[lower];
      final nextAnchor = anchors[upper];
      final previousTime = orderedSubtitles[previousAnchor.subtitleIndex].startMs;
      final nextTime = orderedSubtitles[nextAnchor.subtitleIndex].startMs;
      final previousOffset =
          orderedSpeech[previousAnchor.speechIndex].startMs - previousTime;
      final nextOffset = orderedSpeech[nextAnchor.speechIndex].startMs - nextTime;
      if (previousAnchor == nextAnchor || nextTime <= previousTime) return previousOffset;

      if ((nextOffset - previousOffset).abs() >= _cutOffsetJumpMs) {
        final boundary = previousTime + (nextTime - previousTime) ~/ 2;
        return sourceTimeMs < boundary ? previousOffset : nextOffset;
      }

      final fraction = ((sourceTimeMs - previousTime) / (nextTime - previousTime)).clamp(0.0, 1.0);
      return (previousOffset + (nextOffset - previousOffset) * fraction).round();
    }

    final repaired = <SubtitleCue>[];
    for (var index = 0; index < orderedSubtitles.length; index++) {
      final source = orderedSubtitles[index];
      final anchor = matchedBySubtitle[index];
      if (preserveUnmatchedOutsideEvidence && !anchors.any((evidence) {
        final speech = orderedSpeech[evidence.speechIndex];
        return source.startMs <= speech.endMs + 15000 && source.endMs >= speech.startMs - 15000;
      })) {
        repaired.add(SubtitleCue(
          index: repaired.length + 1,
          startMs: source.startMs,
          endMs: source.endMs,
          text: source.text,
        ));
        continue;
      }
      final correction = repairCuts && anchor != null
          ? orderedSpeech[anchor.speechIndex].startMs - source.startMs
          : offsetAt(source.startMs);
      final start = (source.startMs * rate).round() + correction;
      final end = (source.endMs * rate).round() + correction;
      if (end <= 0 || start >= mediaDurationMs) continue;
      final clippedStart = start.clamp(0, mediaDurationMs).toInt();
      final clippedEnd = end.clamp(clippedStart + 1, mediaDurationMs).toInt();
      if (clippedEnd <= clippedStart) continue;
      repaired.add(SubtitleCue(
        index: repaired.length + 1,
        startMs: clippedStart,
        endMs: clippedEnd,
        text: source.text,
      ));
    }
    if (repaired.isEmpty) throw const FormatException('Alignment moved every subtitle cue outside the audio duration.');

    return SubtitleSyncResult(
      cues: List.unmodifiable(repaired),
      matchedCueCount: anchors.length,
      totalCueCount: orderedSubtitles.length,
      discontinuityCount: discontinuities,
      meanMatchConfidence: meanConfidence,
      appliedRate: rate,
      globalOffsetMs: globalOffset,
    );
  }

  /// Writes an independent UTF-8 SRT asset without changing source files.
  static Uint8List writeSrt(List<SubtitleCue> cues) {
    if (cues.isEmpty || cues.length > SubtitleRetimer.maximumCueCount) {
      throw const FormatException('Subtitle output is empty or exceeds the cue processing bound.');
    }
    final sorted = [...cues]..sort((a, b) => a.startMs.compareTo(b.startMs));
    final output = StringBuffer();
    var outputIndex = 0;
    for (var index = 0; index < sorted.length; index++) {
      final cue = sorted[index];
      if (cue.startMs < 0 || cue.endMs <= cue.startMs || cue.endMs > SubtitleRetimer.maximumTimeMs) {
        throw const FormatException('Subtitle output contains an invalid cue time.');
      }
      final text = cue.text.replaceAll('\u0000', '').trim();
      if (text.isEmpty || text.length > 4000) continue;
      outputIndex++;
      output
        ..writeln(outputIndex)
        ..writeln('${_formatTime(cue.startMs)} --> ${_formatTime(cue.endMs)}')
        ..writeln(text)
        ..writeln();
    }
    final bytes = Uint8List.fromList(utf8.encode(output.toString().replaceAll('\n', '\r\n')));
    if (bytes.lengthInBytes > SubtitleRetimer.maximumInputBytes) {
      throw const FormatException('Generated SRT exceeds the 5 MiB subtitle processing bound.');
    }
    return bytes;
  }

  static bool _isUsableTerm(String term) =>
      term.runes.length >= 3 || (term.runes.length == 2 && term.runes.any((rune) => rune >= 0x2e80));

  static Set<String> _terms(String text) {
    final withoutMarkup = text
        .replaceAll(RegExp(r'<[^>]{0,160}>'), ' ')
        .replaceAll(RegExp(r'\{[^}]{0,160}\}'), ' ')
        .toLowerCase();
    final normalized = StringBuffer();
    var previousWasSpace = true;
    for (final rune in withoutMarkup.runes) {
      final isAsciiWord = (rune >= 48 && rune <= 57) || (rune >= 97 && rune <= 122);
      final isUnicodeScript = rune >= 0x80 &&
          !(rune >= 0x2000 && rune <= 0x206f) &&
          !(rune >= 0x3000 && rune <= 0x303f) &&
          !(rune >= 0xff00 && rune <= 0xff65);
      if (isAsciiWord || isUnicodeScript) {
        if (!previousWasSpace) {
          normalized.writeCharCode(rune);
        } else {
          normalized.writeCharCode(rune);
        }
        previousWasSpace = false;
      } else {
        if (!previousWasSpace) normalized.write(' ');
        previousWasSpace = true;
      }
    }
    final tokens = normalized.toString().trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    final terms = <String>{};
    for (final token in tokens) {
      final runes = token.runes.toList(growable: false);
      if (runes.length >= 3) terms.add(token);
      if (runes.length >= 2 && runes.every((rune) => rune >= 0x2e80)) {
        for (var index = 0; index < runes.length - 1; index++) {
          terms.add(String.fromCharCodes([runes[index], runes[index + 1]]));
        }
      }
      if (runes.length > 6 && runes.every((rune) => rune < 0x2e80)) {
        for (var index = 0; index < runes.length - 1; index++) {
          terms.add(String.fromCharCodes([runes[index], runes[index + 1]]));
        }
      }
    }
    return terms;
  }

  static double _similarity(Set<String> left, Set<String> right) {
    if (left.isEmpty || right.isEmpty) return 0;
    final shared = left.intersection(right).length;
    final tokenDice = 2 * shared / (left.length + right.length);
    if (tokenDice >= 0.96) return tokenDice;

    final leftBigrams = _bigrams(left);
    final rightBigrams = _bigrams(right);
    if (leftBigrams.isEmpty || rightBigrams.isEmpty) return tokenDice;
    final bigramDice = 2 * leftBigrams.intersection(rightBigrams).length / (leftBigrams.length + rightBigrams.length);
    return tokenDice * 0.58 + bigramDice * 0.42;
  }

  static Set<String> _bigrams(Set<String> terms) {
    final output = <String>{};
    for (final term in terms) {
      final runes = term.runes.toList(growable: false);
      for (var index = 0; index + 1 < runes.length; index++) {
        output.add(String.fromCharCodes([runes[index], runes[index + 1]]));
      }
    }
    return output;
  }

  static double _robustRate(
    List<_SubtitleAnchor> anchors,
    List<SubtitleCue> subtitles,
    List<SubtitleCue> speech,
  ) {
    final slopes = <double>[];
    for (var left = 0; left < anchors.length; left++) {
      final leftSource = subtitles[anchors[left].subtitleIndex].startMs;
      final leftTarget = speech[anchors[left].speechIndex].startMs;
      for (var right = left + 1; right < anchors.length && right <= left + 12; right++) {
        final sourceDelta = subtitles[anchors[right].subtitleIndex].startMs - leftSource;
        if (sourceDelta < 30000) continue;
        final targetDelta = speech[anchors[right].speechIndex].startMs - leftTarget;
        final slope = targetDelta / sourceDelta;
        if (slope >= 0.90 && slope <= 1.10) slopes.add(slope);
      }
    }
    if (slopes.isEmpty) return 1.0;
    return _medianDouble(slopes).clamp(0.92, 1.08).toDouble();
  }

  static int _countDiscontinuities(
    List<_SubtitleAnchor> anchors,
    List<SubtitleCue> subtitles,
    List<SubtitleCue> speech,
  ) {
    var count = 0;
    var previousOffset = speech[anchors.first.speechIndex].startMs - subtitles[anchors.first.subtitleIndex].startMs;
    for (final anchor in anchors.skip(1)) {
      final offset = speech[anchor.speechIndex].startMs - subtitles[anchor.subtitleIndex].startMs;
      if ((offset - previousOffset).abs() >= _cutOffsetJumpMs) count++;
      previousOffset = offset;
    }
    return count;
  }

  static int _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[middle] : ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }

  static double _medianDouble(List<double> values) {
    if (values.isEmpty) return 1.0;
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  static String _formatTime(int valueMs) {
    final hours = valueMs ~/ 3600000;
    final minutes = (valueMs % 3600000) ~/ 60000;
    final seconds = (valueMs % 60000) ~/ 1000;
    final milliseconds = valueMs % 1000;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')},'
        '${milliseconds.toString().padLeft(3, '0')}';
  }
}

final class _SubtitleAnchor {
  const _SubtitleAnchor({
    required this.subtitleIndex,
    required this.speechIndex,
    required this.confidence,
  });

  final int subtitleIndex;
  final int speechIndex;
  final double confidence;
}
