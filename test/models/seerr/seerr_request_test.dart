import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/seerr/seerr_request.dart';

void main() {
  group('SeerrRequestPayload', () {
    test('movie request omits TV-only fields', () {
      final body = SeerrRequestPayload.movie(603).toJson();
      expect(body['mediaType'], 'movie');
      expect(body['mediaId'], 603);
      expect(body.containsKey('seasons'), isFalse);
      expect(body.containsKey('tvdbId'), isFalse);
    });

    test('tv request with explicit seasons sends the list', () {
      final body = SeerrRequestPayload.tv(96677, seasons: [1, 3]).toJson();
      expect(body['mediaType'], 'tv');
      expect(body['seasons'], [1, 3]);
    });

    test('tv request without seasons omits the seasons key (= all current+future)', () {
      final body = SeerrRequestPayload.tv(96677).toJson();
      expect(body.containsKey('seasons'), isFalse);
    });

    test('is4k = true is preserved; null is omitted', () {
      final on = SeerrRequestPayload.movie(603, is4k: true).toJson();
      expect(on['is4k'], isTrue);
      final off = SeerrRequestPayload.movie(603).toJson();
      expect(off.containsKey('is4k'), isFalse);
    });
  });

  group('SeerrRequestStatus.fromValue', () {
    test('maps the Overseerr lineage enum values', () {
      expect(SeerrRequestStatus.fromValue(1), SeerrRequestStatus.pendingApproval);
      expect(SeerrRequestStatus.fromValue(2), SeerrRequestStatus.approved);
      expect(SeerrRequestStatus.fromValue(3), SeerrRequestStatus.declined);
      expect(SeerrRequestStatus.fromValue(4), SeerrRequestStatus.failed);
      expect(SeerrRequestStatus.fromValue(5), SeerrRequestStatus.completed);
      // Unknown values default to pending-approval (safer than throwing on a
      // forward-compatible server addition).
      expect(SeerrRequestStatus.fromValue(99), SeerrRequestStatus.pendingApproval);
      expect(SeerrRequestStatus.fromValue(null), SeerrRequestStatus.pendingApproval);
    });
  });

  group('SeerrRequest.fromJson', () {
    test('decodes a movie request', () {
      final r = SeerrRequest.fromJson({
        'id': 12,
        'status': 1,
        'is4k': false,
        'type': 'movie',
        'media': {'id': 1, 'tmdbId': 603, 'status': 2},
        'requestedBy': {'id': 7, 'username': 'edde', 'userType': 4, 'permissions': 0},
      });
      expect(r.id, 12);
      expect(r.status, SeerrRequestStatus.pendingApproval);
      expect(r.media?.tmdbId, 603);
      expect(r.requestedBy?.username, 'edde');
      expect(r.mediaType, 'movie');
    });

    test('decodes a TV request with seasons', () {
      final r = SeerrRequest.fromJson({
        'id': 13,
        'status': 2,
        'is4k': false,
        'type': 'tv',
        'seasons': [
          {'seasonNumber': 1, 'status': 5},
          {'seasonNumber': 2, 'status': 2},
        ],
      });
      expect(r.seasons, hasLength(2));
      expect(r.seasons[0].seasonNumber, 1);
      expect(r.seasons[0].status, SeerrRequestStatus.completed);
    });
  });
}
