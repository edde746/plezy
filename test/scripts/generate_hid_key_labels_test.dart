import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/codegen/generate_hid_key_labels.dart';

void main() {
  late String validSource;

  setUpAll(() async {
    validSource = await File(defaultHidKeyLabelsInput).readAsString();
  });

  test('parse and render are deterministic and reproduce the checked-in artifact', () async {
    final first = renderHidKeyLabels(parseHidKeyLabelsCatalog(validSource));
    final second = renderHidKeyLabels(parseHidKeyLabelsCatalog(validSource));

    expect(second, first);
    expect(first, await File(defaultHidKeyLabelsOutput).readAsString());
  });

  test('rejects invalid schema, empty groups, group names, keys, labels, and IDs', () {
    _expectInvalid(validSource, (catalog) => catalog['schemaVersion'] = 2);
    _expectInvalid(validSource, (catalog) => catalog['groups'] = <Object?>[]);
    _expectInvalid(validSource, (catalog) => _group(catalog, 0)['name'] = '  ');
    _expectInvalid(validSource, (catalog) => _group(catalog, 0)['keys'] = <Object?>[]);
    _expectInvalid(validSource, (catalog) => _key(catalog, 0, 0)['label'] = '');
    _expectInvalid(validSource, (catalog) => _key(catalog, 0, 0)['id'] = '0000001');
    _expectInvalid(validSource, (catalog) => _key(catalog, 0, 0)['id'] = '0000001A');
  });

  test('rejects globally duplicate or noncanonical numeric IDs', () {
    _expectInvalid(validSource, (catalog) => _key(catalog, 0, 1)['id'] = _key(catalog, 0, 0)['id']);
    _expectInvalid(validSource, (catalog) => _key(catalog, 0, 1)['id'] = '0000000f');
    _expectInvalid(validSource, (catalog) => _key(catalog, 1, 0)['id'] = '0000000f');
  });

  test('escapes controls in labels that require double-quoted Dart literals', () {
    const catalog = HidKeyCatalog(
      groups: [
        HidKeyGroup(
          name: 'Test',
          keys: [HidKeyLabel(id: '00000001', label: "Player's\nKey")],
        ),
      ],
    );

    expect(renderHidKeyLabels(catalog), contains("\"Player's\\nKey\""));
  });

  test('invalid input fails before the existing output is replaced', () async {
    final directory = await Directory.systemTemp.createTemp('plezy_hid_generator_test.');
    addTearDown(() => directory.delete(recursive: true));
    final input = File('${directory.path}/invalid.json');
    final output = File('${directory.path}/output.dart');
    await input.writeAsString('{"schemaVersion":1,"groups":[]}');
    await output.writeAsString('sentinel');

    await expectLater(generateHidKeyLabels(input.path, output.path), throwsA(isA<FormatException>()));
    expect(await output.readAsString(), 'sentinel');
  });

  test('atomic writer replaces the complete destination', () async {
    final directory = await Directory.systemTemp.createTemp('plezy_hid_atomic_test.');
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
  expect(() => parseHidKeyLabelsCatalog(jsonEncode(catalog)), throwsA(isA<FormatException>()));
}

Map<String, Object?> _group(Map<String, Object?> catalog, int index) {
  final groups = catalog['groups']! as List<Object?>;
  return (groups[index]! as Map).cast<String, Object?>();
}

Map<String, Object?> _key(Map<String, Object?> catalog, int groupIndex, int keyIndex) {
  final keys = _group(catalog, groupIndex)['keys']! as List<Object?>;
  return (keys[keyIndex]! as Map).cast<String, Object?>();
}
