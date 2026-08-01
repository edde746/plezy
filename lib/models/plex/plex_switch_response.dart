/// INVARIANT (#1488): a successful token mint must never be lost to parsing
/// of decorative fields. `authToken` is the only field any caller consumes
/// (see plex_home_switch.dart), so nothing else on the `/switch` body is
/// read. Plex has changed field shapes on this endpoint before (July 2026:
/// profile language lists became CSV strings), and each drift used to brick
/// token minting outright.
String parsePlexSwitchAuthToken(Map<String, dynamic> json) {
  final authToken = json['authToken'];
  if (authToken is! String || authToken.isEmpty) {
    throw const FormatException('Plex /switch response has no usable authToken');
  }
  return authToken;
}
