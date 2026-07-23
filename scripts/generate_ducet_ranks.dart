/// Generates lib/data/ducet_order.dart from pinned Unicode and CLDR data.
///
/// Usage:
///   dart run scripts/generate_ducet_ranks.dart [allkeys.txt] [FractionalUCA.txt]
///
/// Default generation uses tracked deterministic gzip copies of the pinned source bytes.
/// Unicode data is redistributed unmodified under the Unicode License v3.
/// Explicit/cache/download inputs remain available for integrity and HTTP failure testing.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

final class SourceDescriptor {
  const SourceDescriptor({
    required this.name,
    required this.url,
    required this.bundledFileName,
    required this.cacheFileName,
    required this.sha256Digest,
    required this.licenseUrl,
  });

  final String name;
  final String url;
  final String bundledFileName;
  final String cacheFileName;
  final String sha256Digest;
  final String licenseUrl;
}

const allKeysSource = SourceDescriptor(
  name: 'Unicode 13.0 allkeys',
  url: 'https://www.unicode.org/Public/UCA/13.0.0/allkeys.txt',
  bundledFileName: 'allkeys-13.0.0.txt.gz',
  cacheFileName: 'plezy-allkeys-13.0.0-a3255d45b7af97f4dc14fb8364d7573b434425e5c58cacf00d16901ce081c78d.txt',
  sha256Digest: 'a3255d45b7af97f4dc14fb8364d7573b434425e5c58cacf00d16901ce081c78d',
  licenseUrl: 'https://www.unicode.org/license.txt',
);

const fractionalUcaSource = SourceDescriptor(
  name: 'CLDR FractionalUCA at 651afecf9ccf1541a49306993e8210fa2209aa0b',
  url:
      'https://raw.githubusercontent.com/unicode-org/cldr/651afecf9ccf1541a49306993e8210fa2209aa0b/common/uca/FractionalUCA.txt',
  bundledFileName: 'FractionalUCA-651afecf9ccf1541a49306993e8210fa2209aa0b.txt.gz',
  cacheFileName:
      'plezy-FractionalUCA-651afecf9ccf1541a49306993e8210fa2209aa0b-'
      'a6144d0c8c19cc899a5d2f48fbc14e3e31e819049a73aa86b67111f1f3f81637.txt',
  sha256Digest: 'a6144d0c8c19cc899a5d2f48fbc14e3e31e819049a73aa86b67111f1f3f81637',
  licenseUrl: 'https://github.com/unicode-org/cldr/blob/651afecf9ccf1541a49306993e8210fa2209aa0b/LICENSE',
);

final class SourceDownloadResponse {
  const SourceDownloadResponse({required this.statusCode, required this.bytes, this.close});

  final int statusCode;
  final Stream<List<int>> bytes;
  final void Function()? close;
}

typedef SourceDownloader = Future<SourceDownloadResponse> Function(Uri uri);
typedef GeneratedFileWriter = void Function(File output, String contents);

final class SourceIntegrityException implements Exception {
  const SourceIntegrityException(this.message);

  final String message;

  @override
  String toString() => 'SourceIntegrityException: $message';
}

final class VerifiedSourceBundle {
  VerifiedSourceBundle({
    required this.allKeysFile,
    required this.fractionalUcaFile,
    required this._stagingDirectory,
    required this._stagedCacheFiles,
  });

  final File allKeysFile;
  final File fractionalUcaFile;
  final Directory _stagingDirectory;
  final Map<File, File> _stagedCacheFiles;

  void commitCaches() {
    for (final entry in _stagedCacheFiles.entries) {
      final staged = entry.key;
      final cache = entry.value;
      cache.parent.createSync(recursive: true);
      staged.renameSync(cache.path);
    }
    _stagedCacheFiles.clear();
  }

  void dispose() {
    if (_stagingDirectory.existsSync()) {
      _stagingDirectory.deleteSync(recursive: true);
    }
  }
}

