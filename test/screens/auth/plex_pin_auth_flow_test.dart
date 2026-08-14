import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/screens/auth/plex_pin_auth_flow.dart';
import 'package:plezy/services/plex_auth_service.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../test_helpers/theme.dart';

/// Serves a PIN without touching plex.tv, and never resolves the claim poll so
/// the flow parks on whichever waiting UI it chose.
class _StalledPlexAuthService extends PlexAuthService {
  _StalledPlexAuthService()
    : super.forTesting(http: MediaServerHttpClient(client: MockClient((_) async => http.Response('{}', 200))));

  @override
  Future<Map<String, dynamic>> createPin() async => <String, dynamic>{'id': 1, 'code': 'ABCD'};

  @override
  String getAuthUrl(String pinCode) => 'https://app.plex.tv/auth#?code=$pinCode';

  @override
  Future<String?> pollPinUntilClaimed(
    int pinId, {
    Duration timeout = const Duration(minutes: 2),
    bool Function()? shouldCancel,
    Duration initialBackoff = const Duration(seconds: 1),
    Duration maxBackoff = const Duration(seconds: 5),
  }) => Completer<String?>().future;
}

/// The channel every `url_launcher` platform implementation talks to; a
/// recorded call means the flow tried to leave the app for a browser.
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  final launched = <String>[];

  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() {
    launched.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_urlLauncherChannel, (
      call,
    ) async {
      switch (call.method) {
        case 'launch':
          launched.add((call.arguments as Map)['url'] as String);
          return true;
        case 'canLaunch':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _urlLauncherChannel,
      null,
    );
    TvDetectionService.debugSetAutomotiveOverride(null);
    TvDetectionService.debugReset();
  });

  Future<void> pumpFlow(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: ThemeData(extensions: const [testMonoTokens]),
          home: Scaffold(
            body: PlexPinAuthFlow(
              onTokenReceived: (_) async {},
              autoStartQrOnTV: false,
              serviceFactory: () async => _StalledPlexAuthService(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a car keeps the Plex hand-off in-app as a QR code', (tester) async {
    // A head unit has no browser: Android Automotive gives an app-launched URL
    // to the car link viewer, so launching one strands the flow on a spinner
    // until the PIN expires.
    TvDetectionService.debugSetAutomotiveOverride(true);
    await pumpFlow(tester);

    await tester.tap(find.text(t.auth.signInWithPlex));
    await tester.pump();
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(t.auth.scanQRToSignIn), findsOneWidget);
    expect(find.text(t.auth.waitingForAuth), findsNothing);
    expect(launched, isEmpty);
  });

  testWidgets('every other device still hands Plex sign-in to a browser', (tester) async {
    TvDetectionService.debugSetAutomotiveOverride(false);
    await pumpFlow(tester);

    await tester.tap(find.text(t.auth.signInWithPlex));
    await tester.pump();
    await tester.pump();

    expect(launched, hasLength(1));
    expect(launched.single, startsWith('https://app.plex.tv/auth'));
    expect(find.text(t.auth.waitingForAuth), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('the QR button is unaffected off a car', (tester) async {
    TvDetectionService.debugSetAutomotiveOverride(false);
    await pumpFlow(tester);

    await tester.tap(find.text(t.auth.showQRCode));
    await tester.pump();
    await tester.pump();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(launched, isEmpty);
  });
}
