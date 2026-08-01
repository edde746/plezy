import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_home.dart';

void main() {
  test('PlexHome tolerates scalar drift from the account API', () {
    final home = PlexHome.fromJson({
      'id': '7',
      'name': 42,
      'guestUserID': '9',
      'guestUserUUID': 123,
      'guestEnabled': 1,
      'subscription': 'true',
      'users': <dynamic>[],
    });

    expect(home.id, 7);
    expect(home.name, '42');
    expect(home.guestUserID, 9);
    expect(home.guestUserUUID, '123');
    expect(home.guestEnabled, isTrue);
    expect(home.subscription, isTrue);
  });
}
