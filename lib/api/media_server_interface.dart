abstract class MediaServerInterface {
  Future<bool> login(String url, String username, String password);
  String getStreamUrl(String itemId);
  // İlerleyen aşamalarda getItems, getPlaybackInfo gibi metodlar buraya eklenecek.
}
