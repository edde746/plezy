/// Response from `POST /oauth/device/code`.
///
/// The user enters [userCode] at [verificationUrl]; the app polls
/// `/oauth/device/token` with [deviceCode] every [interval] seconds until
/// [expiresIn] seconds elapse.
class TraktDeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUrl;

  /// URL with the user code prefilled (e.g. `https://trakt.tv/activate/ABC12345`).
  /// Useful for `url_launcher` so the user doesn't have to type the code.
  final String? verificationUrlComplete;

  /// Seconds until the device code expires (typically 600).
  final int expiresIn;

  /// Seconds the app should wait between polls (typically 5).
  final int interval;

  const TraktDeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
    this.verificationUrlComplete,
  });

  factory TraktDeviceCode.fromJson(Map<String, dynamic> json) {
    final verificationUrl = json['verification_url'] as String;
    final userCode = json['user_code'] as String;
    return TraktDeviceCode(
      deviceCode: json['device_code'] as String,
      userCode: userCode,
      verificationUrl: verificationUrl,
      verificationUrlComplete: '$verificationUrl/$userCode',
      expiresIn: (json['expires_in'] as num).toInt(),
      interval: (json['interval'] as num).toInt(),
    );
  }
}

/// Discriminated event emitted by `TraktAuthService.pollDeviceCode`.
sealed class TraktDevicePollEvent {
  const TraktDevicePollEvent();
}

class TraktDevicePollPending extends TraktDevicePollEvent {
  const TraktDevicePollPending();
}

class TraktDevicePollSlowDown extends TraktDevicePollEvent {
  const TraktDevicePollSlowDown();
}

class TraktDevicePollDenied extends TraktDevicePollEvent {
  const TraktDevicePollDenied();
}

class TraktDevicePollExpired extends TraktDevicePollEvent {
  const TraktDevicePollExpired();
}

class TraktDevicePollSuccess extends TraktDevicePollEvent {
  final Map<String, dynamic> tokenResponse;
  const TraktDevicePollSuccess(this.tokenResponse);
}