Future<SourceDownloadResponse> downloadSource(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'Plezy DUCET generator');
    final response = await request.close();
    return SourceDownloadResponse(
      statusCode: response.statusCode,
      bytes: response,
      close: () => client.close(force: true),
    );
  } catch (_) {
    client.close(force: true);
    rethrow;
  }
}

Future<String> sha256ForFile(File file) async => (await sha256.bind(file.openRead()).first).toString();

Future<void> verifySourceFile(File file, SourceDescriptor descriptor) async {
  if (!await file.exists()) {
    throw SourceIntegrityException('${descriptor.name} is missing: ${file.path}');
  }
  final actualDigest = await sha256ForFile(file);
  if (actualDigest != descriptor.sha256Digest) {
    throw SourceIntegrityException(
      '${descriptor.name} SHA-256 mismatch: expected ${descriptor.sha256Digest}, got $actualDigest',
    );
  }
}

Future<VerifiedSourceBundle> loadBundledSources({
  required Directory bundledSourceDirectory,
  SourceDescriptor allKeysDescriptor = allKeysSource,
  SourceDescriptor fractionalUcaDescriptor = fractionalUcaSource,
}) async {
  final staging = await Directory.systemTemp.createTemp('plezy_ducet_bundled_');

  Future<File> decompressAndVerify(SourceDescriptor descriptor) async {
    final compressed = File.fromUri(bundledSourceDirectory.uri.resolve(descriptor.bundledFileName));
    if (!await compressed.exists()) {
      throw SourceIntegrityException('${descriptor.name} bundled source is missing: ${compressed.path}');
    }
    final decompressed = File.fromUri(staging.uri.resolve('${descriptor.bundledFileName}.raw'));
    try {
      await compressed.openRead().transform(gzip.decoder).pipe(decompressed.openWrite());
    } catch (error) {
      throw SourceIntegrityException('${descriptor.name} bundled gzip is invalid: $error');
    }
    await verifySourceFile(decompressed, descriptor);
    return decompressed;
  }

  try {
    final allKeys = await decompressAndVerify(allKeysDescriptor);
    final fractionalUca = await decompressAndVerify(fractionalUcaDescriptor);
    return VerifiedSourceBundle(
      allKeysFile: allKeys,
      fractionalUcaFile: fractionalUca,
      stagingDirectory: staging,
      stagedCacheFiles: <File, File>{},
    );
  } catch (_) {
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    rethrow;
  }
}

Future<VerifiedSourceBundle> loadVerifiedSources({
  File? explicitAllKeys,
  File? explicitFractionalUca,
  Directory? cacheDirectory,
  SourceDownloader downloader = downloadSource,
  SourceDescriptor allKeysDescriptor = allKeysSource,
  SourceDescriptor fractionalUcaDescriptor = fractionalUcaSource,
}) async {
  final cacheRoot = cacheDirectory ?? Directory.systemTemp;
  final staging = await Directory.systemTemp.createTemp('plezy_ducet_sources_');
  final stagedCacheFiles = <File, File>{};

  Future<File> resolve(SourceDescriptor descriptor, File? explicit) async {
    if (explicit != null) {
      await verifySourceFile(explicit, descriptor);
      return explicit;
    }

    final cache = File.fromUri(cacheRoot.uri.resolve(descriptor.cacheFileName));
    if (await cache.exists()) {
      await verifySourceFile(cache, descriptor);
      return cache;
    }

    final staged = File.fromUri(staging.uri.resolve(descriptor.cacheFileName));
    final response = await downloader(Uri.parse(descriptor.url));
    try {
      if (response.statusCode != HttpStatus.ok) {
        throw SourceIntegrityException('${descriptor.name} download returned HTTP ${response.statusCode}');
      }
      await response.bytes.pipe(staged.openWrite());
    } finally {
      response.close?.call();
    }
    await verifySourceFile(staged, descriptor);
    stagedCacheFiles[staged] = cache;
    return staged;
  }

  try {
    final allKeys = await resolve(allKeysDescriptor, explicitAllKeys);
    final fractionalUca = await resolve(fractionalUcaDescriptor, explicitFractionalUca);
    return VerifiedSourceBundle(
      allKeysFile: allKeys,
      fractionalUcaFile: fractionalUca,
      stagingDirectory: staging,
      stagedCacheFiles: stagedCacheFiles,
    );
  } catch (_) {
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
    rethrow;
  }
}

