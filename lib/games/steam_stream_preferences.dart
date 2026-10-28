/// Requested ceilings, not claims about the negotiated stream or network.
/// Keep the default identical to older receivers: 1080p60 at 30 Mbps.
enum SteamStreamQuality {
  balanced(1920, 1080, 60, 30000),
  reducedBandwidth(1280, 720, 60, 12000),
  sharperPicture(1920, 1080, 60, 50000),
  reducedFrameRate(1920, 1080, 30, 15000);

  const SteamStreamQuality(this.width, this.height, this.fps, this.bitrateKbps);
  final int width, height, fps, bitrateKbps;

  Map<String, int> get nativeArguments => {
    'streamWidth': width,
    'streamHeight': height,
    'streamFps': fps,
    'streamBitrateKbps': bitrateKbps,
  };
}

enum SteamStreamCodec { automatic, h264 }

/// The receiver may negotiate fewer channels or retry with stereo when the
/// host omits a verifiable multichannel mapping or the output cannot open it.
enum SteamStreamAudio {
  stereo(2),
  quad(4),
  surround51(6);

  const SteamStreamAudio(this.channels);
  final int channels;
}
