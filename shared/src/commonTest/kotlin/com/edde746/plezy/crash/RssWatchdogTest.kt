package com.edde746.plezy.crash

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

class RssWatchdogTest {
    private val mib = 1L shl 20
    private val time = TestTimeSource()
    private var rss: Long? = 0
    private var cache = 64 * mib
    private var evictions = 0
    private val watchdog = RssWatchdog(RssPolicy.DESKTOP, { rss }, { cache }, { evictions++ }, time)

    @Test
    fun `desktop evicts above one and a half gibibytes every thirty seconds`() {
        assertEquals(RssPolicy(1536 * mib, 30.seconds, 1024 * mib), RssPolicy.DESKTOP)
        rss = 1536 * mib
        assertFalse(watchdog.check())
        rss = 1536 * mib + 1
        assertTrue(watchdog.check())
        assertEquals(1, evictions)
    }

    @Test
    fun `android takes 45 percent of the ram within 512 MiB and 1536 MiB`() {
        assertEquals(1350 * mib, RssPolicy.android(3000 * mib, lowEnd = false).threshold)
        assertEquals(512 * mib, RssPolicy.android(1024 * mib, lowEnd = true).threshold)
        assertEquals(1536 * mib, RssPolicy.android(8192 * mib, lowEnd = false).threshold)
        assertEquals(1024 * mib, RssPolicy.android(null, lowEnd = false).threshold)
    }

    @Test
    fun `android checks every 15 s on low end hardware and every 30 s otherwise`() {
        assertEquals(15.seconds, RssPolicy.android(2048 * mib, lowEnd = true).period)
        assertEquals(30.seconds, RssPolicy.android(8192 * mib, lowEnd = false).period)
        assertTrue(RssPolicy.lowEndAndroid(is64Bit = false, lowRamDevice = false, totalRamBytes = 8192 * mib))
        assertTrue(RssPolicy.lowEndAndroid(is64Bit = true, lowRamDevice = true, totalRamBytes = 8192 * mib))
        assertTrue(RssPolicy.lowEndAndroid(is64Bit = true, lowRamDevice = false, totalRamBytes = 2252 * mib))
        assertFalse(RssPolicy.lowEndAndroid(is64Bit = true, lowRamDevice = false, totalRamBytes = 2253 * mib))
        assertFalse(RssPolicy.lowEndAndroid(is64Bit = true, lowRamDevice = false, totalRamBytes = null))
    }

    @Test
    fun `android in the background evicts above 35 percent of the ram or 768 MiB when unknown`() {
        assertEquals(1400 * mib, RssPolicy.android(4000 * mib, lowEnd = false).backgroundThreshold)
        assertEquals(768 * mib, RssPolicy.android(null, lowEnd = false).backgroundThreshold)
    }

    @Test
    fun `a cache under 8 MiB is left alone`() {
        rss = 2048 * mib
        cache = 8 * mib - 1
        assertFalse(watchdog.check())
        cache = 8 * mib
        assertTrue(watchdog.check())
        assertEquals(1, evictions)
    }

    @Test
    fun `within 60 s of an eviction it evicts again only while the memory still climbs`() {
        rss = 2000 * mib
        assertTrue(watchdog.check())
        time += 30.seconds
        assertFalse(watchdog.check())
        rss = 2001 * mib
        assertTrue(watchdog.check())
        time += 59.seconds
        assertFalse(watchdog.check())
        time += 1.seconds
        assertTrue(watchdog.check())
        assertEquals(3, evictions)
    }

    @Test
    fun `unreadable memory evicts nothing`() {
        rss = null
        assertFalse(watchdog.check())
        assertFalse(watchdog.onBackground())
        assertEquals(0, evictions)
    }

    @Test
    fun `the background evicts above its own threshold whatever the cache and the cooldown`() {
        rss = 1024 * mib
        assertFalse(watchdog.onBackground())
        rss = 1024 * mib + 1
        cache = 0
        assertTrue(watchdog.onBackground())
        assertTrue(watchdog.onBackground())
        assertEquals(2, evictions)
    }

    @Test
    fun `memory pressure always evicts`() {
        cache = 0
        watchdog.onMemoryPressure()
        watchdog.onMemoryPressure()
        assertEquals(2, evictions)
    }
}
