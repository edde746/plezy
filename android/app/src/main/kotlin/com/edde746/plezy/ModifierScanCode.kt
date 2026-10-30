package com.edde746.plezy

import android.view.KeyEvent

// Linux scan codes that Flutter's Android embedder maps to the modifiers it
// reconciles against metaState on every event: KEY_LEFTCTRL, KEY_RIGHTCTRL,
// KEY_LEFTSHIFT, KEY_RIGHTSHIFT, KEY_LEFTALT, KEY_RIGHTALT.
private val MODIFIER_SCAN_CODES = intArrayOf(29, 97, 42, 54, 56, 100)

/**
 * Returns this event without its scan code when a non-modifier key carries a
 * modifier's scan code, else this event itself.
 *
 * Some remote key layouts do that: the Mi Box 3 IR keypad sends OK as
 * KEYCODE_DPAD_CENTER with scan code 97 (KEY_RIGHTCTRL). Flutter derives the
 * physical key from the scan code, so it records Select as pressed under
 * ControlRight; on the release it reconciles modifiers from metaState (no Ctrl
 * held), synthesizes a ControlRight up that clears the record, and drops the
 * real Select up as unpaired. Every press then looks held until the long-press
 * timer fires (#2883). Without a scan code Flutter keys the physical key off
 * the key code instead.
 *
 * Returning the same instance when nothing changes matters: Flutter recognizes
 * a key it redispatches to the view hierarchy by identity, so a fresh copy of
 * an already-normalized event would loop back into the framework.
 */
internal fun KeyEvent.withoutModifierScanCode(): KeyEvent {
  if (scanCode !in MODIFIER_SCAN_CODES || keyCode == KeyEvent.KEYCODE_UNKNOWN || KeyEvent.isModifierKey(keyCode)) {
    return this
  }
  return KeyEvent(downTime, eventTime, action, keyCode, repeatCount, metaState, deviceId, 0, flags, source)
}
