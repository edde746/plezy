/// Result of requesting a device code from an RFC 8628 authorization server.
///
/// The user enters [userCode] at [verificationUrl]; the app polls the token
/// endpoint with [deviceCode] every [interval] seconds until [expiresIn]
/// seconds elapse.
class DeviceCode {
  final String deviceCode;
  final String userCode;
  final String verificationUrl;

  /// URL with the code pre-filled (e.g. `https://trakt.tv/activate/ABC12345`)
  /// when the provider supports it. Nullable — Simkl doesn't.
  final String? verificationUrlComplete;

  final int expiresIn;
  final int interval;

  const DeviceCode({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUrl,
    required this.expiresIn,
    required this.interval,
    this.verificationUrlComplete,
  });
}

/// Discriminated event emitted by a device-code poll loop.
sealed class DevicePollEvent {
  const DevicePollEvent();
}

class DevicePollPending extends DevicePollEvent {
  const DevicePollPending();
}

class DevicePollSlowDown extends DevicePollEvent {
  const DevicePollSlowDown();
}

class DevicePollDenied extends DevicePollEvent {
  const DevicePollDenied();
}

class DevicePollExpired extends DevicePollEvent {
  const DevicePollExpired();
}

class DevicePollSuccess extends DevicePollEvent {
  final Map<String, dynamic> tokenResponse;
  const DevicePollSuccess(this.tokenResponse);
}
