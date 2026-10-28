import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/platform_http_client_stub.dart'
    if (dart.library.io) '../utils/platform_http_client_io.dart'
    as platform;
import 'plezy_server.dart';

/// Resolves a curated storefront handoff to an approved affiliate link.
///
/// Affiliate IDs and network API tokens live on the server. Failures return
/// null so callers can preserve the direct official storefront link.
class ComicCommerceLinkClient {
  final http.Client _http;

  ComicCommerceLinkClient({http.Client? httpClient}) : _http = httpClient ?? platform.createPlatformClient();

  void dispose() => _http.close();

  Future<Uri?> resolve({required String providerId, required Uri destination, String? isbn}) async {
    if (destination.scheme != 'https' || destination.userInfo.isNotEmpty || destination.fragment.isNotEmpty) {
      return null;
    }

    try {
      final response = await _http
          .post(
            Uri.parse('$plezyComicCommerceBaseUrl/commerce/comic-link'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'providerId': providerId,
              'destinationUrl': destination.toString(),
              if (isbn != null && isbn.isNotEmpty) 'isbn': isbn,
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200 || response.bodyBytes.length > 16 * 1024) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic> || decoded['tracked'] != true) return null;
      final value = decoded['url'];
      if (value is! String) return null;
      final uri = Uri.tryParse(value);
      if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty || uri.fragment.isNotEmpty) return null;
      return uri;
    } on Object {
      return null;
    }
  }
}
