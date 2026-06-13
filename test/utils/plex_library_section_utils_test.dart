import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/plex_library_section_utils.dart';

void main() {
  group('plexLibrarySectionIdFromString', () {
    test('parses sectionID from a recentlyAdded home-hub query string', () {
      // #1282: the section is carried in the query, not the path.
      expect(plexLibrarySectionIdFromString('/hubs/home/recentlyAdded?type=2&sectionID=2'), 2);
    });

    test('path section still wins over query params', () {
      expect(plexLibrarySectionIdFromString('/library/sections/3/all?genre=5'), 3);
    });

    test('accepts a plain numeric id', () {
      expect(plexLibrarySectionIdFromString('7'), 7);
    });

    test('accepts librarySectionID in a query string', () {
      expect(plexLibrarySectionIdFromString('/hubs/sections/all?librarySectionID=9'), 9);
    });

    test('returns null for shared / null', () {
      expect(plexLibrarySectionIdFromString('shared'), isNull);
      expect(plexLibrarySectionIdFromString(null), isNull);
    });

    test('returns null when no section is present anywhere', () {
      expect(plexLibrarySectionIdFromString('/hubs/home/recentlyAdded?type=1'), isNull);
    });
  });
}
