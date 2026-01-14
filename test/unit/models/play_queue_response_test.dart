import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/play_queue_response.dart';
import 'package:plezy/models/plex_metadata.dart';

void main() {
  group('BoolOrIntConverter', () {
    const converter = BoolOrIntConverter();

    group('fromJson', () {
      test('handles bool true', () {
        expect(converter.fromJson(true), true);
      });

      test('handles bool false', () {
        expect(converter.fromJson(false), false);
      });

      test('handles int 1 as true', () {
        expect(converter.fromJson(1), true);
      });

      test('handles int 0 as false', () {
        expect(converter.fromJson(0), false);
      });

      test('handles positive int as true', () {
        expect(converter.fromJson(42), true);
        expect(converter.fromJson(999), true);
      });

      test('handles negative int as true', () {
        expect(converter.fromJson(-1), true);
      });

      test('handles string "true" as true', () {
        expect(converter.fromJson('true'), true);
        expect(converter.fromJson('TRUE'), true);
        expect(converter.fromJson('True'), true);
      });

      test('handles string "1" as true', () {
        expect(converter.fromJson('1'), true);
      });

      test('handles string "false" as false', () {
        expect(converter.fromJson('false'), false);
        expect(converter.fromJson('FALSE'), false);
      });

      test('handles other strings as false', () {
        expect(converter.fromJson('hello'), false);
        expect(converter.fromJson('0'), false);
        expect(converter.fromJson(''), false);
      });

      test('handles other types as false', () {
        expect(converter.fromJson([]), false);
        expect(converter.fromJson({}), false);
        expect(converter.fromJson(3.14), false);
      });
    });

    group('toJson', () {
      test('returns bool unchanged', () {
        expect(converter.toJson(true), true);
        expect(converter.toJson(false), false);
      });
    });
  });

  group('PlayQueueResponse', () {
    PlexMetadata createTestMetadata({
      String ratingKey = '12345',
      String key = '/library/metadata/12345',
      String type = 'episode',
      String title = 'Test Episode',
      int? playQueueItemID,
    }) {
      return PlexMetadata(
        ratingKey: ratingKey,
        key: key,
        type: type,
        title: title,
        playQueueItemID: playQueueItemID,
      );
    }

    group('constructor', () {
      test('creates instance with required fields', () {
        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
        );

        expect(response.playQueueID, 12345);
        expect(response.playQueueShuffled, false);
        expect(response.playQueueTotalCount, 10);
        expect(response.playQueueVersion, 1);
      });

      test('stores optional fields', () {
        final items = [
          createTestMetadata(playQueueItemID: 1),
          createTestMetadata(playQueueItemID: 2),
        ];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueSelectedItemID: 1,
          playQueueSelectedItemOffset: 0,
          playQueueSelectedMetadataItemID: '99999',
          playQueueShuffled: true,
          playQueueSourceURI: '/library/metadata/88888',
          playQueueTotalCount: 50,
          playQueueVersion: 2,
          size: 2,
          items: items,
        );

        expect(response.playQueueSelectedItemID, 1);
        expect(response.playQueueSelectedItemOffset, 0);
        expect(response.playQueueSelectedMetadataItemID, '99999');
        expect(response.playQueueShuffled, true);
        expect(response.playQueueSourceURI, '/library/metadata/88888');
        expect(response.playQueueTotalCount, 50);
        expect(response.playQueueVersion, 2);
        expect(response.size, 2);
        expect(response.items, items);
      });
    });

    group('selectedItem', () {
      test('returns null when items is null', () {
        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: 1,
          items: null,
        );

        expect(response.selectedItem, isNull);
      });

      test('returns null when playQueueSelectedItemID is null', () {
        final items = [createTestMetadata(playQueueItemID: 1)];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: null,
          items: items,
        );

        expect(response.selectedItem, isNull);
      });

      test('returns the selected item when found', () {
        final items = [
          createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          createTestMetadata(ratingKey: '2', playQueueItemID: 101),
          createTestMetadata(ratingKey: '3', playQueueItemID: 102),
        ];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 3,
          playQueueVersion: 1,
          playQueueSelectedItemID: 101,
          items: items,
        );

        expect(response.selectedItem, isNotNull);
        expect(response.selectedItem!.ratingKey, '2');
      });

      test('returns null when selected item not in list', () {
        final items = [
          createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          createTestMetadata(ratingKey: '2', playQueueItemID: 101),
        ];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: 999, // Not in items
          items: items,
        );

        expect(response.selectedItem, isNull);
      });
    });

    group('selectedItemIndex', () {
      test('returns null when items is null', () {
        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: 1,
          items: null,
        );

        expect(response.selectedItemIndex, isNull);
      });

      test('returns null when playQueueSelectedItemID is null', () {
        final items = [createTestMetadata(playQueueItemID: 1)];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: null,
          items: items,
        );

        expect(response.selectedItemIndex, isNull);
      });

      test('returns correct index when item found', () {
        final items = [
          createTestMetadata(ratingKey: '1', playQueueItemID: 100),
          createTestMetadata(ratingKey: '2', playQueueItemID: 101),
          createTestMetadata(ratingKey: '3', playQueueItemID: 102),
        ];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 3,
          playQueueVersion: 1,
          playQueueSelectedItemID: 102, // Third item
          items: items,
        );

        expect(response.selectedItemIndex, 2); // 0-indexed
      });

      test('returns -1 when item not found', () {
        final items = [
          createTestMetadata(ratingKey: '1', playQueueItemID: 100),
        ];

        final response = PlayQueueResponse(
          playQueueID: 12345,
          playQueueShuffled: false,
          playQueueTotalCount: 10,
          playQueueVersion: 1,
          playQueueSelectedItemID: 999, // Not in items
          items: items,
        );

        expect(response.selectedItemIndex, -1);
      });
    });

    group('fromJson', () {
      test('parses wrapped MediaContainer format', () {
        final json = {
          'MediaContainer': {
            'playQueueID': 12345,
            'playQueueVersion': 1,
            'playQueueShuffled': false,
            'playQueueTotalCount': 10,
          }
        };

        final response = PlayQueueResponse.fromJson(json);

        expect(response.playQueueID, 12345);
        expect(response.playQueueVersion, 1);
        expect(response.playQueueShuffled, false);
        expect(response.playQueueTotalCount, 10);
      });

      test('parses unwrapped format', () {
        final json = {
          'playQueueID': 12345,
          'playQueueVersion': 1,
          'playQueueShuffled': true,
          'playQueueTotalCount': 5,
        };

        final response = PlayQueueResponse.fromJson(json);

        expect(response.playQueueID, 12345);
        expect(response.playQueueShuffled, true);
        expect(response.playQueueTotalCount, 5);
      });

      test('handles shuffled as int 1', () {
        final json = {
          'playQueueID': 12345,
          'playQueueVersion': 1,
          'playQueueShuffled': 1,
          'playQueueTotalCount': 10,
        };

        final response = PlayQueueResponse.fromJson(json);

        expect(response.playQueueShuffled, true);
      });

      test('handles shuffled as int 0', () {
        final json = {
          'playQueueID': 12345,
          'playQueueVersion': 1,
          'playQueueShuffled': 0,
          'playQueueTotalCount': 10,
        };

        final response = PlayQueueResponse.fromJson(json);

        expect(response.playQueueShuffled, false);
      });

      test('tags items with server info', () {
        final json = {
          'playQueueID': 12345,
          'playQueueVersion': 1,
          'playQueueShuffled': false,
          'playQueueTotalCount': 1,
          'Metadata': [
            {
              'ratingKey': '99999',
              'key': '/library/metadata/99999',
              'type': 'episode',
              'title': 'Test Episode',
            }
          ],
        };

        final response = PlayQueueResponse.fromJson(
          json,
          serverId: 'server-abc',
          serverName: 'My Server',
        );

        expect(response.items, isNotNull);
        expect(response.items!.length, 1);
        expect(response.items!.first.serverId, 'server-abc');
        expect(response.items!.first.serverName, 'My Server');
      });
    });
  });
}
