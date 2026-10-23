import 'dart:convert';

import '../models/catalog/mdblist_explore_shelf.dart';
import '../profiles/profile.dart';

/// Selections belong to the active Plezy profile, just like its tracker session.
class MdblistShelfStore {
  static String keyFor(String profileScope) => profileScopedPrefsKey(profileScope, 'mdblist_explore_shelves_v1');

  static List<MdblistExploreShelf> decode(String? raw) {
    if (raw == null) return const [];
    final data = jsonDecode(raw);
    if (data is! List) throw const FormatException('Invalid MDBList shelf settings');
    final shelves = <int, MdblistExploreShelf>{};
    for (final entry in data.whereType<Map>()) {
      final shelf = MdblistExploreShelf.fromJson(entry.cast<String, dynamic>());
      if (shelf != null) shelves.putIfAbsent(shelf.listId, () => shelf);
    }
    return List.unmodifiable(shelves.values);
  }

  static String encode(List<MdblistExploreShelf> shelves) => jsonEncode([for (final shelf in shelves) shelf.toJson()]);
}
