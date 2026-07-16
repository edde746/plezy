import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/mpv_node_decoder.dart';

void main() {
  const nestedList = [
    {
      'type': 'audio',
      'metadata': {
        'values': [true, 2, 3.5, null],
      },
    },
  ];
  const nestedMap = {
    'cache-end': 12.5,
    'seekable-ranges': [
      {'start': 1, 'end': 9.25},
    ],
  };

  final cases = <({String name, Object? input, Object? list, Object? map})>[
    (name: 'nested structured list', input: nestedList, list: nestedList, map: null),
    (name: 'nested structured map', input: nestedMap, list: null, map: nestedMap),
    (
      name: 'valid list JSON',
      input: '[{"type":"audio","metadata":{"values":[true,2,3.5,null]}}]',
      list: nestedList,
      map: null,
    ),
    (
      name: 'valid map JSON',
      input: '{"cache-end":12.5,"seekable-ranges":[{"start":1,"end":9.25}]}',
      list: null,
      map: nestedMap,
    ),
    (name: 'malformed JSON', input: '{not-json', list: null, map: null),
    (name: 'JSON scalar', input: '42', list: null, map: null),
    (name: 'structured scalar', input: 42, list: null, map: null),
    (name: 'empty string', input: '', list: null, map: null),
    (name: 'null', input: null, list: null, map: null),
    (name: 'JSON null', input: 'null', list: null, map: null),
    (name: 'empty structured list', input: const [], list: const [], map: null),
    (name: 'empty structured map', input: const {}, list: null, map: const {}),
    (name: 'empty JSON list', input: '[]', list: const [], map: null),
    (name: 'empty JSON map', input: '{}', list: null, map: const {}),
  ];

  for (final testCase in cases) {
    test(testCase.name, () {
      expect(MpvNodeDecoder.decodeList(testCase.input), testCase.list);
      expect(MpvNodeDecoder.decodeMap(testCase.input), testCase.map);
    });
  }
}
