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
    assertTrue(options.allowHevc);
  }

  @Test public void newLimitsAndCompatibilityCodecArePreserved() {
    SteamStreamOptions options = SteamStreamOptions.from(Map.of(
        "streamWidth", 1280L, "streamHeight", 720, "streamFps", 30,
        "streamBitrateKbps", 12000, "allowHevc", false));
    assertEquals(1280, options.width);
    assertEquals(720, options.height);
    assertEquals(30, options.fps);
    assertEquals(12000, options.bitrateKbps);
    assertFalse(options.allowHevc);
  }

  @Test public void malformedOrExcessiveLimitsAreRejected() {
    for (Object value : new Object[] {Long.MAX_VALUE, -1, 1921, 1920.5, "1920", true}) {
      assertThrows(IllegalArgumentException.class, () -> SteamStreamOptions.from(Map.of("streamWidth", value)));
    }
    for (Map<?, ?> values : new Map<?, ?>[] {
        Map.of("streamHeight", 721), Map.of("streamFps", 120),
        Map.of("streamBitrateKbps", 50001), Map.of("allowHevc", "false")}) {
      assertThrows(IllegalArgumentException.class, () -> SteamStreamOptions.from(values));
    }
  }
}
