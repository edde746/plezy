import '../media/account_preferences.dart';
import '../media/account_preferences_source.dart';
import 'plex_auth_service.dart';

/// plex.tv account-preference source with no long-lived HTTP client.
///
/// [PlexAuthService] instances in this app are short-lived and own their HTTP
/// clients. The factory creates one service per operation, and the `finally`
/// blocks dispose it even when the request fails, so opening this source cannot
/// leak a socket and the source itself needs no `dispose` method.
class PlexAccountPreferencesSource implements AccountPreferencesSource {
  final String _authToken;
  final Future<PlexAuthService> Function() _serviceFactory;

  PlexAccountPreferencesSource({required this._authToken, Future<PlexAuthService> Function()? serviceFactory})
    : _serviceFactory = serviceFactory ?? PlexAuthService.create;

  @override
  AccountPreferencesCapabilities get capabilities => AccountPreferencesCapabilities.plex;

  @override
  Future<AccountPreferences> read() async {
    final service = await _serviceFactory();
    try {
      return await service.getAccountPreferences(_authToken);
    } finally {
      service.dispose();
    }
  }

  @override
  Future<AccountPreferences> write(AccountPreferencesPatch patch) async {
    final service = await _serviceFactory();
    try {
      return await service.updateAccountPreferences(_authToken, patch);
    } finally {
      service.dispose();
    }
  }
}