class Weight implements Comparable<Weight> {
  final List<(int, int, int)> levels;
  final int codepoint;

  const Weight(this.levels, this.codepoint);

  @override
  int compareTo(Weight other) {
    final len = levels.length < other.levels.length ? levels.length : other.levels.length;
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$1.compareTo(other.levels[i].$1);
      if (cmp != 0) return cmp;
    }
    if (levels.length != other.levels.length) {
      return levels.length.compareTo(other.levels.length);
    }
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$2.compareTo(other.levels[i].$2);
      if (cmp != 0) return cmp;
    }
    for (var i = 0; i < len; i++) {
      final cmp = levels[i].$3.compareTo(other.levels[i].$3);
      if (cmp != 0) return cmp;
    }
    return codepoint.compareTo(other.codepoint);
  }
}

bool _isKatakana(int cp) =>
    (cp >= 0x30A0 && cp <= 0x30FF) || (cp >= 0x31F0 && cp <= 0x31FF) || (cp >= 0xFF65 && cp <= 0xFF9F);

Map<int, Weight> parseAllKeys(String text) {
  final result = <int, Weight>{};
  final weightRe = RegExp(r'\[([.*])([0-9A-Fa-f]{4})\.([0-9A-Fa-f]{4})\.([0-9A-Fa-f]{4})\]');

  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('@')) continue;
    final semiIdx = trimmed.indexOf(';');
    if (semiIdx < 0) continue;
    final cpPart = trimmed.substring(0, semiIdx).trim();
    if (cpPart.contains(' ')) continue;
    final cp = int.tryParse(cpPart, radix: 16);
    if (cp == null || cp > 0xFFFF) continue;

    final matches = weightRe.allMatches(trimmed.substring(semiIdx + 1));
    if (matches.isEmpty) continue;
    final levels = <(int, int, int)>[];
    for (final match in matches) {
      final primary = int.parse(match.group(2)!, radix: 16);
      final secondary = int.parse(match.group(3)!, radix: 16);
      var tertiary = int.parse(match.group(4)!, radix: 16);
      if (_isKatakana(cp) && tertiary >= 0x000F) tertiary -= 6;
      levels.add((primary, secondary, tertiary));
    }
    if (levels.every((level) => level.$1 == 0 && level.$2 == 0 && level.$3 == 0)) continue;
    if (result.containsKey(cp)) {
      throw FormatException('Duplicate allkeys entry for U+${cp.toRadixString(16).padLeft(4, '0')}');
    }
    result[cp] = Weight(levels, cp);
  }
  return result;
}

(List<int>, Map<int, int>) parseRadicals(String text) {
  final order = <int>[];
  final kangxiDecomp = <int, int>{};
  final radicalRe = RegExp(r'^\[radical \d+');

  for (final line in text.split('\n')) {
    if (!radicalRe.hasMatch(line)) continue;
    final eqIdx = line.indexOf('=');
    final colonIdx = line.indexOf(':');
    if (eqIdx < 0 || colonIdx < 0 || colonIdx <= eqIdx) continue;
    final closeBracket = line.lastIndexOf(']');
    if (closeBracket < 0) continue;

    final headerChars = line.substring(eqIdx + 1, colonIdx).runes.toList();
    if (headerChars.length >= 2) {
      final kangxi = headerChars.first;
      final cjk = headerChars[1];
      if (kangxi >= 0x2F00 && kangxi <= 0x2FD5 && cjk <= 0xFFFF) {
        kangxiDecomp[kangxi] = cjk;
      }
    }

    final runes = line.substring(colonIdx + 1, closeBracket).runes.toList();
    var i = 0;
    while (i < runes.length) {
      final cp = runes[i];
      if (cp == 0x20) {
        i++;
        continue;
      }
      if (i + 2 < runes.length && runes[i + 1] == 0x2D) {
        final endCp = runes[i + 2];
        for (var value = cp; value <= endCp; value++) {
          if (value <= 0xFFFF) order.add(value);
        }
        i += 3;
        continue;
      }
      if (cp <= 0xFFFF) order.add(cp);
      i++;
    }
  }

  final seen = <int>{};
  return (order.where(seen.add).toList(), kangxiDecomp);
}

