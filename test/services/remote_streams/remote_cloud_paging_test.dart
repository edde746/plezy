import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/remote_streams/additional_debrid_clients.dart';
import 'package:plezy/services/remote_streams/real_debrid_client.dart';
import 'package:plezy/services/remote_streams/remote_stream_models.dart';

void main() {
  group('debrid cloud inventory paging', () {
    test('Real-Debrid advances by offset and stops on the short final page', () async {
      final requestedOffsets = <String?>[];
      final client = RealDebridClient(
        account: const RemoteStreamAccount(
          id: 'rd-account',
          service: RemoteStreamService.realDebrid,
          displayName: 'Real-Debrid',
          accessToken: 'test-token',
        ),
        client: MockClient((request) async {
          requestedOffsets.add(request.url.queryParameters['offset']);
          final offset = int.parse(request.url.queryParameters['offset']!);
          final count = offset == 0 ? 100 : 1;
          return http.Response(
            jsonEncode([
              for (var index = 0; index < count; index++)
                {'id': offset * 1000 + index, 'status': 'downloaded', 'filename': 'Movie $index', 'bytes': 10},
            ]),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final first = await client.browseCloud();
      final second = await client.browseCloud(offset: int.parse(first.nextCursor!));

      expect(requestedOffsets, ['0', '100']);
      expect(first.items, hasLength(100));
      expect(first.nextCursor, '100');
      expect(second.items, hasLength(1));
      expect(second.nextCursor, isNull);
    });

    test('TorBox advances by offset and preserves page boundaries', () async {
      final requestedOffsets = <String?>[];
      final client = TorBoxClient(
        account: const RemoteStreamAccount(
          id: 'torbox-account',
          service: RemoteStreamService.torbox,
          displayName: 'TorBox',
          accessToken: 'test-token',
        ),
        client: MockClient((request) async {
          requestedOffsets.add(request.url.queryParameters['offset']);
          final offset = int.parse(request.url.queryParameters['offset']!);
          final count = offset == 0 ? 100 : 1;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                for (var index = 0; index < count; index++)
                  {'id': offset + index + 1, 'name': 'Movie $index', 'cached': true, 'size': 10},
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(client.close);

      final first = await client.browseCloud();
      final second = await client.browseCloud(offset: int.parse(first.nextCursor!));

      expect(requestedOffsets, ['0', '100']);
      expect(first.items, hasLength(100));
      expect(first.nextCursor, '100');
      expect(second.items, hasLength(1));
      expect(second.nextCursor, isNull);
    });

    test('page limits are bounded before they reach provider APIs', () async {
      final realDebrid = RealDebridClient(
        account: const RemoteStreamAccount(
          id: 'rd-account',
          service: RemoteStreamService.realDebrid,
          displayName: 'Real-Debrid',
          accessToken: 'test-token',
        ),
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      final torbox = TorBoxClient(
        account: const RemoteStreamAccount(
          id: 'torbox-account',
          service: RemoteStreamService.torbox,
          displayName: 'TorBox',
          accessToken: 'test-token',
        ),
        client: MockClient((_) async => http.Response('{"success":true,"data":[]}', 200)),
      );
      addTearDown(realDebrid.close);
      addTearDown(torbox.close);

      await expectLater(realDebrid.browseCloud(offset: -1), throwsA(isA<RealDebridException>()));
      await expectLater(torbox.browseCloud(offset: -1), throwsA(isA<RemoteProviderException>()));
    });
  });
}
