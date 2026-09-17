import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/certificate_trust.dart';
import 'package:plezy/utils/happy_eyeballs.dart';

// Self-signed CA, valid until 2126; mirrors android/.../UserCertificateChannelTest.kt.
const _privateAuthorityPem = '''
-----BEGIN CERTIFICATE-----
MIIBpjCCAU2gAwIBAgIUE2B0ftvgw24qfGGZDgg9ahCt6W4wCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAgMR4wHAYDVQQDDBVQbGV6eSBUZXN0IFByaXZh
dGUgQ0EwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAATRtBIaHTld7jouEH7XGewU
K0lQXk04cKOtASHwiJ4yeaG3IwqwUzKprnIbJ9LO8j8Yug6Z3b6UuFmmR9nCy3Z0
o2MwYTAdBgNVHQ4EFgQUMkopaSNoRnirfv98G1AIU57Bfd8wHwYDVR0jBBgwFoAU
MkopaSNoRnirfv98G1AIU57Bfd8wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8E
BAMCAQYwCgYIKoZIzj0EAwIDRwAwRAIgZ05Qu7LVaJYl3CabUJ0FvJVe6lHTsbNk
2rBsxeQin20CIHTBFcdyUpAop/I2fotqNzyyP6Awz6V5B8E6phpnwoa5
-----END CERTIFICATE-----
''';

// Leaf for localhost / 127.0.0.1 issued by the authority above.
const _serverLeafPem = '''
-----BEGIN CERTIFICATE-----
MIIBxjCCAWugAwIBAgIUELPXCK88VPZica3MS4eHc+WP0cEwCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVUGxlenkgVGVzdCBQcml2YXRlIENBMCAXDTI2MDkxMzEwMDQ1
MloYDzIxMjYwODIwMTAwNDUyWjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwWTATBgcq
hkjOPQIBBggqhkjOPQMBBwNCAARyNHegHEHgV3jdV3igrqT2XMTZdUUGJS8seSTH
Ef5c0SbWphL3bkaJkJrmwkG2zLeztPkpcShdhF9NhmFDuFiVo4GMMIGJMBoGA1Ud
EQQTMBGCCWxvY2FsaG9zdIcEfwAAATAJBgNVHRMEAjAAMAsGA1UdDwQEAwIHgDAT
BgNVHSUEDDAKBggrBgEFBQcDATAdBgNVHQ4EFgQUza0Nj5xZ8PAzmrIZqtwLKp1E
9lAwHwYDVR0jBBgwFoAUMkopaSNoRnirfv98G1AIU57Bfd8wCgYIKoZIzj0EAwID
SQAwRgIhAK5tJYi21adtGCItM7NMz2s+feAwx0jyGICU5B1s88DCAiEArPUwqZSl
5yJJLTVYtdCVgZrAH3SJ8eau3/uKmx7uXSo=
-----END CERTIFICATE-----
''';

const _serverKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgH4LEt+A2RvrYcUy7
yysLq2toiAdeT+kXlUxy3AMeAwyhRANCAARyNHegHEHgV3jdV3igrqT2XMTZdUUG
JS8seSTHEf5c0SbWphL3bkaJkJrmwkG2zLeztPkpcShdhF9NhmFDuFiV
-----END PRIVATE KEY-----
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void platformAnswers(FutureOr<Object?> Function() reply) {
    messenger.setMockMethodCallHandler(CertificateTrust.channel, (call) async {
      expect(call.method, 'getUserAuthoritiesPem');
      return reply();
    });
  }

  setUp(CertificateTrust.debugReset);
  tearDown(() {
    messenger.setMockMethodCallHandler(CertificateTrust.channel, null);
    CertificateTrust.debugReset();
  });

  group('contextFor', () {
    test('keeps the SDK default until the user store has been loaded', () {
      expect(CertificateTrust.contextFor('jellyfin.home'), isNull);
    });

    test('hands the user store to user-entered hosts and never to fixed endpoints', () async {
      platformAnswers(() => _privateAuthorityPem);
      await CertificateTrust.loadUserAuthorities();

      final userStore = CertificateTrust.contextFor('jellyfin.home');
      expect(userStore, isNotNull);
      expect(CertificateTrust.contextFor('192.168.1.3'), same(userStore));
      expect(
        CertificateTrust.contextFor('notplex.tv'),
        same(userStore),
        reason: 'a parent-domain match must stop at a label boundary',
      );
      for (final fixed in ['plex.tv', 'app.plex.tv', 'PLEX.TV', 'ice.plezy.app', 'api.github.com', 'image.tmdb.org']) {
        expect(CertificateTrust.contextFor(fixed), isNull, reason: fixed);
      }
    });

    test('an unreadable, empty or malformed store leaves system anchors in place without throwing', () async {
      platformAnswers(() => throw PlatformException(code: 'unavailable'));
      await CertificateTrust.loadUserAuthorities();
      expect(CertificateTrust.contextFor('jellyfin.home'), isNull);

      platformAnswers(() => '');
      await CertificateTrust.loadUserAuthorities();
      expect(CertificateTrust.contextFor('jellyfin.home'), isNull);

      platformAnswers(() => 'not a certificate bundle');
      await CertificateTrust.loadUserAuthorities();
      expect(CertificateTrust.contextFor('jellyfin.home'), isNull);
    });
  });

  group('TLS upgrade', () {
    late SecureServerSocket server;
    late StreamSubscription<SecureSocket> accepted;

    setUp(() async {
      final serverContext = SecurityContext()
        ..useCertificateChainBytes(utf8.encode('$_serverLeafPem$_privateAuthorityPem'))
        ..usePrivateKeyBytes(utf8.encode(_serverKeyPem));
      server = await SecureServerSocket.bind(InternetAddress.loopbackIPv4, 0, serverContext);
      // A rejected handshake surfaces here as a stream error; it is the client
      // side's verdict the tests assert on.
      accepted = server.listen((socket) => socket.destroy(), onError: (Object _) {});
    });

    tearDown(() async {
      await accepted.cancel();
      await server.close();
    });

    Future<Socket> connect() => startHappyEyeballsConnect(
      'localhost',
      server.port,
      secure: true,
      lookup: (_, {required type}) async => type == InternetAddressType.IPv4 ? [InternetAddress.loopbackIPv4] : [],
    ).socket;

    test('a private authority is rejected under system-only trust', () async {
      await expectLater(connect(), throwsA(isA<HandshakeException>()));
    });

    test(
      'a private authority the owner installed verifies a user-entered host',
      () async {
        platformAnswers(() => _privateAuthorityPem);
        await CertificateTrust.loadUserAuthorities();

        final socket = await connect();
        addTearDown(socket.destroy);

        expect(socket, isA<SecureSocket>());
      },
      // Apple platforms hand verification to SecTrust, which caps a TLS leaf at
      // 825 days and rejects the long-lived fixture. The fix is Android-only and
      // this exercises BoringSSL's own verifier, which Linux CI runs.
      skip: Platform.isMacOS ? 'SecTrust rejects a leaf valid for more than 825 days' : false,
    );
  });
}