List<int> buildOrder(Map<int, Weight> allKeys, List<int> cjkRadicalOrder) {
  final entries = allKeys.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  final ordered = <int>[];
  final cjkSet = cjkRadicalOrder.toSet();
  var cjkInserted = false;

  for (final entry in entries) {
    if (cjkSet.contains(entry.key)) continue;
    if (!cjkInserted && entry.value.levels.isNotEmpty && entry.value.levels.first.$1 >= 0xFB00) {
      ordered.addAll(cjkRadicalOrder);
      cjkInserted = true;
    }
    ordered.add(entry.key);
  }
  if (!cjkInserted) ordered.addAll(cjkRadicalOrder);
  return ordered;
}

String buildDenseRankLookup(List<int> ordered) {
  if (ordered.length > 0xFFFF) {
    throw StateError('Rank table overflow: ${ordered.length} entries exceed 65535');
  }
  final ranks = List<int>.filled(0x10000, 0);
  for (var rank = 0; rank < ordered.length; rank++) {
    final codepoint = ordered[rank];
    if (codepoint < 0 || codepoint > 0xFFFF) {
      throw RangeError.range(codepoint, 0, 0xFFFF, 'codepoint');
    }
    if (ranks[codepoint] != 0) {
      throw StateError('Duplicate codepoint U+${codepoint.toRadixString(16).padLeft(4, '0')}');
    }
    ranks[codepoint] = rank + 1;
  }
  return String.fromCharCodes(ranks);
}

String _escapeCodeUnit(int codeUnit) {
  if (codeUnit == 0x27) return r"\'";
  if (codeUnit == 0x5C) return r'\\';
  if (codeUnit == 0x24) return r'\$';
  return '\\u${codeUnit.toRadixString(16).padLeft(4, '0')}';
}

String renderDucetOrder(List<int> ordered, Map<int, int> kangxiDecomp) {
  final denseRanks = buildDenseRankLookup(ordered);
  final buffer = StringBuffer()
    ..writeln('/// Dense BMP ranks per DUCET (Unicode 13.0) + pinned CLDR CJK radical-stroke.')
    ..writeln('/// Each code unit stores rank + 1; zero means absent.')
    ..writeln('/// Katakana sorts before hiragana (CLDR root tailoring).')
    ..writeln('/// Generated by scripts/generate_ducet_ranks.dart — do not edit.')
    ..writeln('library;')
    ..writeln()
    ..writeln('const String _ducetRanks =');
  const unitsPerLine = 128;
  for (var start = 0; start < denseRanks.length; start += unitsPerLine) {
    final end = start + unitsPerLine < denseRanks.length ? start + unitsPerLine : denseRanks.length;
    buffer.write("    '");
    for (var i = start; i < end; i++) {
      buffer.write(_escapeCodeUnit(denseRanks.codeUnitAt(i)));
    }
    buffer.writeln(start + unitsPerLine >= denseRanks.length ? "';" : "'");
  }

  buffer
    ..writeln()
    ..writeln('/// Kangxi Radicals (U+2F00-U+2FD5) → CJK Unified equivalents.')
    ..writeln('/// ICU decomposes these via NFD before collation.')
    ..writeln('const Map<int, int> _kangxiDecomp = {');
  final sortedKangxi = kangxiDecomp.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  for (final entry in sortedKangxi) {
    buffer.writeln(
      '  0x${entry.key.toRadixString(16).toUpperCase()}: '
      '0x${entry.value.toRadixString(16).toUpperCase()},',
    );
  }
  buffer
    ..writeln('};')
    ..writeln()
    ..writeln('/// Compare two characters using DUCET + CLDR ordering.')
    ..writeln('/// Decomposes Kangxi radicals to CJK equivalents before lookup.')
    ..writeln('/// Falls back to codepoint order for characters not in the table.')
    ..writeln('int ducetCompare(String a, String b) {')
    ..writeln('  var cpA = a.runes.first;')
    ..writeln('  var cpB = b.runes.first;')
    ..writeln('  cpA = _kangxiDecomp[cpA] ?? cpA;')
    ..writeln('  cpB = _kangxiDecomp[cpB] ?? cpB;')
    ..writeln('  final storedRankA = cpA <= 0xFFFF ? _ducetRanks.codeUnitAt(cpA) : 0;')
    ..writeln('  final storedRankB = cpB <= 0xFFFF ? _ducetRanks.codeUnitAt(cpB) : 0;')
    ..writeln('  final rankA = storedRankA == 0 ? 0x100000 + cpA : storedRankA - 1;')
    ..writeln('  final rankB = storedRankB == 0 ? 0x100000 + cpB : storedRankB - 1;')
    ..writeln('  return rankA.compareTo(rankB);')
    ..writeln('}');
  return buffer.toString();
}

