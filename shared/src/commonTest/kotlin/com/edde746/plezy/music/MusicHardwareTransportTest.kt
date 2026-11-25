package com.edde746.plezy.music

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Foreground hardware media keys: while a session is live every transport key is consumed for its whole down, repeat
 * and up burst (so it can neither leak to the platform's fallback media-button dispatch nor act on a focused item) and
 * acts once, on the first down.
 */
class MusicHardwareTransportTest {
    private var sessionLive = true
    private val calls = mutableListOf<MusicTransport>()
    private val system = FakeMusicSystem()
    private val handler = MusicHardwareTransport(system, { sessionLive }, { calls += it })

    @Test
    fun actsOnKeyDownOnlyAndConsumesDownRepeatAndUpPerKey() {
        handler.register()
        val cases = mapOf(
            MusicKey.PLAY to MusicTransport.PLAY,
            MusicKey.PAUSE to MusicTransport.PAUSE,
            MusicKey.PLAY_PAUSE to MusicTransport.TOGGLE,
            MusicKey.NEXT to MusicTransport.NEXT,
            MusicKey.PREVIOUS to MusicTransport.PREVIOUS,
            MusicKey.STOP to MusicTransport.STOP,
            MusicKey.FAST_FORWARD to MusicTransport.SKIP_FORWARD,
            MusicKey.REWIND to MusicTransport.SKIP_BACKWARD,
        )
        for ((key, transport) in cases) {
            calls.clear()
            assertEquals(listOf(true, true, true), system.press(key), "$key is consumed")
            assertEquals(listOf(transport), calls, "$key fires $transport once on the first down")
        }
    }

    @Test
    fun ignoresTransportKeysWhenNoSessionIsLive() {
        handler.register()
        sessionLive = false

        assertEquals(listOf(false, false, false), system.press(MusicKey.PLAY_PAUSE))
        assertTrue(calls.isEmpty())
    }

    @Test
    fun unregisterStopsHandlingAndIsIdempotent() {
        handler.register()
        assertEquals(listOf(true, true, true), system.press(MusicKey.PLAY_PAUSE))

        handler.unregister()
        handler.unregister()

        assertNull(system.keyHandler)
        assertEquals(listOf(false, false, false), system.press(MusicKey.PLAY_PAUSE))
        assertEquals(listOf(MusicTransport.TOGGLE), calls)
    }
}
