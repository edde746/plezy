import 'package:flutter/foundation.dart';
import '../client/plex_client.dart';
import '../utils/app_logger.dart';

class PlexClientProvider extends ChangeNotifier {
  PlexClient? _client;

  PlexClient? get client => _client;

  void setClient(PlexClient client) {
    _client = client;
    appLogger.d('PlexClientProvider: Client set');
    notifyListeners();
  }

  void updateToken(String newToken) {
    if (_client != null) {
      _client!.updateToken(newToken);
      appLogger.d('PlexClientProvider: Token updated');
      notifyListeners();
    } else {
      appLogger.w('PlexClientProvider: Cannot update token - no client set');
    }
  }

  void clearClient() {
    _client = null;
    appLogger.d('PlexClientProvider: Client cleared');
    notifyListeners();
  }
}
