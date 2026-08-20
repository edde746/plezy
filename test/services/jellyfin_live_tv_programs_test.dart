import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/http_fixtures.dart';

void main() {
  test('guide window lower bound is minEndDate so currently-airing programmes are kept', () async {
    // Jellyfin translates MinStartDate to `StartDate >= …`, which drops a
    // programme that began before the window even though it is still running
    // over "now". MinEndDate (`EndDate >= …`) is the overlap filter.
    final captured = <Uri>[];
    final client = testJellyfinClient(
      handler: (request) async {
        captured.add(request.url);
        return jsonResponse({'Items': const <Object?>[]});
      },
    );
    addTearDown(client.close);

    final from = DateTime.utc(2026, 8, 20, 19);
    final to = DateTime.utc(2026, 8, 21, 1);
    await client.fetchLiveTvPrograms(
      channelIds: const ['ch-1', 'ch-2'],
      beginsAt: from.millisecondsSinceEpoch ~/ 1000,
      endsAt: to.millisecondsSinceEpoch ~/ 1000,
    );

    final request = captured.single;
    expect(request.path, '/LiveTv/Programs');
    expect(request.queryParameters['channelIds'], 'ch-1,ch-2');
    expect(request.queryParameters['minEndDate'], from.toIso8601String());
    expect(request.queryParameters['maxStartDate'], to.toIso8601String());
    expect(request.queryParameters.containsKey('minStartDate'), isFalse);
  });

  test('LiveTvSupport.fetchSchedule forwards the window through the same overlap bounds', () async {
    final captured = <Uri>[];
    final client = testJellyfinClient(
      handler: (request) async {
        captured.add(request.url);
        return jsonResponse({'Items': const <Object?>[]});
      },
    );
    addTearDown(client.close);

    final from = DateTime.utc(2026, 8, 20, 19);
    final to = DateTime.utc(2026, 8, 21, 1);
    await client.liveTv.fetchSchedule(from: from, to: to);

    final request = captured.single;
    expect(request.path, '/LiveTv/Programs');
    expect(request.queryParameters['minEndDate'], from.toIso8601String());
    expect(request.queryParameters['maxStartDate'], to.toIso8601String());
    expect(request.queryParameters.containsKey('minStartDate'), isFalse);
  });
}
