import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/services/base_peer_service.dart';
import 'package:plezy/widgets/companion_remote/discovery_view.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('typed peer errors are classified without parsing localized text', () {
    expect(
      companionRemotePairingErrorMessage(const PeerError(type: PeerErrorType.timeout, message: 'Délai dépassé')),
      t.companionRemote.pairing.connectionTimedOut,
    );
    expect(
      companionRemotePairingErrorMessage(const PeerError(type: PeerErrorType.invalidSession, message: 'Sitzung fehlt')),
      t.companionRemote.pairing.sessionNotFound,
    );
    expect(
      companionRemotePairingErrorMessage(
        const PeerError(type: PeerErrorType.authFailed, message: 'Échec de l’authentification'),
      ),
      t.companionRemote.pairing.authFailed,
    );
  });

  test('typed fallback errors preserve their localized producer message', () {
    expect(
      companionRemotePairingErrorMessage(
        const PeerError(type: PeerErrorType.networkError, message: 'Localized network failure'),
      ),
      'Localized network failure',
    );
  });
}
