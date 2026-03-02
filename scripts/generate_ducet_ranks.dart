/// Generates lib/data/ducet_order.dart from Unicode allkeys.txt and CLDR FractionalUCA.txt.
///
/// Usage:
///   dart run scripts/generate_ducet_ranks.dart [allkeys.txt] [FractionalUCA.txt]
///
/// Downloads the files automatically if not provided.
library;
import 'dart:io';

// ---------------------------------------------------------------------------
// Weight tuple for multi-level UCA comparison
// ---------------------------------------------------------------------------
class Weight implements Comparable<Weight> {
  final List<(int, int, int)> levels;
  final int codepoint; // tiebreaker

  const Weight(this.levels, this.codepoint);

  @override
  int compareTo(Weight other) {
    final len = levels.length < other.levels.length ? levels.length : other.levels.length;

    // Primary pass
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$1.compareTo(other.levels[i].$1);
      if (cmp != 0) return cmp;
    }
    if (levels.length != other.levels.length) {
      return levels.length.compareTo(other.levels.length);
    }

    // Secondary pass
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$2.compareTo(other.levels[i].$2);
      if (cmp != 0) return cmp;
    }

    // Tertiary pass
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$3.compareTo(other.levels[i].$3);
      if (cmp != 0) return cmp;
    }

    // Codepoint tiebreaker
    return codepoint.compareTo(other.codepoint);
  }
}

// ---------------------------------------------------------------------------
// Katakana codepoint ranges (for CLDR kana tertiary reversal)
// ---------------------------------------------------------------------------
bool _isKatakana(int cp) =>
    (cp >= 0x30A0 && cp <= 0x30FF) || // Katakana
    (cp >= 0x31F0 && cp <= 0x31FF) || // Katakana Phonetic Extensions
    (cp >= 0xFF65 && cp <= 0xFF9F); // Halfwidth Katakana

// ---------------------------------------------------------------------------
// Parse allkeys.txt → Map<codepoint, weight-tuples>
//
// CLDR kana fix: ICU/CLDR root collation sorts katakana before hiragana
// (opposite of raw DUCET). We adjust by subtracting 6 from katakana tertiary
// weights, placing them below hiragana tertiaries (0x000D+).
// ---------------------------------------------------------------------------
Map<int, Weight> parseAllKeys(String text) {
  final result = <int, Weight>{};
  final weightRe = RegExp(r'\[([.*])([0-9A-Fa-f]{4})\.([0-9A-Fa-f]{4})\.([0-9A-Fa-f]{4})\]');

  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('@')) continue;

    final semiIdx = trimmed.indexOf(';');
    if (semiIdx < 0) continue;

    final cpPart = trimmed.substring(0, semiIdx).trim();
    if (cpPart.contains(' ')) continue; // skip multi-codepoint

    final cp = int.tryParse(cpPart, radix: 16);
    if (cp == null || cp > 0xFFFF) continue; // BMP only

    final weightPart = trimmed.substring(semiIdx + 1);
    final matches = weightRe.allMatches(weightPart);
    if (matches.isEmpty) continue;

    final isKat = _isKatakana(cp);
    final levels = <(int, int, int)>[];
    for (final m in matches) {
      final p = int.parse(m.group(2)!, radix: 16);
      final s = int.parse(m.group(3)!, radix: 16);
      var t = int.parse(m.group(4)!, radix: 16);
      // CLDR kana fix: lower katakana tertiary below hiragana range
      if (isKat && t >= 0x000F) t -= 6;
      levels.add((p, s, t));
    }

    if (levels.every((l) => l.$1 == 0 && l.$2 == 0 && l.$3 == 0)) continue;

    result[cp] = Weight(levels, cp);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Parse FractionalUCA.txt radical lines → CJK codepoints in radical-stroke
