// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import java.util.Map;

/** Bounded optional arguments; older Flutter/Activity callers retain defaults. */
final class SteamStreamOptions {
  final int width, height, fps, bitrateKbps;
  final boolean allowHevc;

  private SteamStreamOptions(Map<?, ?> args) {
    width = integer(args, "streamWidth", 1920, 640, 1920);
    height = integer(args, "streamHeight", 1080, 360, 1080);
    fps = integer(args, "streamFps", 60, 15, 60);
    bitrateKbps = integer(args, "streamBitrateKbps", 30000, 1000, 50000);
    if (width % 2 != 0 || height % 2 != 0) throw new IllegalArgumentException("Invalid stream dimensions");
    Object hevc = args.get("allowHevc");
    if (hevc != null && !(hevc instanceof Boolean)) throw new IllegalArgumentException("Invalid codec option");
    allowHevc = !Boolean.FALSE.equals(hevc);
  }

  static SteamStreamOptions from(Map<?, ?> args) { return new SteamStreamOptions(args); }

  private static int integer(Map<?, ?> args, String key, int fallback, int min, int max) {
    Object value = args.get(key);
    if (value == null) return fallback;
    if (!(value instanceof Integer) && !(value instanceof Long)) throw new IllegalArgumentException("Invalid stream limit");
    long number = ((Number) value).longValue();
    if (number < min || number > max) throw new IllegalArgumentException("Stream limit out of range");
    return (int) number;
  }
}
