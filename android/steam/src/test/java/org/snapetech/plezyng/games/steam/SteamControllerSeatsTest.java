// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import static org.junit.Assert.*;
import org.junit.Test;

public final class SteamControllerSeatsTest {
  @Test public void tvNavigationDoesNotTakeTheSingleControllerSeat() {
    SteamControllerSeats seats = new SteamControllerSeats(1);
    seats.navigationButton(100, 11, true);
    assertEquals(1 << 11, seats.navigation().buttons());
    assertEquals(0, seats.seat(200));
    seats.state(0).setButton("a", true);
    assertEquals(0, seats.disconnect(100));
    assertEquals(0, seats.navigation().buttons());
    assertEquals(1, seats.state(0).buttons());
    seats.navigationButton(100, 12, true);
    seats.reset();
    assertEquals(0, seats.navigation().buttons());
    assertEquals(0, seats.state(0).buttons());
  }

  @Test public void compositeDeviceDisconnectReleasesNavigationAndItsPad() {
    SteamControllerSeats seats = new SteamControllerSeats(4);
    seats.seat(1);
    int seat = seats.seat(2);
    seats.navigationButton(2, 14, true);
    seats.state(seat).setButton("b", true);
    assertEquals(seat, seats.disconnect(2));
    assertEquals(0, seats.navigation().buttons());
    assertEquals(0, seats.state(seat).buttons());
  }

  @Test public void devicesShareTheirOwnStateAcrossInputPaths() {
    SteamControllerSeats seats = new SteamControllerSeats(4);
    int nativeSeat = seats.seat(201), flutterSeat = seats.seat(201);
    assertEquals(nativeSeat, flutterSeat);
    seats.state(nativeSeat).setAxis("leftStickX", .5);
    seats.state(flutterSeat).setButton("a", true);
    assertEquals(16383, seats.state(nativeSeat).axes()[0]);
    assertEquals(1, seats.state(nativeSeat).buttons());
    int other = seats.seat(900);
    seats.state(other).setButton("b", true);
    assertEquals(2, seats.state(other).buttons());
    assertEquals(1, seats.state(nativeSeat).buttons());
  }

  @Test public void disconnectReleasesOnlyItsSeatAndSlotCanBeReused() {
    SteamControllerSeats seats = new SteamControllerSeats(2);
    int first = seats.seat(1), second = seats.seat(2);
    seats.state(first).setButton("a", true);
    seats.state(second).setAxis("rightTrigger", 1);
    assertEquals(first, seats.disconnect(1));
    assertEquals(0, seats.state(first).buttons());
    assertEquals(32767, seats.state(second).axes()[5]);
    assertEquals(second, seats.seat(2));
    assertEquals(first, seats.seat(3));
    assertEquals(-1, seats.disconnect(1));
  }

  @Test public void excessDevicesNeverFallBackToPlayerOne() {
    SteamControllerSeats seats = new SteamControllerSeats(1);
    assertEquals(0, seats.seat(2));
    seats.state(0).setButton("a", true);
    assertEquals(-1, seats.seat(3));
    assertEquals(1, seats.state(0).buttons());
    assertEquals(-1, seats.disconnect(3));
    assertEquals(1, seats.state(0).buttons());
  }

  @Test public void focusResetNeutralizesAllSeatsWithoutReorderingPlayers() {
    SteamControllerSeats seats = new SteamControllerSeats(4);
    for (int i = 0; i < 4; i++) {
      assertEquals(i, seats.seat(100 + i));
      seats.state(i).setAxis("leftStickY", -1);
      seats.state(i).setButtonBit(i, true);
    }
    seats.reset();
    for (int i = 3; i >= 0; i--) {
      assertEquals(i, seats.seat(100 + i));
      assertEquals(0, seats.state(i).buttons());
      assertArrayEquals(new short[6], seats.state(i).axes());
    }
  }

  @Test public void invalidCountsAreRejected() {
    assertThrows(IllegalArgumentException.class, () -> new SteamControllerSeats(0));
    assertThrows(IllegalArgumentException.class, () -> new SteamControllerSeats(5));
  }
}
