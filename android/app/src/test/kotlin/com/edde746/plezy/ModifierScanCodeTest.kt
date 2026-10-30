package com.edde746.plezy

import android.view.InputDevice
import android.view.KeyEvent
import io.flutter.embedding.android.KeyEmbedderResponder
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer
import java.nio.ByteOrder
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ModifierScanCodeTest {
  private data class FlutterKey(val type: Long, val physical: Long, val logical: Long, val synthesized: Boolean)

  private companion object {
    const val DOWN = 0L
    const val UP = 1L
    const val LOGICAL_SELECT = 0x0010000050CL
    const val PHYSICAL_ANDROID_DPAD_CENTER = 0x01100000017L
    const val SCAN_RIGHT_CTRL = 97
  }

  private fun key(action: Int, keyCode: Int, scanCode: Int) = KeyEvent(
    0,
    0,
    action,
    keyCode,
    0,
    0,
    1,
    scanCode,
    KeyEvent.FLAG_FROM_SYSTEM,
    InputDevice.SOURCE_KEYBOARD or InputDevice.SOURCE_DPAD
  )

  /** Feeds [events] through Flutter's Android key responder and returns what the framework receives. */
  private fun flutterKeysFor(vararg events: KeyEvent): Pair<List<FlutterKey>, KeyEmbedderResponder> {
    val received = mutableListOf<FlutterKey>()
    val messenger = object : BinaryMessenger {
      override fun send(channel: String, message: ByteBuffer?) = send(channel, message, null)

      override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {
        val packet = message!!.duplicate().order(ByteOrder.LITTLE_ENDIAN)
        packet.rewind()
        packet.getLong() // character size
        packet.getLong() // timestamp
        received += FlutterKey(packet.getLong(), packet.getLong(), packet.getLong(), packet.getLong() != 0L)
      }

      override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {}
    }
    val responder = KeyEmbedderResponder(messenger)
    for (event in events) responder.handleEvent(event) {}
    return received to responder
  }

  @Test
  fun okSentWithRightCtrlScanCodeReachesFlutterAsSelectPressAndRelease() {
    val down = key(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_CENTER, SCAN_RIGHT_CTRL)
    val up = key(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_DPAD_CENTER, SCAN_RIGHT_CTRL)

    val (received, responder) = flutterKeysFor(down.withoutModifierScanCode(), up.withoutModifierScanCode())

    assertEquals(
      listOf(
        FlutterKey(DOWN, PHYSICAL_ANDROID_DPAD_CENTER, LOGICAL_SELECT, synthesized = false),
        FlutterKey(UP, PHYSICAL_ANDROID_DPAD_CENTER, LOGICAL_SELECT, synthesized = false)
      ),
      received
    )
    assertTrue(responder.pressedState.isEmpty())
  }

  @Test
  fun eventsFlutterAlreadyMapsCorrectlyAreReturnedAsIs() {
    val realRightCtrl = key(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_CTRL_RIGHT, SCAN_RIGHT_CTRL)
    val keyboardEnter = key(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER, 28)
    val normalized = key(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_DPAD_CENTER, SCAN_RIGHT_CTRL).withoutModifierScanCode()

    assertSame(realRightCtrl, realRightCtrl.withoutModifierScanCode())
    assertSame(keyboardEnter, keyboardEnter.withoutModifierScanCode())
    // Flutter matches its own redispatched events by identity.
    assertSame(normalized, normalized.withoutModifierScanCode())
  }
}
