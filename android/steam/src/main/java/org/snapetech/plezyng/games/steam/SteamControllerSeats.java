// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

/** UI-thread-owned controller seats shared by native and Flutter input paths.
 * Device IDs stay local. Seats are assigned on first input and remain stable
 * through focus changes. Disconnect frees just that device's seat.
 */
final class SteamControllerSeats {
  private final Integer[] devices;
  private final SteamControllerState[] states;

  SteamControllerSeats(int count) {
    if (count < 1 || count > 4) throw new IllegalArgumentException("Invalid controller count");
    devices = new Integer[count];
    states = new SteamControllerState[count];
    for (int i = 0; i < count; i++) states[i] = new SteamControllerState();
  }

  int count() { return states.length; }
  SteamControllerState state(int seat) { return states[seat]; }

  int seat(int deviceId) {
    for (int i = 0; i < devices.length; i++) {
      if (devices[i] != null && devices[i] == deviceId) return i;
    }
    for (int i = 0; i < devices.length; i++) {
      if (devices[i] == null) {
        devices[i] = deviceId;
        states[i].reset();
        return i;
      }
    }
    return -1; // Never combine excess controllers with player one.
  }

  int disconnect(int deviceId) {
    for (int i = 0; i < devices.length; i++) {
      if (devices[i] != null && devices[i] == deviceId) {
        states[i].reset();
        devices[i] = null;
        return i;
      }
    }
    return -1;
  }

  void reset() {
    for (SteamControllerState state : states) state.reset();
  }
}
