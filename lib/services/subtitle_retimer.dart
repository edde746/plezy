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

/// A text-backed subtitle event available for manual timing alignment.
final class SubtitleCue {
  const SubtitleCue({
    required this.index,
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  final int index;
  final int startMs;
  final int endMs;
  final String text;
}


enum _SubtitleTextEncoding { utf8, utf8Bom, utf16LittleEndian, utf16BigEndian }

final class _DecodedSubtitleText {
  const _DecodedSubtitleText(this.text, this.encoding);

  final String text;
  final _SubtitleTextEncoding encoding;
}

/// Loss-aware SRT/WebVTT and guarded ASS/SSA retimer with bounded cue inspection.
///
/// MPV applies subtitle timing as `sourceTime * sub-speed + sub-delay`.
/// The exporter uses that affine transform, preserving cue payload,
/// WebVTT cue settings, identifiers, and file line endings.
abstract final class SubtitleRetimer {
  static _DecodedSubtitleText _decodeText(List<int> bytes) {
    if (bytes.any((byte) => byte < 0 || byte > 255)) {
      throw const FormatException('Subtitle contains a byte outside the 0–255 range.');
    }
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
      if ((bytes.length - 2).isOdd) {
        throw const FormatException('UTF-16LE subtitle ends with an incomplete code unit.');
      }
      return _DecodedSubtitleText(_decodeUtf16(bytes, littleEndian: true), _SubtitleTextEncoding.utf16LittleEndian);
    }
    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      if ((bytes.length - 2).isOdd) {
        throw const FormatException('UTF-16BE subtitle ends with an incomplete code unit.');
      }
      return _DecodedSubtitleText(_decodeUtf16(bytes, littleEndian: false), _SubtitleTextEncoding.utf16BigEndian);
    }
    final hasUtf8Bom = bytes.length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf;
    final payload = hasUtf8Bom ? bytes.skip(3).toList(growable: false) : bytes;
    return _DecodedSubtitleText(
      utf8.decode(payload, allowMalformed: false),
      hasUtf8Bom ? _SubtitleTextEncoding.utf8Bom : _SubtitleTextEncoding.utf8,
    );
  }

