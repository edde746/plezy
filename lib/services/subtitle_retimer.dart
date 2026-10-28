import 'dart:convert';

/// A derived subtitle file whose cue times follow the active MPV timing
/// correction. The source bytes are never modified.
final class SubtitleRetimingResult {
  const SubtitleRetimingResult({
    required this.bytes,
    required this.retimedCueCount,
    required this.clippedCueCount,
    required this.format,
  });

  final List<int> bytes;
  final int retimedCueCount;
  final int clippedCueCount;
  final String format;
}

/// Loss-aware SRT/WebVTT retimer for export.
///
/// MPV applies subtitle timing as `sourceTime * sub-speed + sub-delay`.
/// This exporter uses that same affine transform, preserving cue payload,
/// WebVTT cue settings, identifiers, and file line endings.
abstract final class SubtitleRetimer {
  static const int maximumInputBytes = 5 * 1024 * 1024;
  static const int maximumTimeMs = 60 * 24 * 60 * 60 * 1000;
  static const int minimumDelayMs = -60000;
  static const int maximumDelayMs = 60000;
  static const double minimumRate = 0.8;
  static const double maximumRate = 1.25;

  static final RegExp _timingLine = RegExp(r'^([ \t]*)(\S+)([ \t]+-->[ \t]+)(\S+)(.*)$');

  static SubtitleRetimingResult retime({
    required List<int> sourceBytes,
    required String extension,
    required int delayMs,
    required double rate,
  }) {
    final format = extension.toLowerCase();
    if (format != '.srt' && format != '.vtt') {
      throw ArgumentError.value(extension, 'extension', 'Only SRT and WebVTT export is supported.');
    }
    if (sourceBytes.isEmpty || sourceBytes.length > maximumInputBytes) {
      throw FormatException('Subtitle input is empty or larger than the 5 MiB processing bound.');
    }
    if (delayMs < minimumDelayMs || delayMs > maximumDelayMs) {
      throw RangeError.range(delayMs, minimumDelayMs, maximumDelayMs, 'delayMs');
    }
    if (!rate.isFinite || rate < minimumRate || rate > maximumRate) {
      throw RangeError.range(rate, minimumRate, maximumRate, 'rate');
    }

    var source = utf8.decode(sourceBytes, allowMalformed: false);
    final hasBom = source.startsWith('\uFEFF');
    if (hasBom) source = source.substring(1);
    if (source.contains('\u0000')) throw const FormatException('Subtitle contains a NUL byte.');
    final newline = source.contains('\r\n')
        ? '\r\n'
        : source.contains('\r')
        ? '\r'
        : '\n';
    final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final output = <String>[];
    final block = <String>[];
    var retimedCueCount = 0;
    var clippedCueCount = 0;
    final isVtt = format == '.vtt';

    void flushBlock() {
      if (block.isEmpty) return;
      final firstLine = block.first.trimLeft().toUpperCase();
      final isNoteBlock = firstLine == 'NOTE' || firstLine.startsWith('NOTE ');
      final noteHasCueTiming = block.length > 1 && _timingLine.firstMatch(block[1]) != null;
      if (isVtt &&
          (firstLine == 'WEBVTT' ||
              (isNoteBlock && !noteHasCueTiming) ||
              firstLine == 'STYLE' ||
              firstLine == 'REGION')) {
        output.addAll(block);
        block.clear();
        return;
      }

      for (var index = 0; index < block.length; index++) {
        final match = _timingLine.firstMatch(block[index]);
        if (match == null) continue;
        final start = _parseTime(match.group(2)!, isVtt: isVtt);
        final end = _parseTime(match.group(4)!, isVtt: isVtt);
        if (start == null || end == null) {
          throw const FormatException('Subtitle cue contains an invalid timestamp.');
        }
        if (end <= start) throw const FormatException('Subtitle cue end must be after its start.');

        retimedCueCount++;
        final transformedStart = (start * rate).round() + delayMs;
        final transformedEnd = (end * rate).round() + delayMs;
        if (transformedEnd <= 0) {
          clippedCueCount++;
          block.clear();
          return;
        }
        if (transformedStart > maximumTimeMs || transformedEnd > maximumTimeMs) {
          throw const FormatException('Retimed subtitle cue is outside the supported range.');
        }

        final outputStart = transformedStart < 0 ? 0 : transformedStart;
        final outputEnd = transformedEnd;
        if (outputEnd <= outputStart) throw const FormatException('Retimed subtitle cue has no visible duration.');
        final startSeparator = isVtt || match.group(2)!.contains('.') ? '.' : ',';
        final endSeparator = isVtt || match.group(4)!.contains('.') ? '.' : ',';
        block[index] =
            '${match.group(1)}${_formatTime(outputStart, separator: startSeparator, keepHours: match.group(2)!.split(':').length == 3)}'
            '${match.group(3)}${_formatTime(outputEnd, separator: endSeparator, keepHours: match.group(4)!.split(':').length == 3)}'
            '${match.group(5)}';
        break;
      }
      output.addAll(block);
      block.clear();
    }

    for (final line in lines) {
      if (line.trim().isEmpty) {
        flushBlock();
        output.add(line);
      } else {
        block.add(line);
      }
    }
    flushBlock();
    if (retimedCueCount == 0) {
      throw const FormatException('No valid SRT/WebVTT cue timing lines were found.');
    }

    final result = output.join(newline);
    return SubtitleRetimingResult(
      bytes: utf8.encode('${hasBom ? '\uFEFF' : ''}$result'),
      retimedCueCount: retimedCueCount,
      clippedCueCount: clippedCueCount,
      format: isVtt ? 'WebVTT' : 'SRT',
    );
  }

  static int? _parseTime(String value, {required bool isVtt}) {
    final match = RegExp(r'^(\d+):([0-5]\d)(?::([0-5]\d))?([,.])(\d{3})$').firstMatch(value);
    if (match == null || (isVtt && match.group(4) != '.')) return null;
    final first = int.tryParse(match.group(1)!);
    final second = int.tryParse(match.group(2)!);
    final third = match.group(3) == null ? null : int.tryParse(match.group(3)!);
    final millis = int.tryParse(match.group(5)!);
    if (first == null ||
        second == null ||
        millis == null ||
        match.group(1)!.length > 6 ||
        (third != null && first > 999999)) {
      throw const FormatException('Subtitle timestamp is outside the supported range.');
    }
    final hours = third == null ? 0 : first;
    final minutes = third == null ? first : second;
    final seconds = third ?? second;
    final total = (((hours * 60 + minutes) * 60 + seconds) * 1000) + millis;
    if (total < 0 || total > maximumTimeMs) {
      throw const FormatException('Subtitle timestamp is outside the supported range.');
    }
    return total;
  }

  static String _formatTime(int valueMs, {required String separator, required bool keepHours}) {
    final hours = valueMs ~/ 3600000;
    final minutes = (valueMs ~/ 60000) % 60;
    final seconds = (valueMs ~/ 1000) % 60;
    final millis = valueMs % 1000;
    final minutesText = minutes.toString().padLeft(2, '0');
    final secondsText = seconds.toString().padLeft(2, '0');
    final millisText = millis.toString().padLeft(3, '0');
    if (keepHours || hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutesText:$secondsText$separator$millisText';
    }
    return '$minutesText:$secondsText$separator$millisText';
  }
}
