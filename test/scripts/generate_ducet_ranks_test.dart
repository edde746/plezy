import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../scripts/generate_ducet_ranks.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('plezy_ducet_test_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });


  test('bundled gzip inputs have deterministic normalized headers and bytes', () {
    final allKeys = File('scripts/data/${allKeysSource.bundledFileName}').readAsBytesSync();
    final fractional = File('scripts/data/${fractionalUcaSource.bundledFileName}').readAsBytesSync();

    expect(allKeys.take(8), [0x1F, 0x8B, 0x08, 0, 0, 0, 0, 0]);
    expect(fractional.take(8), [0x1F, 0x8B, 0x08, 0, 0, 0, 0, 0]);
    expect(sha256.convert(allKeys).toString(), '744040b99e266f9ec599744e267091c159369a36f6ca7558c12a9eb3e039575f');
    expect(sha256.convert(fractional).toString(), 'edc486bae663abf83d18c9006d08c1e8bb19986810cf8ab663fa33bee6d22275');
  });

  test('dense lookup stores rank plus one with a zero sentinel', () {
    final ranks = buildDenseRankLookup([0x41, 0x24, 0x5C]);

    expect(ranks.length, 0x10000);
    expect(ranks.codeUnitAt(0x41), 1);
    expect(ranks.codeUnitAt(0x24), 2);
    expect(ranks.codeUnitAt(0x5C), 3);
    expect(ranks.codeUnitAt(0x42), 0);
  });

  test('dense lookup rejects duplicate, out-of-BMP, and overflowing orders', () {
    expect(() => buildDenseRankLookup([0x41, 0x41]), throwsStateError);
    expect(() => buildDenseRankLookup([-1]), throwsRangeError);
    expect(() => buildDenseRankLookup([0x10000]), throwsRangeError);
    expect(() => buildDenseRankLookup(List<int>.generate(0x10000, (index) => index)), throwsStateError);
  });

  test('parse and render seams are deterministic and escape Dart interpolation characters', () {
    const allKeysText = '''
0041 ; [.0100.0020.0002]
30A2 ; [.0200.0020.000F]
3042 ; [.0200.0020.000D]
''';
    const fractionalText = '[radical 1=⼀一:一丁]';

    final firstAllKeys = parseAllKeys(allKeysText);
    final secondAllKeys = parseAllKeys(allKeysText);
    final (firstCjk, firstKangxi) = parseRadicals(fractionalText);
    final (secondCjk, secondKangxi) = parseRadicals(fractionalText);
    final firstOrder = buildOrder(firstAllKeys, firstCjk);
    final secondOrder = buildOrder(secondAllKeys, secondCjk);

    expect(firstOrder, secondOrder);
    expect(renderDucetOrder(firstOrder, firstKangxi), renderDucetOrder(secondOrder, secondKangxi));

    final ranksWithSpecialCodeUnits = List<int>.generate(0x5C, (index) => 0x1000 + index);
    final rendered = renderDucetOrder(ranksWithSpecialCodeUnits, const {});
    expect(rendered, contains(r"\'"));
    expect(rendered, contains(r'\\'));
    expect(rendered, contains(r'\$'));
  });

  test('explicit inputs are both verified before parsing and writing', () async {
    const allKeysText = '0041 ; [.0100.0020.0002]\n';
    const fractionalText = '[radical 1=⼀一:一]\n';
    final allKeysFile = File('${temporaryDirectory.path}/allkeys.txt')..writeAsStringSync(allKeysText);
    final fractionalFile = File('${temporaryDirectory.path}/FractionalUCA.txt')..writeAsStringSync(fractionalText);
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');
    var downloads = 0;

    await generateDucetRanks(
      useBundledSources: false,
      explicitAllKeys: allKeysFile,
      explicitFractionalUca: fractionalFile,
      output: output,
      allKeysDescriptor: descriptorFor('allkeys', allKeysText),
      fractionalUcaDescriptor: descriptorFor('fractional', fractionalText),
      downloader: (_) async {
        downloads++;
        throw StateError('network must not be used');
      },
    );

    expect(downloads, 0);
    expect(output.readAsStringSync(), contains('const String _ducetRanks ='));
    expect(output.readAsStringSync(), isNot(contains('_buildRanks')));
  });

  test('rejects an explicit digest mismatch without replacing output', () async {
    final allKeysFile = File('${temporaryDirectory.path}/allkeys.txt')..writeAsStringSync('tampered');
    final fractionalFile = File('${temporaryDirectory.path}/FractionalUCA.txt')..writeAsStringSync('fractional');
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');
    var writerCalled = false;

    await expectLater(
      generateDucetRanks(
        useBundledSources: false,
        explicitAllKeys: allKeysFile,
        explicitFractionalUca: fractionalFile,
        output: output,
        allKeysDescriptor: descriptorFor('allkeys', 'expected'),
        fractionalUcaDescriptor: descriptorFor('fractional', 'fractional'),
        writer: (_, _) => writerCalled = true,
      ),
      throwsA(isA<SourceIntegrityException>()),
    );

    expect(writerCalled, isFalse);
    expect(output.readAsStringSync(), 'old output');
    expect(allKeysFile.readAsStringSync(), 'tampered');
  });

  test('rejects an invalid cached source without downloading or replacing files', () async {
    final cache = Directory('${temporaryDirectory.path}/cache')..createSync();
    final allKeysDescriptor = descriptorFor('allkeys', 'expected allkeys');
    final fractionalDescriptor = descriptorFor('fractional', 'fractional');
    final cachedAllKeys = File('${cache.path}/${allKeysDescriptor.cacheFileName}')..writeAsStringSync('tampered cache');
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');
    var downloads = 0;

    await expectLater(
      generateDucetRanks(
        useBundledSources: false,
        cacheDirectory: cache,
        output: output,
        allKeysDescriptor: allKeysDescriptor,
        fractionalUcaDescriptor: fractionalDescriptor,
        downloader: (_) async {
          downloads++;
          return response(HttpStatus.ok, utf8.encode('unused'));
        },
      ),
      throwsA(isA<SourceIntegrityException>()),
    );

    expect(downloads, 0);
    expect(cachedAllKeys.readAsStringSync(), 'tampered cache');
    expect(output.readAsStringSync(), 'old output');
  });

  test('rejects HTTP status before parsing, caching, or replacing output', () async {
    final cache = Directory('${temporaryDirectory.path}/cache')..createSync();
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');

    await expectLater(
      generateDucetRanks(
        useBundledSources: false,
        cacheDirectory: cache,
        output: output,
        allKeysDescriptor: descriptorFor('allkeys', 'allkeys'),
        fractionalUcaDescriptor: descriptorFor('fractional', 'fractional'),
        downloader: (_) async => response(HttpStatus.notFound, utf8.encode('not found')),
      ),
      throwsA(isA<SourceIntegrityException>().having((error) => error.message, 'message', contains('HTTP 404'))),
    );

    expect(cache.listSync(), isEmpty);
    expect(output.readAsStringSync(), 'old output');
  });

  test('a rejected second download preserves the first cache and output', () async {
    const allKeysText = '0041 ; [.0100.0020.0002]\n';
    const fractionalText = '[radical 1=⼀一:一]\n';
    final cache = Directory(path.join(temporaryDirectory.path, 'cache'))..createSync();
    final marker = File(path.join(cache.path, 'marker'))..writeAsStringSync('keep');
    final output = File(path.join(temporaryDirectory.path, 'ducet_order.dart'))..writeAsStringSync('old output');
    var request = 0;

    await expectLater(
      generateDucetRanks(
        useBundledSources: false,
        cacheDirectory: cache,
        output: output,
        allKeysDescriptor: descriptorFor('allkeys', allKeysText),
        fractionalUcaDescriptor: descriptorFor('fractional', fractionalText),
        downloader: (_) async {
          request++;
          return response(HttpStatus.ok, utf8.encode(request == 1 ? allKeysText : 'tampered fractional'));
        },
      ),
      throwsA(isA<SourceIntegrityException>()),
    );

    expect(request, 2);
    expect(cache.listSync().map((entity) => path.basename(entity.path)).toList(), ['marker']);
    expect(marker.readAsStringSync(), 'keep');
    expect(output.readAsStringSync(), 'old output');
  });

  test('parse rejection leaves verified inputs, caches, and output untouched', () async {
    const duplicateAllKeys = '''
0041 ; [.0100.0020.0002]
0041 ; [.0101.0020.0002]
''';
    const fractionalText = '[radical 1=⼀一:一]\n';
    final allKeysFile = File(path.join(temporaryDirectory.path, 'allkeys.txt'))..writeAsStringSync(duplicateAllKeys);
    final fractionalFile = File(path.join(temporaryDirectory.path, 'FractionalUCA.txt'))
      ..writeAsStringSync(fractionalText);
    final cache = Directory(path.join(temporaryDirectory.path, 'cache'))..createSync();
    final marker = File(path.join(cache.path, 'marker'))..writeAsStringSync('keep');
    final output = File(path.join(temporaryDirectory.path, 'ducet_order.dart'))..writeAsStringSync('old output');

    await expectLater(
      generateDucetRanks(
        useBundledSources: false,
        explicitAllKeys: allKeysFile,
        explicitFractionalUca: fractionalFile,
        cacheDirectory: cache,
        output: output,
        allKeysDescriptor: descriptorFor('allkeys', duplicateAllKeys),
        fractionalUcaDescriptor: descriptorFor('fractional', fractionalText),
      ),
      throwsFormatException,
    );

    expect(allKeysFile.readAsStringSync(), duplicateAllKeys);
    expect(fractionalFile.readAsStringSync(), fractionalText);
    expect(cache.listSync().map((entity) => path.basename(entity.path)).toList(), ['marker']);
    expect(marker.readAsStringSync(), 'keep');
    expect(output.readAsStringSync(), 'old output');
  });

  test('default bundled generation is deterministic and never downloads', () async {
    final output = File('${temporaryDirectory.path}/ducet_order.dart');
    var downloads = 0;
    String? first;
    String? second;
    Future<SourceDownloadResponse> failDownloader(Uri _) async {
      downloads++;
      throw StateError('bundled generation must not use the network');
    }

    await generateDucetRanks(output: output, downloader: failDownloader, writer: (_, contents) => first = contents);
    await generateDucetRanks(output: output, downloader: failDownloader, writer: (_, contents) => second = contents);

    expect(downloads, 0);
    expect(first, isNotNull);
    expect(second, first);
    expect(first, File('lib/data/ducet_order.dart').readAsStringSync());
  });

  test('tampered bundled gzip fails before replacing output', () async {
    const allKeysText = '0041 ; [.0100.0020.0002]\n';
    const fractionalText = '[radical 1=⼀一:一]\n';
    final bundled = Directory('${temporaryDirectory.path}/bundled')..createSync();
    final allKeysDescriptor = descriptorFor('allkeys', allKeysText);
    final fractionalDescriptor = descriptorFor('fractional', fractionalText);
    File('${bundled.path}/${allKeysDescriptor.bundledFileName}').writeAsBytesSync(const [0x1F, 0x8B, 0x08, 0x00, 0x00]);
    writeBundledSource(bundled, fractionalDescriptor, fractionalText);
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');

    await expectLater(
      generateDucetRanks(
        bundledSourceDirectory: bundled,
        output: output,
        allKeysDescriptor: allKeysDescriptor,
        fractionalUcaDescriptor: fractionalDescriptor,
      ),
      throwsA(isA<SourceIntegrityException>()),
    );

    expect(output.readAsStringSync(), 'old output');
  });

  test('tampered decompressed bundled bytes fail digest before replacing output', () async {
    const allKeysText = '0041 ; [.0100.0020.0002]\n';
    const fractionalText = '[radical 1=⼀一:一]\n';
    final bundled = Directory('${temporaryDirectory.path}/bundled')..createSync();
    final allKeysDescriptor = descriptorFor('allkeys', allKeysText);
    final fractionalDescriptor = descriptorFor('fractional', fractionalText);
    writeBundledSource(bundled, allKeysDescriptor, 'tampered raw bytes');
    writeBundledSource(bundled, fractionalDescriptor, fractionalText);
    final output = File('${temporaryDirectory.path}/ducet_order.dart')..writeAsStringSync('old output');

    await expectLater(
      generateDucetRanks(
        bundledSourceDirectory: bundled,
        output: output,
        allKeysDescriptor: allKeysDescriptor,
        fractionalUcaDescriptor: fractionalDescriptor,
      ),
      throwsA(
        isA<SourceIntegrityException>().having((error) => error.message, 'message', contains('SHA-256 mismatch')),
      ),
    );

    expect(output.readAsStringSync(), 'old output');
  });
}

SourceDescriptor descriptorFor(String name, String contents) => SourceDescriptor(
  name: name,
  url: 'https://example.test/$name',
  bundledFileName: '$name.txt.gz',
  cacheFileName: '$name.txt',
  sha256Digest: sha256.convert(utf8.encode(contents)).toString(),
  licenseUrl: 'https://example.test/license',
);

void writeBundledSource(Directory directory, SourceDescriptor descriptor, String contents) {
  File('${directory.path}/${descriptor.bundledFileName}').writeAsBytesSync(gzip.encode(utf8.encode(contents)));
}

SourceDownloadResponse response(int statusCode, List<int> bytes) =>
    SourceDownloadResponse(statusCode: statusCode, bytes: Stream<List<int>>.value(bytes));
