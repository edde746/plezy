import 'dart:convert';
import 'package:http/http.dart' as http;
import 'media_server_interface.dart';

class EmbyClient implements MediaServerInterface {
  String? _token;
  String? _serverUrl;
  
  // Emby'nin zorunlu tuttuğu kimlik doğrulama başlık parametreleri
  final String _deviceId = "plezy-custom-id";
  final String _clientName = "plezy";
  final String _version = "1.0.0";

  @override
  Future<bool> login(String url, String username, String password) async {
    _serverUrl = url;
    
    final response = await http.post(
      Uri.parse('$_serverUrl/Users/AuthenticateByName'),
      headers: {
        'Content-Type': 'application/json',
        'X-Emby-Authorization': 'MediaBrowser Client="$_clientName", Device="Mobile", DeviceId="$_deviceId", Version="$_version"',
      },
      body: jsonEncode({
        'Username': username,
        'Pw': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['AccessToken']; // Emby'den dönen token kaydediliyor
      return true;
    }
    return false;
  }

  @override
  String getStreamUrl(String itemId) {
    // Emby için doğrudan oynatma bağlantısı
    return '$_serverUrl/Videos/$itemId/stream?static=true&api_key=$_token';
  }
}
