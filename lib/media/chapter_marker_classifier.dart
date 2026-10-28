import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One chapter as the classifier sees it: its title and its resolved span in milliseconds, `endMs >= startMs`.
typedef ChapterSpan = ({String? title, int startMs, int endMs});

/// The chapters the classifier marked, as indices into the spans it was given.
typedef ChapterMarkerPicks = ({int? intro, int? credits});

/// Picks an item's intro and credits chapter from its chapter list alone: titles plus start/end times.
///
/// A boosted-tree ensemble trained by `scripts/codegen/train_chapter_marker_model.py` scores every chapter as
/// other/intro/credits from 48 numbers: where the chapter sits and how long it and its neighbours run, whether its
/// title is generic ("Chapter 3", a timestamp, empty), intro/credits keywords in its own and its neighbours'
/// titles, and a 24-number embedding of its title's character n-grams. Timing lets it find the 90-second OP of an
/// episode whose chapters are all "Chapter N"; context lets it pass over a cold open titled "Intro" that comes
/// before an explicit "OP".
///
/// The feature code mirrors the training script line for line. `test/media/chapter_marker_model_cases.dart`
/// holds the script's own probabilities for synthetic inputs, so any drift between the two fails a test.
class ChapterMarkerClassifier {
  /// The bundled model, loaded from `assets/chapter_marker_model.bin` and decoded on first use. Callers await this
  /// once per load of playback extras and pass the classifier to `PlaybackExtras.withChapterFallback`.
  static final Future<ChapterMarkerClassifier> bundled = rootBundle
      .load('assets/chapter_marker_model.bin')
      .then((data) => ChapterMarkerClassifier.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));

  /// Minimum probability for a pick.
  static const threshold = 0.8;

  /// A chapter shorter than this is never a marker.
  static const minMarkerDuration = Duration(seconds: 5);

  /// A chapter longer than this is never an intro: detected intros fall well inside two minutes, while a movie's
  /// first chapter titled "Opening Credits" can run five to ten minutes of picture (#2235).
  static const maxIntroDuration = Duration(minutes: 3);

  static const _leaf = 0xFF;
  static const _other = 0, _intro = 1, _credits = 2;
  static const _titleFeatures = 24;

  final int _featureCount;
  final int _buckets;
  final int _embedDim;
  final Float64List _baseline;
  final Float64List _scale;
  final Float32List _idf;

  /// Projection rows of the buckets that have one, `_embedDim` values each. Every other bucket's row is all zeros.
  final Int8List _table;

  /// Per bucket, the offset of its row in [_table], or -1 for an all-zero row.
  final Int32List _tableRow;

  final Int32List _treeStarts;
  final Uint8List _nodeFeature;

  /// Split threshold for a split node, contribution for a leaf.
  final Float64List _nodeValue;
  final Int32List _nodeRight;

  ChapterMarkerClassifier._(
    this._featureCount,
    this._buckets,
    this._embedDim,
    this._baseline,
    this._scale,
    this._idf,
    this._table,
    this._tableRow,
    this._treeStarts,
    this._nodeFeature,
    this._nodeValue,
    this._nodeRight,
  );

  /// Reads the little-endian layout written by `serialize` in the training script.
  factory ChapterMarkerClassifier.decode(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var at = 0;
    int u8() => data.getUint8(at++);
    int u16() => data.getUint16((at += 2) - 2, Endian.little);
    int u32() => data.getUint32((at += 4) - 4, Endian.little);
    double f32() => data.getFloat32((at += 4) - 4, Endian.little);
    double f64() => data.getFloat64((at += 8) - 8, Endian.little);

    if (String.fromCharCodes(bytes, 0, 4) != 'PCM2') throw const FormatException('Not a chapter marker model');
    at = 4;
    final featureCount = u16();
    final buckets = u32();
    final embedDim = u8();
    final classes = u8();
    if (classes != 3 || featureCount != _titleFeatures + embedDim) {
      throw FormatException('Unsupported chapter marker model: $classes classes, $featureCount features');
    }
    final baseline = Float64List.fromList([for (var i = 0; i < classes; i++) f64()]);
    final scale = Float64List.fromList([for (var i = 0; i < embedDim; i++) f64()]);
    final idf = Float32List.fromList([for (var i = 0; i < buckets; i++) f32()]);
    final bitmap = Uint8List.sublistView(bytes, at, at + ((buckets + 7) >> 3));
    at += bitmap.length;
    final tableRow = Int32List(buckets);
    var rows = 0;
    for (var b = 0; b < buckets; b++) {
      tableRow[b] = (bitmap[b >> 3] >> (b & 7)) & 1 == 1 ? embedDim * rows++ : -1;
    }
    final table = Int8List.sublistView(bytes, at, at + rows * embedDim);
    at += table.length;
    final thresholds = [
      for (var f = 0; f < featureCount; f++) [for (var i = 0, n = u8(); i < n; i++) f64()],
    ];
    final treeCount = u16();
    final nodeCount = u32();
    final treeStarts = Int32List(treeCount);
    final nodeFeature = Uint8List(nodeCount);
    final nodeValue = Float64List(nodeCount);
    final nodeRight = Int32List(nodeCount);
    var node = 0;
    for (var t = 0; t < treeCount; t++) {
      final start = treeStarts[t] = node;
      for (var i = 0, n = u16(); i < n; i++, node++) {
        final feature = nodeFeature[node] = u8();
        if (feature == _leaf) {
          nodeValue[node] = f32();
        } else {
          nodeValue[node] = thresholds[feature][u8()];
          nodeRight[node] = start + u16();
        }
      }
    }
    if (node != nodeCount || at != bytes.length) throw const FormatException('Truncated chapter marker model');
    return ChapterMarkerClassifier._(
      featureCount,
      buckets,
      embedDim,
      baseline,
      scale,
      idf,
      table,
      tableRow,
      treeStarts,
      nodeFeature,
      nodeValue,
      nodeRight,
    );
  }

  /// The intro and credits chapters, if the model is confident: per type, the most probable chapter that passes
  /// [minMarkerDuration] (and [maxIntroDuration] for intros), when its probability reaches [threshold]. One
  /// chapter is never both.
  ChapterMarkerPicks pick(List<ChapterSpan> spans) {
    if (spans.isEmpty) return (intro: null, credits: null);
    final probs = probabilities(spans);
    for (var i = 0; i < spans.length; i++) {
      final duration = spans[i].endMs - spans[i].startMs;
      if (duration < minMarkerDuration.inMilliseconds) {
        probs[i][_intro] = 0;
        probs[i][_credits] = 0;
      } else if (duration > maxIntroDuration.inMilliseconds) {
        probs[i][_intro] = 0;
      }
    }
    int? best(int cls, int? taken) {
      var at = 0;
      for (var i = 1; i < probs.length; i++) {
        if (probs[i][cls] > probs[at][cls]) at = i;
      }
      return probs[at][cls] >= threshold && at != taken ? at : null;
    }

    final intro = best(_intro, null);
    return (intro: intro, credits: best(_credits, intro));
  }

  /// Per-chapter `[other, intro, credits]` probabilities, before the duration rules [pick] applies.
  @visibleForTesting
  List<Float64List> probabilities(List<ChapterSpan> spans) {
    final x = _features(spans);
    return [
      for (var i = 0; i < spans.length; i++)
        _softmax(_raw(Float32List.sublistView(x, i * _featureCount, (i + 1) * _featureCount))),
    ];
  }

  Float64List _raw(Float32List x) {
    final raw = Float64List.fromList(_baseline);
    for (var t = 0; t < _treeStarts.length; t++) {
      var i = _treeStarts[t];
      for (var f = _nodeFeature[i]; f != _leaf; f = _nodeFeature[i]) {
        i = x[f] <= _nodeValue[i] ? i + 1 : _nodeRight[i];
      }
      raw[t % raw.length] += _nodeValue[i];
    }
    return raw;
  }

  static Float64List _softmax(Float64List raw) {
    final top = raw.reduce(math.max);
    final out = Float64List.fromList([for (final r in raw) math.exp(r - top)]);
    final sum = out[_other] + out[_intro] + out[_credits];
    for (var k = 0; k < out.length; k++) {
      out[k] /= sum;
    }
    return out;
  }

  // ---- Features: mirror `features` in the training script. ----

  static final _whitespace = RegExp('[\t\n\v\f\r \u0085\u00a0\u1680\u2000-\u200a\u2028\u2029\u202f\u205f\u3000]+');
  static final _digit = RegExp('[0-9]');
  static final _introWords = RegExp(r'(?:^|\b)(?:intro(?:duction)?|opening)(?:\b|$)|^op(?: ?[0-9]+)?$');
  static final _creditsWords = RegExp(r'(?:^|\b)(?:outro|credits?|ending)(?:\b|$)|^ed(?: ?[0-9]+)?$');
  static const _gw =
      r'(?:(?:chapter|chapitre|kapitel|cap[ií]tulo|capitolo|hoofdstuk|глава|チャプター|scene|part) ?[#\-_.]? ?)?';
  static final _genericTitle = RegExp(
    '^$_gw[0-9]+(?: $_gw[0-9]+)*\$'
    r'|^(?:\([0-9]+\))? ?[0-9]{1,2}:[0-9]{2}(?::[0-9]{2})?(?:[.,:][0-9]+)?$'
    r'|^\(unnamed scene\)$|^(?:chapter)?$',
  );
  static final _logHour = math.log(3600);
  static final _log4Hours = math.log(4 * 3600);

  /// Fullwidth ASCII to ASCII, whitespace runs to one space, trimmed, lowercase.
  static String _clean(String? title) {
    if (title == null || title.isEmpty) return '';
    final ascii = String.fromCharCodes(title.runes.map((r) => r >= 0xFF01 && r <= 0xFF5E ? r - 0xFEE0 : r));
    final spaced = ascii.replaceAll(_whitespace, ' ');
    var start = 0, end = spaced.length;
    while (start < end && spaced.codeUnitAt(start) == 0x20) {
      start++;
    }
    while (end > start && spaced.codeUnitAt(end - 1) == 0x20) {
      end--;
    }
    return spaced.substring(start, end).toLowerCase();
  }

  /// Features rounded to float32 like the script's: split thresholds can sit exactly on a value that repeats in
  /// the training data, and the rounding absorbs last-bit differences in the arithmetic.
  Float32List _features(List<ChapterSpan> spans) {
    final n = spans.length;
    final runtime = math.max(spans.map((s) => s.endMs).reduce(math.max), 1);
    final titles = [for (final s in spans) _clean(s.title)];
    final keywords = [
      for (final t in titles) [_introWords.hasMatch(t) ? 1.0 : 0.0, _creditsWords.hasMatch(t) ? 1.0 : 0.0],
    ];
    final durations = [for (final s in spans) (s.endMs - s.startMs) / 1000];
    const none = [-1.0, -1.0];
    final x = Float32List(n * _featureCount);
    for (var i = 0; i < n; i++) {
      final s = spans[i].startMs, e = spans[i].endMs, d = durations[i], t = titles[i];
      final row = <double>[
        s / runtime,
        e / runtime,
        (e - s) / runtime,
        math.log(1 + d) / _logHour,
        math.min(s / 1000, 900.0) / 900,
        math.min((runtime - e) / 1000, 900.0) / 900,
        math.min((d - 90).abs(), 300.0) / 300,
        i / math.max(n - 1, 1),
        i == 0 ? 1 : 0,
        i == n - 1 ? 1 : 0,
        math.min(n, 40) / 40,
        math.log(1 + runtime / 1000) / _log4Hours,
        d >= 84 && d <= 96 ? 1 : 0,
        i > 0 ? math.min(durations[i - 1], 900.0) / 900 : -1,
        i + 1 < n ? math.min(durations[i + 1], 900.0) / 900 : -1,
        _genericTitle.hasMatch(t) ? 1 : 0,
        t.isEmpty ? 1 : 0,
        ...keywords[i],
        ...(i > 0 ? keywords[i - 1] : none),
        ...(i + 1 < n ? keywords[i + 1] : none),
        t.runes.length / 40,
      ];
      x.setAll(i * _featureCount, row);
      x.setAll(i * _featureCount + _titleFeatures, _embed(t));
    }
    return x;
  }

  /// Hashed n-gram counts -> idf weights -> L2 normalize -> int8 projection, summed in ascending bucket order
  /// like the script's sparse product. A bucket without a table row only adds to the norm.
  Float64List _embed(String cleaned) {
    final out = Float64List(_embedDim);
    final counts = _titleBuckets(cleaned);
    if (counts.isEmpty) return out;
    final buckets = counts.keys.toList()..sort();
    var squares = 0.0;
    for (final b in buckets) {
      final w = counts[b]! * _idf[b];
      squares += w * w;
    }
    final inverseNorm = 1 / math.sqrt(squares);
    for (final b in buckets) {
      final row = _tableRow[b];
      if (row < 0) continue;
      final w = counts[b]! * _idf[b] * inverseNorm;
      for (var k = 0; k < _embedDim; k++) {
        out[k] += w * (_table[row + k] * _scale[k]);
      }
    }
    return out;
  }

  /// Counts of FNV-1a-hashed 1-3 character n-grams of each space-padded word, digits folded to 0.
  Map<int, int> _titleBuckets(String cleaned) {
    final counts = <int, int>{};
    for (final word in cleaned.replaceAll(_digit, '0').split(' ')) {
      if (word.isEmpty) continue;
      final padded = <List<int>>[
        const [0x20],
        for (final r in word.runes) utf8.encode(String.fromCharCode(r)),
        const [0x20],
      ];
      for (var n = 1; n <= 3; n++) {
        for (var i = 0; i + n <= padded.length; i++) {
          var h = 0x811C9DC5;
          for (var k = i; k < i + n; k++) {
            for (final byte in padded[k]) {
              h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF;
            }
          }
          final bucket = h % _buckets;
          counts[bucket] = (counts[bucket] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
