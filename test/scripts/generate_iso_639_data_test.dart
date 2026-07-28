import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/generate_iso_639_data.dart';

void main() {
  late String validSource;

  setUpAll(() async {
    validSource = await File(defaultIso639Input).readAsString();
  });

  test('parse and render are deterministic and reproduce the checked-in artifact', () async {
    final first = renderIso639Data(parseIso639Catalog(validSource));
    final second = renderIso639Data(parseIso639Catalog(validSource));

    expect(second, first);
    expect(first, await File(defaultIso639Output).readAsString());
  });

  test('rejects invalid schema, keys, primary consistency, names, and field shapes', () {
    _expectInvalid(validSource, (catalog) => catalog['schemaVersion'] = 2);
    _expectInvalid(validSource, (catalog) => catalog['languages'] = <String, Object?>{});
    _expectInvalid(validSource, (catalog) => _entry(catalog, 'aa')['primary'] = 'ab');
    _expectInvalid(validSource, (catalog) => _entry(catalog, 'aa')['terminology'] = 'AAR');
    _expectInvalid(validSource, (catalog) => _entry(catalog, 'bo')['bibliographic'] = 'TIB');
    _expectInvalid(validSource, (catalog) => _entry(catalog, 'aa')['name'] = '  ');

    _expectInvalid(validSource, (catalog) {
      final languages = _languages(catalog);
      languages['a'] = languages.remove('aa');
    });
  });

  test('rejects duplicate aliases and noncanonical primary ordering', () {
    _expectInvalid(
      validSource,
      (catalog) => _entry(catalog, 'ab')['terminology'] = _entry(catalog, 'aa')['terminology'],
    );
    _expectInvalid(
      validSource,
      (catalog) => _entry(catalog, 'bo')['bibliographic'] = _entry(catalog, 'aa')['terminology'],
    );
    _expectInvalid(validSource, (catalog) {
      final languages = _languages(catalog);
      final first = languages.remove('aa');
      languages['aa'] = first;
    });
  });

  test('escapes controls in names that require double-quoted Dart literals', () {
    const catalog = Iso639Catalog(
      entries: [Iso639CatalogEntry(primary: 'aa', terminology: 'aaa', bibliographic: null, name: "People's\nLanguage")],
    );

    expect(renderIso639Data(catalog), contains("\"People's\\nLanguage\""));
  });

  test('invalid input fails before the existing output is replaced', () async {
    final directory = await Directory.systemTemp.createTemp('plezy_iso_generator_test.');
    addTearDown(() => directory.delete(recursive: true));
    final input = File('${directory.path}/invalid.json');
    final output = File('${directory.path}/output.dart');
    await input.writeAsString('{"schemaVersion":1,"languages":{}}');
    await output.writeAsString('sentinel');

    await expectLater(generateIso639Data(input.path, output.path), throwsA(isA<FormatException>()));
    expect(await output.readAsString(), 'sentinel');
  });

  test('atomic writer replaces the complete destination', () async {
    final directory = await Directory.systemTemp.createTemp('plezy_iso_atomic_test.');
    addTearDown(() => directory.delete(recursive: true));
    final output = File('${directory.path}/output.dart');
    await output.writeAsString('old');

    await writeFileAtomically(output.path, 'new bytes\n');

    expect(await output.readAsString(), 'new bytes\n');
    expect(directory.listSync().where((entry) => entry.path.contains('.tmp.')), isEmpty);
  });
}

void _expectInvalid(String source, void Function(Map<String, Object?> catalog) mutate) {
  final catalog = (jsonDecode(source) as Map).cast<String, Object?>();
  mutate(catalog);
  expect(() => parseIso639Catalog(jsonEncode(catalog)), throwsA(isA<FormatException>()));
}

Map<String, Object?> _languages(Map<String, Object?> catalog) {
  return (catalog['languages']! as Map).cast<String, Object?>();
}

Map<String, Object?> _entry(Map<String, Object?> catalog, String code) {
  return (_languages(catalog)[code]! as Map).cast<String, Object?>();
}
