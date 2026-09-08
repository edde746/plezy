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

/// Account preferences span two server stores: `UserConfiguration` for the
/// language, subtitle and library fields, and the account's
/// `DisplayPreferences` row for [AccountPreferenceKey.rewatchingInNextUp],
/// which has no `UserConfiguration` field on either dialect.
mixin _JellyfinAccountPreferencesMethods on _JellyfinClientInternals {
  Map<String, String> get _displayPreferencesQuery => {
    'userId': connection.userId,
    'client': JellyfinDisplayPreferences.client,
  };

  Future<AccountPreferences> fetchAccountPreferences({void Function()? checkCurrent}) async {
    // Independent rows on the same server; the pair costs one round trip.
    final responses = await Future.wait([
      _http.get(paths.currentUser),
      _http.get(
        MediaBrowserPaths.displayPreferences(JellyfinDisplayPreferences.displayPreferencesId),
        queryParameters: _displayPreferencesQuery,
      ),
    ]);
    for (final response in responses) {
      throwIfHttpError(response);
    }

    final rewatching = JellyfinDisplayPreferences.readRewatchingInNextUp(responses[1].data);
    checkCurrent?.call();
    _rewatchingInNextUp = rewatching ?? false;
    return JellyfinAccountPreferences.fromConfiguration(
      _accountConfiguration(responses.first.data) ?? const {},
      rewatchingInNextUp: rewatching,
    );
  }

  Future<AccountPreferences> updateAccountPreferences(
    AccountPreferencesPatch patch, {
    void Function()? checkCurrent,
  }) async {
    (dialect == MediaBrowserDialect.emby
            ? AccountPreferencesCapabilities.emby
            : AccountPreferencesCapabilities.jellyfin)
        .validate(patch);
    checkCurrent?.call();
    final rewatchingRequested = patch.contains(AccountPreferenceKey.rewatchingInNextUp);
    final configurationPatch = AccountPreferencesPatch({
      for (final entry in patch.values.entries)
        if (entry.key != AccountPreferenceKey.rewatchingInNextUp) entry.key: entry.value,
    });

    if (rewatchingRequested) {
      await _writeRewatchingInNextUp(
        patch.boolAt(AccountPreferenceKey.rewatchingInNextUp)!,
        checkCurrent: checkCurrent,
      );
    }
    if (configurationPatch.isEmpty) {
      // Re-read so the caller still gets the whole account, including the
      // fields this write did not touch.
      return fetchAccountPreferences(checkCurrent: checkCurrent);
    }

    final readResponse = await _http.get(paths.currentUser);
    throwIfHttpError(readResponse);
    final configuration = _accountConfiguration(readResponse.data);
    if (configuration == null) {
      throw const FormatException('MediaBrowser current-user response omitted Configuration');
    }
    final merged = JellyfinAccountPreferences.mergePatch(configuration, configurationPatch);
    checkCurrent?.call();

    final writeResponse = await _http.post(paths.userConfiguration, body: merged);
    throwIfHttpError(writeResponse);
    checkCurrent?.call();
    return fetchAccountPreferences(checkCurrent: checkCurrent);
  }

  /// Read-modify-write the `DisplayPreferences` row: the `POST` replaces it, so
  /// anything already in `CustomPrefs` has to travel back with the change.
  Future<void> _writeRewatchingInNextUp(bool value, {void Function()? checkCurrent}) async {
    final path = MediaBrowserPaths.displayPreferences(JellyfinDisplayPreferences.displayPreferencesId);
    final readResponse = await _http.get(path, queryParameters: _displayPreferencesQuery);
    throwIfHttpError(readResponse);

    final merged = JellyfinDisplayPreferences.mergeRewatchingInNextUp(readResponse.data, value);
    checkCurrent?.call();
    final writeResponse = await _http.post(path, queryParameters: _displayPreferencesQuery, body: merged);
    throwIfHttpError(writeResponse);
    checkCurrent?.call();
    _rewatchingInNextUp = value;
  }
}
