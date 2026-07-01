import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/connection/connection_registry.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/profiles/profile_connection_registry.dart';
import 'package:plezy/providers/seerr_session_provider.dart';
import 'package:plezy/screens/seerr/seerr_detail_screen.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_client.dart';
import 'package:provider/provider.dart';

SeerrConnection _conn() => SeerrConnection(
  id: 'seerr-1',
  baseUrl: 'https://requests.example.com',
  instanceLabel: 'Seerr',
  jellyfinUsername: 'edde',
  jellyfinPassword: 'pw',
  sessionCookie: 'sid',
  seerrUserId: 7,
  permissions: 0,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

http.Response _json(int code, Object body) =>
    http.Response(jsonEncode(body), code, headers: {'content-type': 'application/json'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders movie detail even when recommendations request fails', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    var recommendationsRequested = false;
    Future<http.Response> handler(http.Request req) async {
      if (req.url.path.endsWith('/recommendations')) {
        recommendationsRequested = true;
        // Recommendations fail — the detail must still degrade gracefully.
        return _json(500, {'error': 'boom'});
      }
      // /movie/{id} — only `id` is strictly required to parse.
      return _json(200, {'id': 42, 'title': 'Test Movie'});
    }

    final client = SeerrClient(
      _conn(),
      authService: SeerrAuthService(testHttpClientFactory: () => MockClient(handler)),
      onSessionInvalidated: () {},
      httpClient: MockClient(handler),
    );
    addTearDown(client.dispose);

    final session = _FakeSeerrSession(
      client,
      connectionRegistry: ConnectionRegistry(db),
      profileConnectionRegistry: ProfileConnectionRegistry(db),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<SeerrSessionProvider>.value(
        value: session,
        child: const MaterialApp(home: SeerrDetailScreen(tmdbId: 42, mediaType: 'movie')),
      ),
    );
    await tester.pumpAndSettle();

    // The recommendations request was attempted and failed...
    expect(recommendationsRequested, isTrue);
    // ...yet the screen degraded gracefully: the detail body (with its
    // "Request" call-to-action) is shown, not the error/not-connected state.
    expect(find.text(t.seerr.detail.requestMovie), findsOneWidget);
    expect(find.text(t.seerr.detail.notConnected), findsNothing);
  });
}

/// Minimal [SeerrSessionProvider] whose [client] is a pre-built, mocked
/// [SeerrClient]. The base constructor needs the registries but they are
/// never exercised here — only [client] is read by the screen.
class _FakeSeerrSession extends SeerrSessionProvider {
  _FakeSeerrSession(this._client, {required super.connectionRegistry, required super.profileConnectionRegistry});

  final SeerrClient? _client;

  @override
  SeerrClient? get client => _client;
}
