/// Read-only metadata. It never establishes ownership or permission to launch.
class SteamGameActivity {
  const SteamGameActivity({
    required this.achievements,
    required this.news,
    required this.friends,
    required this.achievementsAvailable,
    required this.newsAvailable,
    required this.friendsAvailable,
    required this.friendsRequested,
    required this.truncated,
  });
  final List<SteamAchievement> achievements;
  final List<SteamNewsItem> news;
  final List<SteamPlayingFriend> friends;
  final bool achievementsAvailable, newsAvailable, friendsAvailable, friendsRequested, truncated;

  factory SteamGameActivity.fromJson(Map<String, dynamic> data, {required int appId, required String steamId}) {
    if (data['appId'] != appId || data['steamId'] != steamId) {
      throw const FormatException('Steam activity identity mismatch');
    }
    List<T> rows<T>(String key, int limit, T Function(Map<String, dynamic>) parse) {
      final values = data[key];
      if (values == null) return [];
      if (values is! List || values.length > limit) throw const FormatException('Invalid Steam activity size');
      return values.map((row) => parse(Map<String, dynamic>.from(row as Map))).toList(growable: false);
    }

    return SteamGameActivity(
      achievements: rows('achievements', 1000, SteamAchievement.fromJson),
      news: rows('news', 10, SteamNewsItem.fromJson),
      friends: rows('friends', 100, SteamPlayingFriend.fromJson),
      achievementsAvailable: data['achievementsAvailable'] == true,
      newsAvailable: data['newsAvailable'] == true,
      friendsAvailable: data['friendsAvailable'] == true,
      friendsRequested: data['friendsRequested'] == true,
      truncated: data['achievementsTruncated'] == true || data['friendsTruncated'] == true,
    );
  }
}

String _text(Object? value, int limit) {
  if (value is! String || value.length > limit * 2) throw const FormatException('Invalid Steam text');
  return value.replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f\u202a-\u202e\u2066-\u2069]'), '').trim();
}

class SteamAchievement {
  SteamAchievement.fromJson(Map<String, dynamic> data)
    : hidden = data['hidden'] == true,
      unlocked = data['unlocked'] == true,
      name = data['hidden'] == true ? '' : _text(data['name'], 256),
      description = data['hidden'] == true ? '' : _text(data['description'], 1024);
  final String name, description;
  final bool hidden, unlocked;
}

class SteamNewsItem {
  SteamNewsItem.fromJson(Map<String, dynamic> data)
    : title = _text(data['title'], 256),
      feed = _text(data['feed'], 128),
      date = _date(data['date']);
  final String title, feed;
  final DateTime date;
  static DateTime _date(Object? value) {
    if (value is! int || value < 0 || value > 253402300799) throw const FormatException('Invalid Steam date');
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true);
  }
}

class SteamPlayingFriend {
  SteamPlayingFriend.fromJson(Map<String, dynamic> data)
    : name = _text(data['name'], 128),
      steamId = _id(data['steamId']);
  final String name, steamId;
  static String _id(Object? value) {
    if (value is! String || !RegExp(r'^\d{17}$').hasMatch(value)) throw const FormatException('Invalid Steam identity');
    return value;
  }
}

enum SteamDestination { store, community, workshop, news }

Uri steamDestination(int appId, SteamDestination destination) {
  if (appId < 1 || appId > 0xffffffff) throw const FormatException('Invalid Steam AppID');
  return switch (destination) {
    SteamDestination.store => Uri.https('store.steampowered.com', '/app/$appId/'),
    SteamDestination.community => Uri.https('steamcommunity.com', '/app/$appId/'),
    SteamDestination.workshop => Uri.https('steamcommunity.com', '/app/$appId/workshop/'),
    SteamDestination.news => Uri.https('store.steampowered.com', '/news/app/$appId'),
  };
}
