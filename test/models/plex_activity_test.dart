import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_activity.dart';

void main() {
  test('PlexActivity tolerates stringified and scalar fields', () {
    final activity = PlexActivity.fromJson({
      'uuid': 42,
      'type': 7,
      'title': true,
      'subtitle': 99,
      'progress': '75',
      'cancellable': '1',
    });

    expect(activity.uuid, '42');
    expect(activity.type, '7');
    expect(activity.title, 'true');
    expect(activity.subtitle, '99');
    expect(activity.progress, 75);
    expect(activity.cancellable, isTrue);
  });
}
