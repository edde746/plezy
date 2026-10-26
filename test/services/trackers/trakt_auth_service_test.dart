import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/models/trackers/device_code.dart';
import 'package:plezy/services/trackers/trakt/trakt_auth_service.dart';
import 'package:plezy/services/trackers/trakt/trakt_constants.dart';

void main() {
  test('device authorization identifies the public client without a secret', () async {
    http.Request? captured;
    final service = TraktAuthService(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          json.encode({
            'device_code': 'device-code',
            'user_code': 'USER-CODE',
            'verification_url': 'https://trakt.tv/activate',
            'expires_in': 600,
            'interval': 5,
          }),
          200,
        );
      }),
    );

    final code = await service.createDeviceCode();

    expect(code.deviceCode, 'device-code');
    expect(captured?.url.path, '/oauth/device/code');
    expect(json.decode(captured!.body), {'client_id': TraktConstants.clientId});
    service.dispose();
  });

  test('device-code polling does not send a client secret', () async {
    http.Request? captured;
    final service = TraktAuthService(
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response('authorization pending', 400);
      }),
    );

    final result = await service.probe(
      const DeviceCode(
        deviceCode: 'device-code',
        userCode: 'USER-CODE',
        verificationUrl: 'https://trakt.tv/activate',
        expiresIn: 600,
        interval: 5,
      ),
    );

    expect(result, isA<DevicePollPending>());
    expect(captured?.url.path, '/oauth/device/token');
    expect(json.decode(captured!.body), {'code': 'device-code', 'client_id': TraktConstants.clientId});
    service.dispose();
  });
}
