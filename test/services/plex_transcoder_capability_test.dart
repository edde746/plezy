import 'dart:convert';
import 'package:plezy/media/ids.dart';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Plex transcoder capability', () {
    test('client probe fails open when transcoderVideo is absent', () async {
      final client = _makeClient({'friendlyName': 'Plex'});
      addTearDown(client.close);

      final supported = await client.serverSupportsVideoTranscoding();

      expect(supported, isTrue);
      expect(client.capabilities.videoTranscoding, isTrue);
    });

    test('client probe preserves explicit transcoderVideo false', () async {
      final client = _makeClient({'transcoderVideo': false});
      addTearDown(client.close);

      final supported = await client.serverSupportsVideoTranscoding();

      expect(supported, isFalse);
      expect(client.capabilities.videoTranscoding, isFalse);
    });

    test('connection probe keeps absent transcoderVideo unknown', () async {
      final server = await _startRootServer({'friendlyName': 'Plex'});
      addTearDown(() async => server.close(force: true));

      final result = await PlexClient.testConnectionWithLatency(
        _serverBaseUrl(server),
        'token',
        timeout: const Duration(seconds: 2),
        clientIdentifier: 'client-id',
      );

      expect(result.success, isTrue);
      expect(result.transcoderVideo, isNull);
    });

    test('connection probe preserves explicit transcoderVideo false', () async {
      final server = await _startRootServer({'transcoderVideo': false});
      addTearDown(() async => server.close(force: true));

      final result = await PlexClient.testConnectionWithLatency(
        _serverBaseUrl(server),
        'token',
        timeout: const Duration(seconds: 2),
        clientIdentifier: 'client-id',
      );

      expect(result.success, isTrue);
      expect(result.transcoderVideo, isFalse);
    });
  });
}

PlexClient _makeClient(Map<String, dynamic> rootContainer) {
  return PlexClient.forTesting(
    config: PlexConfig(
      baseUrl: 'https://plex.example.com',
      token: 'token',
      clientIdentifier: 'client-id',
      product: 'Plezy',
      version: 'test',
    ),
    serverId: ServerId('server-id'),
    httpClient: MockClient((request) async {
      expect(request.url.path, '/');
      return http.Response(
        jsonEncode({'MediaContainer': rootContainer}),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );
}

Future<HttpServer> _startRootServer(Map<String, dynamic> rootContainer) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    if (request.uri.path != '/') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'MediaContainer': rootContainer}));
    await request.response.close();
  });
  return server;
}

String _serverBaseUrl(HttpServer server) => 'http://${server.address.host}:${server.port}';
