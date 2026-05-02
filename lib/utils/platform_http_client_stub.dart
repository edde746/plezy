import 'package:http/http.dart' as http;

/// Fallback stub — should never be called; actual implementation is selected
/// via conditional imports in `media_server_http_client.dart`.
http.Client createPlatformClient() => throw UnsupportedError('No platform HTTP client available');

void closePlexClient(http.Client client) => throw UnsupportedError('No platform HTTP client available');