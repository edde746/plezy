import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/plex/plex_home.dart';

void main() {
  test('PlexHome tolerates scalar drift from the account API', () {
    final home = PlexHome.fromJson({'id': '7', 'name': 42, 'users': <dynamic>[]});

    expect(home.id, 7);
    expect(home.users, isEmpty);
  });
}