// order, plus Kangxi radical → CJK decomposition map.
// ---------------------------------------------------------------------------
(List<int>, Map<int, int>) parseRadicals(String text) {
  final order = <int>[];
  final kangxiDecomp = <int, int>{}; // kangxi radical CP → CJK CP
  final radicalRe = RegExp(r'^\[radical \d+');

  for (final line in text.split('\n')) {
    if (!radicalRe.hasMatch(line)) continue;

    // Parse header: [radical N=<kangxi><cjk>:<char-list>]
    final eqIdx = line.indexOf('=');
    final colonIdx = line.indexOf(':');
    if (eqIdx < 0 || colonIdx < 0 || colonIdx <= eqIdx) continue;
    final closeBracket = line.lastIndexOf(']');
    if (closeBracket < 0) continue;

    // Extract Kangxi radical → CJK mapping from header
    final headerChars = line.substring(eqIdx + 1, colonIdx).runes.toList();
    if (headerChars.length >= 2) {
      final kangxi = headerChars.first;
      final cjk = headerChars[1];
      // Kangxi Radicals: U+2F00-U+2FD5
      if (kangxi >= 0x2F00 && kangxi <= 0x2FD5 && cjk <= 0xFFFF) {
        kangxiDecomp[kangxi] = cjk;
      }
    }

    // Parse character list after colon
    final charList = line.substring(colonIdx + 1, closeBracket);
    final runes = charList.runes.toList();
    var i = 0;
    while (i < runes.length) {
      final cp = runes[i];

      if (cp == 0x20) {
        i++;
        continue;
      }

      // Check for range: <char>-<char>
      if (i + 2 < runes.length && runes[i + 1] == 0x2D) {
        final endCp = runes[i + 2];
        for (var c = cp; c <= endCp; c++) {
          if (c <= 0xFFFF) order.add(c);
        }
        i += 3;
        continue;
      }

      if (cp <= 0xFFFF) order.add(cp);
      i++;
    }
  }

  // Deduplicate preserving order
  final seen = <int>{};
  final deduped = order.where((cp) => seen.add(cp)).toList();
  return (deduped, kangxiDecomp);
}

