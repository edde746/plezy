part of '../../jellyfin_client.dart';

Map<String, dynamic>? _accountConfiguration(Object? userDto) {
  if (userDto is! Map<String, dynamic>) {
    throw const FormatException('MediaBrowser current-user response is not an object');
  }
  final configuration = userDto['Configuration'];
  if (configuration == null) return null;
  if (configuration is Map<String, dynamic>) return configuration;
  throw const FormatException('MediaBrowser user Configuration is not an object');
}

mixin _JellyfinAccountPreferencesMethods on _JellyfinClientInternals {
  Future<AccountPreferences> fetchAccountPreferences() async {
    final response = await _http.get(paths.currentUser);
    throwIfHttpError(response);
    return JellyfinAccountPreferences.fromConfiguration(_accountConfiguration(response.data) ?? const {});
  }

  Future<AccountPreferences> updateAccountPreferences(AccountPreferencesPatch patch) async {
    final readResponse = await _http.get(paths.currentUser);
    throwIfHttpError(readResponse);
    final configuration = _accountConfiguration(readResponse.data);
    if (configuration == null) {
      throw const FormatException('MediaBrowser current-user response omitted Configuration');
    }
    final merged = JellyfinAccountPreferences.mergePatch(configuration, patch);

    final writeResponse = await _http.post(paths.userConfiguration, body: merged);
    throwIfHttpError(writeResponse);
    return JellyfinAccountPreferences.fromConfiguration(merged);
  }
}
