import '../media/account_preferences.dart';
import '../media/account_preferences_source.dart';
import 'jellyfin_client.dart';

class MediaBrowserAccountPreferencesSource implements AccountPreferencesSource {
  const MediaBrowserAccountPreferencesSource(this._client);

  final JellyfinClient _client;

  @override
  AccountPreferencesCapabilities get capabilities => AccountPreferencesCapabilities.mediaBrowser;

  @override
  Future<AccountPreferences> read() => _client.fetchAccountPreferences();

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch) => _client.updateAccountPreferences(patch);
}
