import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/seerr/seerr_session.dart';
import 'package:plezy/providers/seerr_account_provider.dart';
import 'package:plezy/screens/settings/seerr_connect_screen.dart';
import 'package:plezy/services/seerr/seerr_auth_service.dart';
import 'package:plezy/services/seerr/seerr_constants.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:provider/provider.dart';

/// Records what the connect flow produced instead of persisting it: the real
/// store writes through the credential vault.
class _RecordingAccount extends SeerrAccountProvider {
  _RecordingAccount(SeerrAuthService authService) : super(authService: authService);

  SeerrSession? adopted;

  @override
  Future<void> adoptSession(SeerrSession session) async => adopted = session;
}

http.Response _json(Object body, {int status = 200, Map<String, String>? headers}) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json', ...?headers});

Map<String, Object?> _publicSettings({int mediaServerType = SeerrMediaServerType.jellyfin}) => {
  'initialized': true,
  'applicationTitle': 'Requests',
  'localLogin': false,
  'mediaServerLogin': true,
  'mediaServerType': mediaServerType,
};

/// A Seerr that answers only on plain HTTP at its default port — the LAN setup
/// that used to fail because the form assumed https.
SeerrAuthService _plainHttpLanInstance({int mediaServerType = SeerrMediaServerType.jellyfin}) {
  return SeerrAuthService(
    httpClientFactory: () => MockClient((request) async {
      if (request.url.scheme != 'http' || request.url.port != SeerrConstants.defaultPort) {
        throw http.ClientException('connection refused', request.url);
      }
      return _json(_publicSettings(mediaServerType: mediaServerType));
    }),
  );
}

/// The same instance, plus the Quick Connect proxy routes. [approved] gates the
/// poll; [initiateStatus] simulates an instance without the routes.
SeerrAuthService _quickConnectInstance({bool approved = true, int initiateStatus = 200}) {
  return SeerrAuthService(
    httpClientFactory: () => MockClient((request) async {
      switch (request.url.path) {
        case '/api/v1/settings/public':
          return _json(_publicSettings());
        case '/api/v1/auth/jellyfin/quickconnect/initiate':
          if (initiateStatus != 200) return _json({'message': 'Not Found'}, status: initiateStatus);
          return _json({'code': 'ABC123', 'secret': 'qc-secret'});
        case '/api/v1/auth/jellyfin/quickconnect/check':
          return _json({'authenticated': approved});
        case '/api/v1/auth/jellyfin/quickconnect/authenticate':
          return _json(
            {'id': 3, 'displayName': 'Alice', 'permissions': 2},
            headers: {'set-cookie': '${SeerrConstants.sessionCookieName}=fresh; Path=/'},
          );
      }
      throw http.ClientException('unexpected ${request.url.path}', request.url);
    }),
  );
}

void main() {
  late _RecordingAccount account;

  tearDown(() => account.dispose());

  Widget app(SeerrAuthService auth, {ValueChanged<Future<bool?>>? onRoute}) {
    account = _RecordingAccount(auth);
    return ChangeNotifierProvider<SeerrAccountProvider>.value(
      value: account,
      child: MaterialApp(
        theme: monoTheme(dark: true),
        home: onRoute == null
            ? const SeerrConnectScreen()
            : Builder(
                builder: (context) => TextButton(
                  onPressed: () => onRoute(
                    Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const SeerrConnectScreen())),
                  ),
                  child: const Text('Open route'),
                ),
              ),
      ),
    );
  }

  Future<void> submitUrl(WidgetTester tester, String input) async {
    await tester.enterText(find.byType(TextField).first, input);
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
  }

  /// The waiting panel hosts a perpetual spinner, so `pumpAndSettle` would
  /// never return — pump bounded frames instead.
  Future<void> pumpFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('a schemeless address reaches a plain-HTTP instance on the default port', (tester) async {
    await tester.pumpWidget(app(_plainHttpLanInstance()));
    await submitUrl(tester, 'seerr.lan');

    // The URL that answered is what the sign-in and the session will use.
    expect(find.text('http://seerr.lan:5055'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
  });

  testWidgets('an unreachable address keeps the URL step with the primary candidate named', (tester) async {
    await tester.pumpWidget(
      app(
        SeerrAuthService(
          httpClientFactory: () =>
              MockClient((request) async => throw http.ClientException('connection refused', request.url)),
        ),
      ),
    );
    await submitUrl(tester, 'seerr.lan');

    expect(find.textContaining('https://seerr.lan'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('Quick Connect is offered for a Jellyfin-backed instance', (tester) async {
    await tester.pumpWidget(app(_plainHttpLanInstance()));
    await submitUrl(tester, 'seerr.lan');

    expect(find.text('Use Quick Connect'), findsOneWidget);
  });

  testWidgets('Quick Connect is withheld from an Emby-backed instance', (tester) async {
    // Seerr rejects its Quick Connect routes for Emby, so the affordance is
    // gated on the linked media server, not on the instance answering at all.
    await tester.pumpWidget(app(_plainHttpLanInstance(mediaServerType: SeerrMediaServerType.emby)));
    await submitUrl(tester, 'seerr.lan');

    expect(find.text('Use Quick Connect'), findsNothing);
    // Emby's only path stays reachable.
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('Quick Connect shows the code and cancel restores the form', (tester) async {
    await tester.pumpWidget(app(_quickConnectInstance(approved: false)));
    await submitUrl(tester, 'https://seerr.example.com');

    await tester.tap(find.text('Use Quick Connect'));
    await pumpFrames(tester);

    expect(find.text('ABC123'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(find.text('ABC123'), findsNothing);
    expect(find.byType(TextField), findsWidgets);
    expect(account.adopted, isNull);

    // Let the cancelled poll's backoff timer fire so the test ends clean.
    await tester.pump(SeerrConstants.quickConnectPollInterval * 2);
  });

  testWidgets('approving the code adopts a quickConnect session and pops', (tester) async {
    Future<bool?>? route;
    await tester.pumpWidget(app(_quickConnectInstance(), onRoute: (r) => route = r));
    await tester.tap(find.text('Open route'));
    await tester.pumpAndSettle();

    await submitUrl(tester, 'https://seerr.example.com');
    await tester.tap(find.text('Use Quick Connect'));
    await tester.pumpAndSettle();

    expect(await route, isTrue);
    expect(account.adopted, isNotNull);
    expect(account.adopted!.method, SeerrAuthMethod.quickConnect);
    expect(account.adopted!.cookie, 'fresh');
    expect(account.adopted!.secret, isEmpty, reason: 'no secret to store means no silent re-auth to attempt');
    expect(account.adopted!.instanceLabel, 'Requests');
  });

  testWidgets('an instance without the Quick Connect routes says so and restores the form', (tester) async {
    await tester.pumpWidget(app(_quickConnectInstance(initiateStatus: 404)));
    await submitUrl(tester, 'https://seerr.example.com');

    await tester.tap(find.text('Use Quick Connect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Seerr 3.4 or newer'), findsOneWidget);
    expect(find.text('Use Quick Connect'), findsOneWidget);
  });
}
