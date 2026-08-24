import 'package:http/http.dart' as http;

/// Fallback stub — should never be called; actual implementation is selected
/// via conditional imports in `media_server_http_client.dart`.
http.Client createPlatformClient() => throw UnsupportedError('No platform HTTP client available');

http.Client createPlexApiClient() => throw UnsupportedError('No platform HTTP client available');

/// No-op: only the `dart:io` implementation has an engine to warm.
Future<void> warmUpPlatformHttpClient() async {}