void writeGeneratedFile(File output, String contents) {
  output.parent.createSync(recursive: true);
  final staged = File('${output.path}.$pid.tmp');
  try {
    staged.writeAsStringSync(contents, flush: true);
    staged.renameSync(output.path);
  } finally {
    if (staged.existsSync()) staged.deleteSync();
  }
}

Future<void> generateDucetRanks({
  bool useBundledSources = true,
  Directory? bundledSourceDirectory,
  File? explicitAllKeys,
  File? explicitFractionalUca,
  Directory? cacheDirectory,
  File? output,
  SourceDownloader downloader = downloadSource,
  GeneratedFileWriter writer = writeGeneratedFile,
  SourceDescriptor allKeysDescriptor = allKeysSource,
  SourceDescriptor fractionalUcaDescriptor = fractionalUcaSource,
}) async {
  final sources = useBundledSources
      ? await loadBundledSources(
          bundledSourceDirectory:
              bundledSourceDirectory ?? Directory.fromUri(Directory.current.uri.resolve('scripts/data/')),
          allKeysDescriptor: allKeysDescriptor,
          fractionalUcaDescriptor: fractionalUcaDescriptor,
        )
      : await loadVerifiedSources(
          explicitAllKeys: explicitAllKeys,
          explicitFractionalUca: explicitFractionalUca,
          cacheDirectory: cacheDirectory,
          downloader: downloader,
          allKeysDescriptor: allKeysDescriptor,
          fractionalUcaDescriptor: fractionalUcaDescriptor,
        );
  try {
    final allKeys = parseAllKeys(await sources.allKeysFile.readAsString());
    final (cjkOrder, kangxiDecomp) = parseRadicals(await sources.fractionalUcaFile.readAsString());
    final ordered = buildOrder(allKeys, cjkOrder);
    final rendered = renderDucetOrder(ordered, kangxiDecomp);
    sources.commitCaches();
    writer(output ?? File.fromUri(Directory.current.uri.resolve('lib/data/ducet_order.dart')), rendered);
  } finally {
    sources.dispose();
  }
}

Future<void> main(List<String> args) async {
  if (args.length > 2) {
    stderr.writeln('Usage: dart run scripts/generate_ducet_ranks.dart [allkeys.txt] [FractionalUCA.txt]');
    exitCode = 64;
    return;
  }
  try {
    await generateDucetRanks(
      explicitAllKeys: args.isNotEmpty ? File(args.first) : null,
      explicitFractionalUca: args.length > 1 ? File(args[1]) : null,
      useBundledSources: args.isEmpty,
    );
    stderr.writeln('Written to ${File.fromUri(Directory.current.uri.resolve('lib/data/ducet_order.dart')).path}');
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
