import '../media/account_preferences.dart';
import '../media/account_preferences_source.dart';
import '../media/media_browser_dialect.dart';
import 'jellyfin_client.dart';

class MediaBrowserAccountPreferencesSource implements AccountPreferencesSource {
  const MediaBrowserAccountPreferencesSource(this._client);

  final JellyfinClient _client;

  /// Emby drops the rewatching switch — see
  /// [MediaBrowserDialect.supportsNextUpRewatching].
  @override
  AccountPreferencesCapabilities get capabilities => _client.dialect == MediaBrowserDialect.emby
      ? AccountPreferencesCapabilities.emby
      : AccountPreferencesCapabilities.jellyfin;

  @override
  Future<AccountPreferences> read() => _client.fetchAccountPreferences(checkCurrent: _captureIdentity());

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch, {void Function()? checkCurrent}) =>
      _client.updateAccountPreferences(patch, checkCurrent: _captureIdentity(checkCurrent));

  void Function() _captureIdentity([void Function()? checkCurrent]) {
    final authentication = _client.authenticationSessionId;
    return () {
      checkCurrent?.call();
      if (!identical(_client.authenticationSessionId, authentication)) {
        throw StateError('Account authentication changed');
      }
    };
  }
}
