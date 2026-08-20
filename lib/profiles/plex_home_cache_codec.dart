import 'dart:convert';

import '../models/plex/plex_home_user.dart';

List<Map<String, dynamic>> encodePlexHomeUsersCache(List<PlexHomeUser> users) {
  return users.map((user) => user.toJson()).toList(growable: false);
}

String encodePlexHomeUsersCacheJson(List<PlexHomeUser> users) {
  return jsonEncode(encodePlexHomeUsersCache(users));
}

List<PlexHomeUser> decodePlexHomeUsersCache(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! List) {
    throw const FormatException('Plex Home users cache is not a list');
  }
  return decoded.whereType<Map<String, dynamic>>().map(PlexHomeUser.fromJson).toList(growable: false);
}
