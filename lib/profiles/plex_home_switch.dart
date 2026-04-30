import '../exceptions/media_server_exceptions.dart';
import '../services/plex_auth_service.dart';
import '../utils/app_logger.dart';

/// Outcome of a Plex Home user switch attempt.
enum PlexHomeSwitchStatus { success, cancelled, failed }

class PlexHomeSwitchResult {
  final PlexHomeSwitchStatus status;
  final String? userToken;

  const PlexHomeSwitchResult._(this.status, this.userToken);

  bool get succeeded => status == PlexHomeSwitchStatus.success;
}

/// Callback that prompts the user for a Plex Home PIN during a single
/// `/home/users/{uuid}/switch` round-trip. The profile context is captured
/// by the caller. Returns the PIN string, or `null` if the user cancelled.
typedef PlexHomeSwitchPinPrompt = Future<String?> Function({String? errorMessage});

/// Switch into [homeUserUuid] on the account identified by [accountToken],
/// looping on Plex error code 1041 (invalid PIN). Returns the freshly minted
/// user-level token.
///
/// Pass [requiresPin] = true when the Home user has Plex's `protected` flag
/// set; otherwise the call is attempted without a PIN first and the loop
/// only kicks in if Plex returns 1041 anyway.
///
/// Used by both [ActiveProfileBinder] (lazy-fetching a missing token on
/// activation) and the borrow flow (minting an independent token for a
/// borrower). See `lib/profiles/active_profile_binder.dart` and
/// `lib/screens/profile/borrow_connection_screen.dart`.
Future<PlexHomeSwitchResult> switchPlexHomeUserWithPin({
  required PlexAuthService auth,
  required String accountToken,
  required String homeUserUuid,
  required bool requiresPin,
  required PlexHomeSwitchPinPrompt promptForPin,
  String? logLabel,
}) async {
  String? pin;
  String? error;
  while (true) {
    if (requiresPin) {
      pin = await promptForPin(errorMessage: error);
      if (pin == null) return const PlexHomeSwitchResult._(PlexHomeSwitchStatus.cancelled, null);
    }
    try {
      final response = await auth.switchToUser(homeUserUuid, accountToken, pin: pin);
      return PlexHomeSwitchResult._(PlexHomeSwitchStatus.success, response.authToken);
    } on MediaServerHttpException catch (e) {
      if (e.statusCode == 403 && _isInvalidPin(e)) {
        error = 'Incorrect PIN. Please try again.';
        pin = null;
        // Force the next iteration to prompt even when the caller didn't
        // expect a PIN — Plex disagrees about whether one is required.
        requiresPin = true;
        continue;
      }
      appLogger.e('switchPlexHomeUserWithPin failed${logLabel == null ? '' : ' for $logLabel'}', error: e);
      return const PlexHomeSwitchResult._(PlexHomeSwitchStatus.failed, null);
    } catch (e, st) {
      appLogger.e(
        'switchPlexHomeUserWithPin failed${logLabel == null ? '' : ' for $logLabel'}',
        error: e,
        stackTrace: st,
      );
      return const PlexHomeSwitchResult._(PlexHomeSwitchStatus.failed, null);
    }
  }
}

bool _isInvalidPin(MediaServerHttpException e) {
  final data = e.responseData;
  if (data is! Map) return false;
  final errors = data['errors'];
  if (errors is! List || errors.isEmpty) return false;
  final first = errors.first;
  return first is Map && first['code'] == 1041;
}
