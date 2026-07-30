import 'media_server_interface.dart';

class JellyfinClient implements MediaServerInterface {
  // Projedeki mevcut Jellyfin giriş ve stream metodlarını buraya taşıyıp bağlamalısın.
  
  @override
  Future<bool> login(String url, String username, String password) async {
    // Mevcut Plezy Jellyfin login kodları buraya gelecek
    return true; 
  }

  @override
  String getStreamUrl(String itemId) {
    // Mevcut Plezy Jellyfin stream URL oluşturma kodları buraya gelecek
    return ''; 
  }
}
