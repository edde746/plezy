// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public final class SteamControllerStateTest {
  @Test public void standardButtonsUseTheSteamPadBitLayout() {
    SteamControllerState state = new SteamControllerState();

    assertTrue(state.setButton("a", true));
    assertTrue(state.setButton("leftBumper", true));
    assertTrue(state.setButton("dpadUp", true));
    assertEquals((1 << 0) | (1 << 9) | (1 << 11), state.buttons());
    assertTrue(state.setButton("dpadUp", false));
    assertEquals((1 << 0) | (1 << 9), state.buttons());
    assertFalse(state.setButton("unknown", true));
  }

  @Test public void stickAxesClampAndTriggersRemainUnipolar() {
    SteamControllerState state = new SteamControllerState();

    assertTrue(state.setAxis("leftStickX", -4.0));
    assertTrue(state.setAxis("rightStickY", 4.0));
    assertTrue(state.setAxis("leftTrigger", 0.5));
    assertArrayEquals(new short[] {-32767, 0, 0, 32767, 16383, 0}, state.axes());
    assertTrue(state.setButton("rightTrigger", true));
    assertEquals(32767, state.axes()[5]);
  }

  @Test public void resettingReleasesAllAxesAndButtons() {
    SteamControllerState state = new SteamControllerState();
    state.setButton("b", true);
    state.setAxis("leftStickY", 1.0);

    state.reset();

    assertEquals(0, state.buttons());
    assertArrayEquals(new short[6], state.axes());
  }
}
