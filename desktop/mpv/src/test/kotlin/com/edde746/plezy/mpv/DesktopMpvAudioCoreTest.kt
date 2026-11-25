package com.edde746.plezy.mpv

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.test.Test
import kotlin.test.assertTrue

class DesktopMpvAudioCoreTest {
    @Test
    fun `every request racing destroy is answered`() {
        repeat(ROUNDS) { round ->
            val core = DesktopMpvAudioCore()
            val answered = CountDownLatch(SENDERS * REQUESTS)
            val go = CountDownLatch(1)
            val senders = List(SENDERS) {
                Thread {
                    go.await()
                    repeat(REQUESTS) { core.getProperty("volume") { _, _ -> answered.countDown() } }
                }.apply { start() }
            }
            go.countDown()
            core.destroy()
            senders.forEach(Thread::join)
            assertTrue(answered.await(5, TimeUnit.SECONDS), "round $round: ${answered.count} requests were never answered")
        }
    }

    private companion object {
        const val ROUNDS = 300
        const val SENDERS = 4
        const val REQUESTS = 200
    }
}
