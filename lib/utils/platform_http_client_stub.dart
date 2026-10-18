import 'package:http/http.dart' as http;

/// Fallback stub — should never be called; actual implementation is selected
/// via conditional imports in `media_server_http_client.dart`.
http.Client createPlatformClient({Duration connectTimeout = Duration.zero}) =>
    throw UnsupportedError('No platform HTTP client available');