// ---------------------------------------------------------------------------
// Build final ordered list
// ---------------------------------------------------------------------------
List<int> buildOrder(Map<int, Weight> allKeys, List<int> cjkRadicalOrder) {
  final entries = allKeys.entries.toList();
  entries.sort((a, b) => a.value.compareTo(b.value));

  final ordered = <int>[];
  final cjkSet = cjkRadicalOrder.toSet();
  bool cjkInserted = false;

  for (final e in entries) {
    if (cjkSet.contains(e.key)) continue;

    if (!cjkInserted && e.value.levels.isNotEmpty && e.value.levels.first.$1 >= 0xFB00) {
      for (final cp in cjkRadicalOrder) {
        if (cp <= 0xFFFF) ordered.add(cp);
      }
      cjkInserted = true;
    }

    ordered.add(e.key);
  }

  if (!cjkInserted) {
    for (final cp in cjkRadicalOrder) {
      if (cp <= 0xFFFF) ordered.add(cp);
    }
  }

  return ordered;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------
Future<void> main(List<String> args) async {
  final allKeysPath = args.isNotEmpty ? args.first : '/tmp/allkeys.txt';
  final fracUcaPath = args.length > 1 ? args[1] : '/tmp/FractionalUCA.txt';

  // Download if missing
  if (!File(allKeysPath).existsSync()) {
    stderr.writeln('Downloading allkeys.txt...');
    final result = await Process.run('curl', [
      '-sL',
      'https://www.unicode.org/Public/UCA/13.0.0/allkeys.txt',
      '-o',
      allKeysPath,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln('Failed to download allkeys.txt');
      exit(1);
    }
  }

  if (!File(fracUcaPath).existsSync()) {
    stderr.writeln('Downloading FractionalUCA.txt...');
    final result = await Process.run('curl', [
      '-sL',
      'https://raw.githubusercontent.com/unicode-org/cldr/release-39/common/uca/FractionalUCA.txt',
      '-o',
      fracUcaPath,
    ]);
    if (result.exitCode != 0) {
      stderr.writeln('Failed to download FractionalUCA.txt');
      exit(1);
    }
  }

  stderr.writeln('Parsing allkeys.txt (with CLDR kana fix)...');
  final allKeysText = File(allKeysPath).readAsStringSync();
  final allKeys = parseAllKeys(allKeysText);
  stderr.writeln('  ${allKeys.length} BMP entries');

  stderr.writeln('Parsing FractionalUCA.txt...');
  final fracText = File(fracUcaPath).readAsStringSync();
  final (cjkOrder, kangxiDecomp) = parseRadicals(fracText);
  stderr.writeln('  ${cjkOrder.length} CJK codepoints in radical-stroke order');
  stderr.writeln('  ${kangxiDecomp.length} Kangxi radical decompositions');
  final bmpCjk = cjkOrder.where((cp) => cp <= 0xFFFF).length;
  stderr.writeln('  $bmpCjk BMP CJK codepoints');

  stderr.writeln('Building total order...');
  final ordered = buildOrder(allKeys, cjkOrder);
  stderr.writeln('  ${ordered.length} total BMP codepoints in order');

  stderr.writeln('  ${ordered.length * 2} raw bytes');

  // Generate Dart file — store codepoints as a raw UTF-16 string constant.
  // Each char IS the codepoint. Dart strings are UTF-16 natively, so the
  // compiled snapshot stores the data as raw 2-byte values with zero decoding.
  final outPath = '${Directory.current.path}/lib/data/ducet_order.dart';
  final buf = StringBuffer();
  buf.writeln('/// Sorted BMP codepoints per DUCET (Unicode 13.0) + CLDR 39 CJK radical-stroke.');
  buf.writeln('/// Katakana sorts before hiragana (CLDR root tailoring).');
  buf.writeln('/// Generated by scripts/generate_ducet_ranks.dart — do not edit.');
  buf.writeln();

  // Raw UTF-16 string — each code unit is a codepoint in DUCET order.
  // Use \uXXXX escapes so the source stays ASCII-safe.
  buf.write("const String _ducetOrder = '");
  for (var i = 0; i < ordered.length; i++) {
    final cp = ordered[i];
    if (cp == 0x27) {
      buf.write(r"\'"); // escape single quote
    } else if (cp == 0x5C) {
      buf.write(r'\\'); // escape backslash
    } else if (cp == 0x24) {
      buf.write(r'\$'); // escape dollar
    } else {
      buf.write('\\u${cp.toRadixString(16).padLeft(4, '0')}');
    }
  }
  buf.writeln("';");

  // Kangxi radical decomposition map
  buf.writeln();
  buf.writeln('/// Kangxi Radicals (U+2F00-U+2FD5) → CJK Unified equivalents.');
  buf.writeln('/// ICU decomposes these via NFD before collation.');
  buf.writeln('const Map<int, int> _kangxiDecomp = {');
  final sortedKangxi = kangxiDecomp.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final e in sortedKangxi) {
    buf.writeln('  0x${e.key.toRadixString(16).toUpperCase()}: 0x${e.value.toRadixString(16).toUpperCase()},');
  }
  buf.writeln('};');

  buf.writeln();
  buf.writeln('late final Map<int, int> _ranks = _buildRanks();');
  buf.writeln();
  buf.writeln('Map<int, int> _buildRanks() {');
  buf.writeln('  return {');
  buf.writeln('    for (var i = 0; i < _ducetOrder.length; i++)');
  buf.writeln('      _ducetOrder.codeUnitAt(i): i,');
  buf.writeln('  };');
  buf.writeln('}');
  buf.writeln();
  buf.writeln('/// Compare two characters using DUCET + CLDR ordering.');
  buf.writeln('/// Decomposes Kangxi radicals to CJK equivalents before lookup.');
  buf.writeln('/// Falls back to codepoint order for characters not in the table.');
  buf.writeln('int ducetCompare(String a, String b) {');
  buf.writeln('  var cpA = a.runes.first;');
  buf.writeln('  var cpB = b.runes.first;');
  buf.writeln('  cpA = _kangxiDecomp[cpA] ?? cpA;');
  buf.writeln('  cpB = _kangxiDecomp[cpB] ?? cpB;');
  buf.writeln('  final rankA = _ranks[cpA] ?? (0x100000 + cpA);');
  buf.writeln('  final rankB = _ranks[cpB] ?? (0x100000 + cpB);');
  buf.writeln('  return rankA.compareTo(rankB);');
  buf.writeln('}');

  File(outPath).writeAsStringSync(buf.toString());
  stderr.writeln('Written to $outPath');
}
