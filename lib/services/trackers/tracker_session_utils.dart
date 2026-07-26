import 'dart:convert' as convert;

/// Current epoch time in seconds, matching tracker OAuth expiry fields.
int trackerSessionNowEpochSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

bool isTrackerTokenExpired(int expiresAt, {int? nowSeconds}) =>
    (nowSeconds ?? trackerSessionNowEpochSeconds()) >= expiresAt;

bool trackerTokenNeedsRefresh(int expiresAt, {int refreshWindowSeconds = 300, int? nowSeconds}) =>
    (nowSeconds ?? trackerSessionNowEpochSeconds()) >= expiresAt - refreshWindowSeconds;

String encodeTrackerSessionJson(Map<String, dynamic> value) => convert.json.encode(value);

T decodeTrackerSessionJson<T>(String raw, T Function(Map<String, dynamic> json) fromJson) {
  return fromJson(convert.json.decode(raw) as Map<String, dynamic>);
}
