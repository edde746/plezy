/// Minimal Trakt user info parsed from `GET /users/settings`.
class TraktUser {
  final String username;
  final String? name;

  const TraktUser({required this.username, this.name});

  factory TraktUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    if (user == null) {
      throw const FormatException('Trakt /users/settings response missing "user" field');
    }
    return TraktUser(username: user['username'] as String, name: user['name'] as String?);
  }
}
