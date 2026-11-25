package com.edde746.plezy.cast

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import platform.Foundation.NSDate
import platform.Foundation.NSRunLoop
import platform.Foundation.dateWithTimeIntervalSinceNow
import platform.Foundation.runUntilDate
import kotlin.random.Random
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

class BonjourCastDiscoveryTest {
    @Test
    fun `a browse started off the main thread finds a receiver another device advertises`() {
        val id = "test-${Random.nextLong().toULong()}"
        val txt = mapOf("id" to id, "name" to "Test TV", "platform" to "tvOS", "kind" to "TV")
        val advert = BonjourCastDiscovery().advertise("Test TV $id", 48641, txt)
        var found: CastService? = null
        // The browse is collected on a background thread, as the sender's picker collects it.
        val scope = CoroutineScope(Dispatchers.Default)
        BonjourCastDiscovery().browse().onEach { services -> services.firstOrNull { it.txt["id"] == id }?.let { found = it } }.launchIn(scope)
        try {
            // Bonjour reports on the main run loop: it runs here until the receiver shows, for at most 15 s.
            val deadline = TimeSource.Monotonic.markNow() + 15.seconds
            while (found == null && deadline.hasNotPassedNow()) {
                NSRunLoop.mainRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.1))
            }
            val service = assertNotNull(found, "no receiver $id found")
            assertEquals(48641, service.port)
            assertEquals(txt, service.txt)
        } finally {
            scope.cancel()
            advert.close()
            NSRunLoop.mainRunLoop.runUntilDate(NSDate.dateWithTimeIntervalSinceNow(0.2))
        }
    }
}
