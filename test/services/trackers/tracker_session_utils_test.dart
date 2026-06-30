import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/services/trackers/tracker_constants.dart';
import 'package:vibe_stream/services/trackers/tracker_exceptions.dart';
import 'package:vibe_stream/services/trackers/tracker_session.dart';
import 'package:vibe_stream/services/trackers/tracker_session_utils.dart';

void main() {
  group('tracker token expiry helpers', () {
    test('detects expired token', () {
      expect(isTrackerTokenExpired(100, nowSeconds: 100), isTrue);
      expect(isTrackerTokenExpired(101, nowSeconds: 100), isFalse);
    });

    test('detects refresh window', () {
      expect(trackerTokenNeedsRefresh(400, nowSeconds: 100), isTrue);
      expect(trackerTokenNeedsRefresh(401, nowSeconds: 100), isFalse);
      expect(trackerTokenNeedsRefresh(110, refreshWindowSeconds: 10, nowSeconds: 100), isTrue);
    });
  });

  group('tracker session json codec', () {
    test('round-trips through provided factory', () {
      final encoded = encodeTrackerSessionJson({'access_token': 'abc', 'created_at': 123});
      final decoded = decodeTrackerSessionJson(encoded, (json) => json);

      expect(decoded, {'access_token': 'abc', 'created_at': 123});
    });

    test('round-trips Trakt sessions with snake-case keys and default scope', () {
      const session = TrackerSession(
        accessToken: 'trakt-at',
        refreshToken: 'trakt-rt',
        expiresAt: 2000,
        scope: 'public',
        createdAt: 1000,
      );

      expect(session.toJson(), {
        'access_token': 'trakt-at',
        'refresh_token': 'trakt-rt',
        'expires_at': 2000,
        'username': null,
        'scope': 'public',
        'created_at': 1000,
      });

      final decoded = TrackerSession.fromJson({
        'access_token': 'trakt-at',
        'refresh_token': 'trakt-rt',
        'expires_at': 2000,
        'created_at': 1000,
      });

      expect(decoded.accessToken, 'trakt-at');
      expect(decoded.refreshToken, 'trakt-rt');
      expect(decoded.expiresAt, 2000);
      expect(decoded.username, isNull);
      expect(decoded.scope, isNull);
      expect(decoded.createdAt, 1000);
    });

    test('round-trips AniList sessions through shared encode mixin', () {
      const session = TrackerSession(accessToken: 'anilist-at', expiresAt: 2000, username: 'alice', createdAt: 1000);

      final decoded = TrackerSession.decode(session.encode());

      expect(decoded.accessToken, 'anilist-at');
      expect(decoded.expiresAt, 2000);
      expect(decoded.username, 'alice');
      expect(decoded.createdAt, 1000);
    });

    test('round-trips MAL sessions through shared encode mixin', () {
      const session = TrackerSession(
        accessToken: 'mal-at',
        refreshToken: 'mal-rt',
        expiresAt: 2000,
        username: 'bob',
        createdAt: 1000,
      );

      final decoded = TrackerSession.decode(session.encode());

      expect(decoded.accessToken, 'mal-at');
      expect(decoded.refreshToken, 'mal-rt');
      expect(decoded.expiresAt, 2000);
      expect(decoded.username, 'bob');
      expect(decoded.createdAt, 1000);
    });

    test('round-trips Simkl sessions through shared encode mixin', () {
      const session = TrackerSession(accessToken: 'simkl-at', username: 'carol', createdAt: 1000);

      final decoded = TrackerSession.decode(session.encode());

      expect(decoded.accessToken, 'simkl-at');
      expect(decoded.username, 'carol');
      expect(decoded.createdAt, 1000);
    });

    test('builds Trakt token sessions with default scope', () {
      final session = TrackerSession.fromTokenResponse(TrackerService.trakt, {
        'access_token': 'trakt-at',
        'refresh_token': 'trakt-rt',
        'expires_in': 1000,
        'created_at': 1000,
      });

      expect(session.scope, 'public');
      expect(session.expiresAt, 2000);
    });

    test('defaults missing scope only when decoding stored Trakt sessions', () {
      final encoded = encodeTrackerSessionJson({
        'access_token': 'trakt-at',
        'refresh_token': 'trakt-rt',
        'expires_at': 2000,
        'created_at': 1000,
      });

      expect(TrackerSession.decode(encoded).scope, isNull);
      expect(TrackerSession.decode(encoded, service: TrackerService.trakt).scope, 'public');
    });
  });

  // The migration-safety contract: a service-aware decode (the shape
  // TrackerAccountStore.load uses) must keep accepting every pre-refactor blob
  // shape, and reject corrupt/truncated ones by throwing — TrackerAccountStore
  // swallows that into a clean re-auth rather than loading a broken session.
  group('persisted session validation', () {
    test('decodes a legacy Simkl blob (no scope/refresh/expiry)', () {
      final raw = encodeTrackerSessionJson({'access_token': 'simkl-at', 'username': 'carol', 'created_at': 1000});

      final session = TrackerSession.decode(raw, service: TrackerService.simkl);

      expect(session.accessToken, 'simkl-at');
      expect(session.username, 'carol');
      expect(session.refreshToken, isNull);
      expect(session.expiresAt, isNull);
    });

    test('decodes a legacy AniList blob (no refresh token)', () {
      final raw = encodeTrackerSessionJson({
        'access_token': 'anilist-at',
        'expires_at': 2000,
        'username': 'alice',
        'created_at': 1000,
      });

      final session = TrackerSession.decode(raw, service: TrackerService.anilist);

      expect(session.accessToken, 'anilist-at');
      expect(session.expiresAt, 2000);
      expect(session.refreshToken, isNull);
    });

    test('decodes a legacy MAL blob', () {
      final raw = encodeTrackerSessionJson({
        'access_token': 'mal-at',
        'refresh_token': 'mal-rt',
        'expires_at': 2000,
        'username': 'bob',
        'created_at': 1000,
      });

      final session = TrackerSession.decode(raw, service: TrackerService.mal);

      expect(session.refreshToken, 'mal-rt');
      expect(session.expiresAt, 2000);
    });

    test('decodes a legacy Trakt blob and defaults the scope', () {
      final raw = encodeTrackerSessionJson({
        'access_token': 'trakt-at',
        'refresh_token': 'trakt-rt',
        'expires_at': 2000,
        'created_at': 1000,
      });

      final session = TrackerSession.decode(raw, service: TrackerService.trakt);

      expect(session.refreshToken, 'trakt-rt');
      expect(session.scope, 'public');
    });

    test('rejects a MAL/Trakt blob missing the refresh token', () {
      for (final service in const [TrackerService.mal, TrackerService.trakt]) {
        final raw = encodeTrackerSessionJson({'access_token': 'at', 'expires_at': 2000, 'created_at': 1000});

        expect(
          () => TrackerSession.decode(raw, service: service),
          throwsA(isA<TrackerAuthException>()),
          reason: '${service.name} must require a refresh token',
        );
      }
    });

    test('rejects a MAL/Trakt blob with an empty refresh token', () {
      for (final service in const [TrackerService.mal, TrackerService.trakt]) {
        final raw = encodeTrackerSessionJson({
          'access_token': 'at',
          'refresh_token': '',
          'expires_at': 2000,
          'created_at': 1000,
        });

        expect(
          () => TrackerSession.decode(raw, service: service),
          throwsA(isA<TrackerAuthException>()),
          reason: '${service.name} must reject an empty refresh token',
        );
      }
    });

    test('rejects a MAL/AniList/Trakt blob missing the expiry', () {
      final blobs = <TrackerService, Map<String, dynamic>>{
        TrackerService.mal: {'access_token': 'at', 'refresh_token': 'rt', 'created_at': 1000},
        TrackerService.anilist: {'access_token': 'at', 'created_at': 1000},
        TrackerService.trakt: {'access_token': 'at', 'refresh_token': 'rt', 'created_at': 1000},
      };

      blobs.forEach((service, blob) {
        expect(
          () => TrackerSession.decode(encodeTrackerSessionJson(blob), service: service),
          throwsA(isA<TrackerAuthException>()),
          reason: '${service.name} must require an expiry',
        );
      });
    });

    test('Simkl accepts a blob with neither expiry nor refresh token', () {
      final raw = encodeTrackerSessionJson({'access_token': 'at', 'created_at': 1000});

      expect(TrackerSession.decode(raw, service: TrackerService.simkl).accessToken, 'at');
    });
  });
}
