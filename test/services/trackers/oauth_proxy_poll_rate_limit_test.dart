import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/services/trackers/oauth_proxy_client.dart';
import 'package:plezy/services/trackers/tracker_constants.dart';

/// Contract: a 429 from /auth/result is rate limiting, not a terminal failure.
/// The poller must keep the session alive by retrying — honoring Retry-After
/// when the relay sends one — and may only surface a failure once the
/// session's own lifetime has expired.
void main() {
  const tokenBody = '{"accessToken":"tok-abc","refreshToken":"ref-xyz","expiresIn":3600}';

  group('poll 429 handling', () {
    test('a 429 mid-poll honors Retry-After and the flow still completes', () {
      fakeAsync((async) {
        var calls = 0;
        final client = OAuthProxyClient(
          httpClient: MockClient((request) async {
            calls++;
            if (calls == 1) {
              return http.Response('Rate limited', 429, headers: {'retry-after': '3'});
            }
            return http.Response(tokenBody, 200);
          }),
        );

        OAuthProxyResult? result;
        Object? error;
        client.poll('secret').then<void>((r) => result = r, onError: (Object e) => error = e);
        async.flushMicrotasks();
        expect(calls, 1);
        expect(error, isNull, reason: '429 must not abort the poll loop');

        // The 3 s Retry-After hint outranks the default 2 s retry tick.
        async.elapse(const Duration(seconds: 2));
        expect(calls, 1);
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(calls, 2);
        expect(error, isNull);
        expect(result?.accessToken, 'tok-abc');
        client.dispose();
      });
    });

    test('a 429 without Retry-After backs off to the next poll tick', () {
      fakeAsync((async) {
        var calls = 0;
        final client = OAuthProxyClient(
          httpClient: MockClient((request) async {
            calls++;
            if (calls == 1) return http.Response('Rate limited', 429);
            return http.Response(json.encode({'accessToken': 'tok-abc'}), 200);
          }),
        );

        OAuthProxyResult? result;
        client.poll('secret').then<void>((r) => result = r);
        async.flushMicrotasks();
        expect(calls, 1);
        expect(result, isNull);

        async.elapse(TrackerConstants.oauthProxyRetryDelay);
        async.flushMicrotasks();
        expect(calls, 2);
        expect(result?.accessToken, 'tok-abc');
        client.dispose();
      });
    });

    test('persistent 429 fails only at the session deadline, not immediately', () {
      fakeAsync((async) {
        var calls = 0;
        final client = OAuthProxyClient(
          httpClient: MockClient((request) async {
            calls++;
            return http.Response('Rate limited', 429);
          }),
        );

        var completed = false;
        Object? error;
        client
            .poll('secret')
            .then<void>(
              (_) => completed = true,
              onError: (Object e) {
                completed = true;
                error = e;
              },
            );
        async.flushMicrotasks();
        expect(calls, 1);
        expect(completed, isFalse, reason: 'a 429 must not be an immediate abort');

        // Well within the session lifetime the poller is still retrying.
        async.elapse(const Duration(minutes: 5));
        expect(completed, isFalse);
        expect(calls, greaterThan(1));

        // Past the relay's session TTL the failure surfaces with the existing
        // unexpected-status error shape.
        async.elapse(TrackerConstants.oauthProxySessionTimeout);
        async.flushMicrotasks();
        expect(completed, isTrue);
        expect(error, isA<OAuthProxyException>());
        expect('$error', contains('HTTP 429'));
        client.dispose();
      });
    });
  });
}
