// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import static org.junit.Assert.*;
import java.util.Map;
import org.junit.Test;

public final class SteamStreamOptionsTest {
  @Test public void oldCallersKeepDefaults() {
    SteamStreamOptions options = SteamStreamOptions.from(Map.of());
    assertEquals(1920, options.width);
    assertEquals(1080, options.height);
    assertEquals(60, options.fps);
    assertEquals(30000, options.bitrateKbps);
    assertEquals(1, options.controllerCount);
    assertEquals(2, options.audioChannels);
    assertTrue(options.allowHevc);
  }

  @Test public void newLimitsAndCompatibilityCodecArePreserved() {
    SteamStreamOptions options = SteamStreamOptions.from(Map.of(
        "streamWidth", 1280L, "streamHeight", 720, "streamFps", 30,
        "streamBitrateKbps", 12000, "allowHevc", false, "controllerCount", 4, "audioChannels", 6));
    assertEquals(1280, options.width);
    assertEquals(720, options.height);
    assertEquals(30, options.fps);
    assertEquals(12000, options.bitrateKbps);
    assertFalse(options.allowHevc);
    assertEquals(4, options.controllerCount);
    assertEquals(6, options.audioChannels);
  }

  @Test public void malformedOrExcessiveLimitsAreRejected() {
    for (Object value : new Object[] {Long.MAX_VALUE, -1, 1921, 1920.5, "1920", true}) {
      assertThrows(IllegalArgumentException.class, () -> SteamStreamOptions.from(Map.of("streamWidth", value)));
    }
    for (Map<?, ?> values : new Map<?, ?>[] {
        Map.of("streamHeight", 721), Map.of("streamFps", 120),
        Map.of("streamBitrateKbps", 50001), Map.of("allowHevc", "false"),
        Map.of("controllerCount", 0), Map.of("controllerCount", 5), Map.of("controllerCount", 1.0),
        Map.of("audioChannels", 3), Map.of("audioChannels", 5), Map.of("audioChannels", 8),
        Map.of("audioChannels", 6.0), Map.of("audioChannels", "6")}) {
      assertThrows(IllegalArgumentException.class, () -> SteamStreamOptions.from(values));
    }
  }
}