  static String _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    final codePoints = <int>[];
    for (var index = 2; index < bytes.length; index += 2) {
      final first = bytes[index];
      final second = bytes[index + 1];
      final unit = littleEndian ? first | (second << 8) : (first << 8) | second;
      if (unit >= 0xd800 && unit <= 0xdbff) {
        if (index + 3 >= bytes.length) {
          throw const FormatException('UTF-16 subtitle ends with an unpaired high surrogate.');
        }
        final nextFirst = bytes[index + 2];
        final nextSecond = bytes[index + 3];
        final next = littleEndian ? nextFirst | (nextSecond << 8) : (nextFirst << 8) | nextSecond;
        if (next < 0xdc00 || next > 0xdfff) {
          throw const FormatException('UTF-16 subtitle contains an invalid surrogate pair.');
        }
        codePoints.add(0x10000 + ((unit - 0xd800) << 10) + (next - 0xdc00));
        index += 2;
      } else if (unit >= 0xdc00 && unit <= 0xdfff) {
        throw const FormatException('UTF-16 subtitle contains an unpaired low surrogate.');
      } else {
        codePoints.add(unit);
      }
    }
    return String.fromCharCodes(codePoints);
  }

  static List<int> _encodeText(String text, _SubtitleTextEncoding encoding) {
    if (encoding == _SubtitleTextEncoding.utf8) return utf8.encode(text);
    if (encoding == _SubtitleTextEncoding.utf8Bom) {
      return [0xef, 0xbb, 0xbf, ...utf8.encode(text)];
    }

    final bytes = <int>[];
    final littleEndian = encoding == _SubtitleTextEncoding.utf16LittleEndian;
    bytes.addAll(littleEndian ? const [0xff, 0xfe] : const [0xfe, 0xff]);
    for (final rune in text.runes) {
      if (rune <= 0xffff) {
        _appendUtf16Unit(bytes, rune, littleEndian);
      } else {
        final scalar = rune - 0x10000;
        _appendUtf16Unit(bytes, 0xd800 + (scalar >> 10), littleEndian);
        _appendUtf16Unit(bytes, 0xdc00 + (scalar & 0x3ff), littleEndian);
      }
    }
    return bytes;
  }

  static void _appendUtf16Unit(List<int> bytes, int unit, bool littleEndian) {
    if (littleEndian) {
      bytes
        ..add(unit & 0xff)
        ..add(unit >> 8);
    } else {
      bytes
        ..add(unit >> 8)
        ..add(unit & 0xff);
    }
  }
  static const int maximumInputBytes = 5 * 1024 * 1024;
  static const int maximumCueCount = 50000;
  static const int maximumTimeMs = 60 * 24 * 60 * 60 * 1000;
  static const int minimumDelayMs = -60000;
  static const int maximumDelayMs = 60000;
  static const double minimumRate = 0.8;
  static const double maximumRate = 1.25;

  static final RegExp _timingLine = RegExp(r'^([ \t]*)(\S+)([ \t]+-->[ \t]+)(\S+)(.*)$');
  static final RegExp _assDialogueLine = RegExp(r'^\s*Dialogue\s*:', caseSensitive: false);
  static final RegExp _assTimeExpression = RegExp(r'^(\d{1,6}):([0-5]\d):([0-5]\d)\.(\d{2})$');
  static final RegExp _assTimedTag = RegExp(r'\\(?:kf|ko|kt|k|t|move|fad|fade)(?=[0-9(]|$)', caseSensitive: false);

  /// Parses bounded SRT, WebVTT, ASS, or SSA timing and payload for an interactive cue
  /// picker. The source bytes remain untouched and cues retain display text.
  static List<SubtitleCue> parseCues({
    required List<int> sourceBytes,
    required String extension,
  }) {
    final format = extension.toLowerCase();
    const supportedFormats = {'.srt', '.vtt', '.ass', '.ssa'};
    if (!supportedFormats.contains(format)) {
      throw ArgumentError.value(
        extension,
        'extension',
        'Only SRT, WebVTT, ASS, and SSA cue inspection is supported.',
      );
    }
    if (sourceBytes.isEmpty || sourceBytes.length > maximumInputBytes) {
      throw FormatException('Subtitle input is empty or larger than the 5 MiB processing bound.');
    }
    if (format == '.ass' || format == '.ssa') return _parseAssCues(sourceBytes);

    var source = _decodeText(sourceBytes).text;
    if (source.contains('\u0000')) throw const FormatException('Subtitle contains a NUL byte.');
    final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final isVtt = format == '.vtt';
    final cues = <SubtitleCue>[];
    final block = <String>[];

    void flushBlock() {
      if (block.isEmpty) return;
      final firstLine = block.first.trimLeft().toUpperCase();
      final isNoteBlock = firstLine == 'NOTE' || firstLine.startsWith('NOTE ');
      final noteHasCueTiming = block.length > 1 && _timingLine.firstMatch(block[1]) != null;
      if (isVtt &&
          (firstLine == 'WEBVTT' ||
              firstLine.startsWith('WEBVTT ') ||
              (isNoteBlock && !noteHasCueTiming) ||
              firstLine == 'STYLE' ||
              firstLine == 'REGION')) {
        block.clear();
        return;
      }

      for (var lineIndex = 0; lineIndex < block.length; lineIndex++) {
        final match = _timingLine.firstMatch(block[lineIndex]);
        if (match == null) continue;
        final start = _parseTime(match.group(2)!, isVtt: isVtt);
        final end = _parseTime(match.group(4)!, isVtt: isVtt);
        if (start == null || end == null) {
          throw const FormatException('Subtitle cue contains an invalid timestamp.');
        }
        if (end <= start) throw const FormatException('Subtitle cue end must be after its start.');
        final text = block.skip(lineIndex + 1).join('\n').trim();
        if (text.isNotEmpty) {
          if (cues.length >= maximumCueCount) {
            throw const FormatException('Subtitle has more cues than the 50000 cue processing bound.');
          }
          cues.add(SubtitleCue(index: cues.length + 1, startMs: start, endMs: end, text: text));
        }
        break;
      }
      block.clear();
    }

    for (final line in lines) {
      if (line.trim().isEmpty) {
        flushBlock();
      } else {
        block.add(line);
      }
    }
    flushBlock();
    if (cues.isEmpty) throw const FormatException('No text subtitle cues were found.');
    cues.sort((a, b) {
      final timeOrder = a.startMs.compareTo(b.startMs);
      return timeOrder != 0 ? timeOrder : a.index.compareTo(b.index);
    });
    return List.unmodifiable(cues);
  }

  static SubtitleRetimingResult retime({
    required List<int> sourceBytes,
    required String extension,
    required int delayMs,
    required double rate,
  }) {
    final format = extension.toLowerCase();
    if (format != '.srt' && format != '.vtt' && format != '.ass' && format != '.ssa') {
      throw ArgumentError.value(extension, 'extension', 'Only SRT, WebVTT, ASS, and SSA export is supported.');
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

    if (format == '.ass' || format == '.ssa') {
      return _retimeAss(sourceBytes: sourceBytes, delayMs: delayMs, rate: rate, format: format);
    }

    final decoded = _decodeText(sourceBytes);
    var source = decoded.text;
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
      bytes: _encodeText(result, decoded.encoding),
      retimedCueCount: retimedCueCount,
      clippedCueCount: clippedCueCount,
      format: isVtt ? 'WebVTT' : 'SRT',
    );
  }

  static SubtitleRetimingResult _retimeAss({
    required List<int> sourceBytes,
    required int delayMs,
    required double rate,
    required String format,
  }) {
    final decoded = _decodeText(sourceBytes);
    var source = decoded.text;
    if (source.contains('\u0000')) throw const FormatException('Subtitle contains a NUL byte.');
    final newline = source.contains('\r\n')
        ? '\r\n'
        : source.contains('\r')
        ? '\r'
        : '\n';
    final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final output = <String>[];
    List<String>? formatFields;
    var inEvents = false;
    var retimedCueCount = 0;
    var clippedCueCount = 0;

    String formatFieldTime(String original, int timeMs) {
      final leading = RegExp(r'^\s*').firstMatch(original)!.group(0)!;
      final trailing = RegExp(r'\s*$').firstMatch(original)!.group(0)!;
      return leading + _formatAssTime(timeMs) + trailing;
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        inEvents = trimmed.toLowerCase() == '[events]';
        formatFields = null;
        output.add(line);
        continue;
      }
      if (inEvents && trimmed.toLowerCase().startsWith('format:')) {
        formatFields = trimmed.substring('format:'.length).split(',').map((field) => field.trim().toLowerCase()).toList();
        if (!formatFields.contains('start') ||
            !formatFields.contains('end') ||
            !formatFields.contains('text') ||
            formatFields.last != 'text') {
          throw const FormatException('ASS event format must end in a text field and include start and end.');
        }
        output.add(line);
        continue;
      }
      if (!inEvents || !_assDialogueLine.hasMatch(line)) {
        output.add(line);
        continue;
      }

      final fields = formatFields;
      if (fields == null) throw const FormatException('ASS dialogue appears before its event format.');
      final colonIndex = line.indexOf(':');
      final values = _splitAssFields(line.substring(colonIndex + 1), fields.length);
      final textIndex = fields.indexOf('text');
      final text = values[textIndex];
      if (_assTimedTag.hasMatch(text)) {
        throw const FormatException('ASS dialogue contains karaoke or animated timing tags and cannot be retimed safely.');
      }
      final effectIndex = fields.indexOf('effect');
      if (effectIndex >= 0 && values[effectIndex].trim().isNotEmpty) {
        throw const FormatException('ASS dialogue effects cannot be retimed safely.');
      }
      final startIndex = fields.indexOf('start');
      final endIndex = fields.indexOf('end');
      final start = _parseAssTime(values[startIndex].trim());
      final end = _parseAssTime(values[endIndex].trim());
      if (start == null || end == null) {
        throw const FormatException('ASS cue contains an invalid timestamp.');
      }
      if (end <= start) throw const FormatException('ASS cue end must be after its start.');
      retimedCueCount++;

      final transformedStart = (start * rate).round() + delayMs;
      final transformedEnd = (end * rate).round() + delayMs;
      if (transformedEnd <= 0) {
        clippedCueCount++;
        continue;
      }
      if (transformedStart > maximumTimeMs || transformedEnd > maximumTimeMs) {
        throw const FormatException('Retimed subtitle cue is outside the supported range.');
      }
      final visibleStart = transformedStart < 0 ? 0 : transformedStart;
      if (transformedEnd <= visibleStart) {
        throw const FormatException('Retimed subtitle cue has no visible duration.');
      }

      values[startIndex] = formatFieldTime(values[startIndex], visibleStart);
      values[endIndex] = formatFieldTime(values[endIndex], transformedEnd);
      output.add(line.substring(0, colonIndex + 1) + values.join(','));
    }
    if (retimedCueCount == 0) throw const FormatException('No valid ASS dialogue cues were found.');

    final outputText = output.join(newline);
    return SubtitleRetimingResult(
      bytes: _encodeText(outputText, decoded.encoding),
      retimedCueCount: retimedCueCount,
      clippedCueCount: clippedCueCount,
      format: format == '.ssa' ? 'SSA' : 'ASS',
    );
  }

  static String _formatAssTime(int timeMs) {
    final centiseconds = (timeMs / 10).round();
    final totalMs = centiseconds * 10;
    final hours = totalMs ~/ 3600000;
    final minutes = (totalMs ~/ 60000) % 60;
    final seconds = (totalMs ~/ 1000) % 60;
    final subsecond = centiseconds % 100;
    return hours.toString() +
        ':' +
        minutes.toString().padLeft(2, '0') +
        ':' +
        seconds.toString().padLeft(2, '0') +
        '.' +
        subsecond.toString().padLeft(2, '0');
  }

  static List<SubtitleCue> _parseAssCues(List<int> sourceBytes) {
    var source = _decodeText(sourceBytes).text;
    if (source.contains('\u0000')) throw const FormatException('Subtitle contains a NUL byte.');

    final cues = <SubtitleCue>[];
    final lines = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    List<String>? formatFields;
    var inEvents = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        inEvents = trimmed.toLowerCase() == '[events]';
        formatFields = null;
        continue;
      }
      if (!inEvents) continue;
      if (trimmed.toLowerCase().startsWith('format:')) {
        formatFields = trimmed.substring('format:'.length).split(',').map((field) => field.trim().toLowerCase()).toList();
        if (!formatFields.contains('start') ||
            !formatFields.contains('end') ||
            !formatFields.contains('text') ||
            formatFields.last != 'text') {
          throw const FormatException('ASS event format must end in a text field and include start and end.');
        }
        continue;
      }
      if (!_assDialogueLine.hasMatch(line)) continue;
      final fields = formatFields;
      if (fields == null) throw const FormatException('ASS dialogue appears before its event format.');
      final colonIndex = line.indexOf(':');
      final values = _splitAssFields(line.substring(colonIndex + 1), fields.length);
      final start = _parseAssTime(values[fields.indexOf('start')].trim());
      final end = _parseAssTime(values[fields.indexOf('end')].trim());
      if (start == null || end == null) {
        throw const FormatException('ASS cue contains an invalid timestamp.');
      }
      if (end <= start) throw const FormatException('ASS cue end must be after its start.');
      final text = values[fields.indexOf('text')].trim();
      if (text.isEmpty) continue;
      if (cues.length >= maximumCueCount) {
        throw const FormatException('Subtitle has more cues than the 50000 cue processing bound.');
      }
      cues.add(SubtitleCue(index: cues.length + 1, startMs: start, endMs: end, text: text));
    }
    if (cues.isEmpty) throw const FormatException('No text subtitle cues were found.');
    cues.sort((a, b) {
      final timeOrder = a.startMs.compareTo(b.startMs);
      return timeOrder != 0 ? timeOrder : a.index.compareTo(b.index);
    });
    return List.unmodifiable(cues);
  }

  static List<String> _splitAssFields(String line, int fieldCount) {
    if (fieldCount < 3) throw const FormatException('ASS event format has too few fields.');
    final values = <String>[];
    var start = 0;
    for (var field = 0; field < fieldCount - 1; field++) {
      final separator = line.indexOf(',', start);
      if (separator < 0) throw const FormatException('ASS dialogue does not match its event format.');
      values.add(line.substring(start, separator));
      start = separator + 1;
    }
    values.add(line.substring(start));
    return values;
  }

  static int? _parseAssTime(String value) {
    final match = _assTimeExpression.firstMatch(value);
    if (match == null) return null;
    final hours = int.tryParse(match.group(1)!);
    final minutes = int.tryParse(match.group(2)!);
    final seconds = int.tryParse(match.group(3)!);
    final centiseconds = int.tryParse(match.group(4)!);
    if (hours == null || minutes == null || seconds == null || centiseconds == null) return null;
    final timeMs = (((hours * 60 + minutes) * 60 + seconds) * 1000) + centiseconds * 10;
    if (timeMs > maximumTimeMs) {
      throw const FormatException('Subtitle timestamp is outside the supported range.');
    }
    return timeMs;
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
