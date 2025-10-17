class PlexConfig {
  final String baseUrl;
  final String? token;
  final String clientIdentifier;
  final String product;
  final String version;
  final String platform;
  final String? device;
  final bool acceptJson;

  PlexConfig({
    required this.baseUrl,
    this.token,
    required this.clientIdentifier,
    this.product = 'Plezy',
    this.version = '1.0.0',
    this.platform = 'Flutter',
    this.device,
    this.acceptJson = true,
  });

  Map<String, String> get headers {
    final headers = {
      'X-Plex-Client-Identifier': clientIdentifier,
      'X-Plex-Product': product,
      'X-Plex-Version': version,
      'X-Plex-Platform': platform,
      if (device != null) 'X-Plex-Device': device!,
      if (acceptJson) 'Accept': 'application/json',
    };

    if (token != null) {
      headers['X-Plex-Token'] = token!;
    }

    return headers;
  }

  PlexConfig copyWith({
    String? baseUrl,
    String? token,
    String? clientIdentifier,
    String? product,
    String? version,
    String? platform,
    String? device,
    bool? acceptJson,
  }) {
    return PlexConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      clientIdentifier: clientIdentifier ?? this.clientIdentifier,
      product: product ?? this.product,
      version: version ?? this.version,
      platform: platform ?? this.platform,
      device: device ?? this.device,
      acceptJson: acceptJson ?? this.acceptJson,
    );
  }
}
