// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import java.util.Locale;

/** Maps Flutter's standard gamepad event names to the Steam HID pad contract. */
final class SteamControllerState {
  private final short[] axes = new short[6];
  private int buttons;

  SteamControllerState() {}

  short[] axes() { return axes.clone(); }
  int buttons() { return buttons; }

  void reset() {
    for (int i = 0; i < axes.length; i++) axes[i] = 0;
    buttons = 0;
  }

  void setButtonBit(int bit, boolean pressed) {
    if (bit < 0 || bit > 14) return;
    if (pressed) buttons |= 1 << bit;
    else buttons &= ~(1 << bit);
  }

  boolean setButton(String name, boolean pressed) {
    String key = normalize(name);
    int bit = switch (key) {
      case "a", "buttona" -> 0;
      case "b", "buttonb" -> 1;
      case "x", "buttonx" -> 2;
      case "y", "buttony" -> 3;
      case "select", "back", "view", "buttonselect" -> 4;
      case "mode", "guide", "home", "steam" -> 5;
      case "start", "buttonstart" -> 6;
      case "leftstick", "leftthumb", "buttonleftstick" -> 7;
      case "rightstick", "rightthumb", "buttonrightstick" -> 8;
      case "leftbumper", "leftshoulder", "lb" -> 9;
      case "rightbumper", "rightshoulder", "rb" -> 10;
      case "dpadup" -> 11;
      case "dpaddown" -> 12;
      case "dpadleft" -> 13;
      case "dpadright" -> 14;
      case "dpadcenter" -> 0;
      case "lefttrigger", "lt" -> { axes[4] = (short) (pressed ? 32767 : 0); yield -1; }
      case "righttrigger", "rt" -> { axes[5] = (short) (pressed ? 32767 : 0); yield -1; }
      default -> -2;
    };
    if (bit == -2) return false;
    if (bit >= 0) {
      setButtonBit(bit, pressed);
    }
    return true;
  }

  boolean setAxis(String name, double value) {
    if (!Double.isFinite(value)) return false;
    String key = normalize(name);
    int index = switch (key) {
      case "leftstickx" -> 0;
      case "leftsticky" -> 1;
      case "rightstickx" -> 2;
      case "rightsticky" -> 3;
      case "lefttrigger" -> 4;
      case "righttrigger" -> 5;
      default -> -1;
    };
    if (index < 0) return false;
    double min = index < 4 ? -1.0 : 0.0;
    axes[index] = (short) (Math.max(min, Math.min(1.0, value)) * 32767);
    return true;
  }

  private static String normalize(String value) {
    return value == null ? "" : value.replaceAll("[^A-Za-z0-9]", "").toLowerCase(Locale.ROOT);
  }
}
