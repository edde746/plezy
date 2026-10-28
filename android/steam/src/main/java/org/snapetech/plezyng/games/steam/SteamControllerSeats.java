// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

/** UI-thread-owned controller seats shared by native and Flutter input paths.
 * Device IDs stay local. Seats are assigned on first input and remain stable
 * through focus changes. Disconnect frees just that device's seat.
 */
final class SteamControllerSeats {
  private final Integer[] devices;
  private final SteamControllerState[] states;
  private final SteamControllerState navigation = new SteamControllerState();
  private Integer navigationDevice;

  SteamControllerSeats(int count) {
    if (count < 1 || count > 4) throw new IllegalArgumentException("Invalid controller count");
    devices = new Integer[count];
    states = new SteamControllerState[count];
    for (int i = 0; i < count; i++) states[i] = new SteamControllerState();
  }

  int count() { return states.length; }
  SteamControllerState state(int seat) { return states[seat]; }
  SteamControllerState navigation() { return navigation; }

  /** A TV's navigation-only remote assists player one without taking a pad seat. */
  void navigationButton(int deviceId, int bit, boolean pressed) {
    if (navigationDevice != null && navigationDevice != deviceId) navigation.reset();
    navigationDevice = deviceId;
    navigation.setButtonBit(bit, pressed);
  }

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
    boolean navigationRemoved = navigationDevice != null && navigationDevice == deviceId;
    if (navigationRemoved) {
      navigation.reset();
      navigationDevice = null;
    }
    for (int i = 0; i < devices.length; i++) {
      if (devices[i] != null && devices[i] == deviceId) {
        states[i].reset();
        devices[i] = null;
        return i;
      }
    }
    return navigationRemoved ? 0 : -1;
  }

  void reset() {
    for (SteamControllerState state : states) state.reset();
    navigation.reset();
  }
}
