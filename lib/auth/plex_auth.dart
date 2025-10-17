import 'dart:convert';
import 'package:http/http.dart' as http;

class PlexAuth {
  static const String authUrl = 'https://plex.tv/api/v2';
  static const String clientsUrl = 'https://clients.plex.tv/api/v2';

  final String clientIdentifier;
  final String product;

  PlexAuth({
    required this.clientIdentifier,
    this.product = 'Plex Flutter Client',
  });

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'X-Plex-Client-Identifier': clientIdentifier,
    'X-Plex-Product': product,
  };

  /// Generate a PIN for authentication
  Future<Map<String, dynamic>> generatePin({bool strong = true}) async {
    final response = await http.post(
      Uri.parse('$authUrl/pins?strong=$strong'),
      headers: _headers,
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to generate PIN: ${response.body}');
    }
  }

  /// Check PIN status
  Future<Map<String, dynamic>> checkPin(int pinId) async {
    final response = await http.get(
      Uri.parse('$authUrl/pins/$pinId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check PIN: ${response.body}');
    }
  }

  /// Get auth app URL for user to authenticate
  String getAuthAppUrl(String code, {String? forwardUrl}) {
    final params = {
      'clientID': clientIdentifier,
      'code': code,
      'context[device][product]': product,
      if (forwardUrl != null) 'forwardUrl': forwardUrl,
    };

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return 'https://app.plex.tv/auth#?$queryString';
  }

  /// Verify token validity
  Future<bool> verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$authUrl/user'),
        headers: {..._headers, 'X-Plex-Token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get user info
  Future<Map<String, dynamic>> getUserInfo(String token) async {
    final response = await http.get(
      Uri.parse('$authUrl/user'),
      headers: {..._headers, 'X-Plex-Token': token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user info: ${response.body}');
    }
  }

  /// Get available resources (servers)
  Future<List<dynamic>> getResources(String token) async {
    final response = await http.get(
      Uri.parse(
        '$clientsUrl/resources?includeHttps=1&includeRelay=1&includeIPv6=1',
      ),
      headers: {..._headers, 'X-Plex-Token': token},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get resources: ${response.body}');
    }
  }
}
