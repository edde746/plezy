package com.edde746.plezy.desktop.windows

import com.edde746.plezy.desktop.windows.DisplayRecovery.Kind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DisplayRecoveryTest {
    private class ModeRestore(val device: String, val width: Long, val height: Long, val rate: Long)
    private class HdrRestore(val device: String, val enabled: Boolean)

    /** The registry and the display calls, in memory, with the order of every call in [events]. */
    private class FakeBackend : DisplayRecovery.Backend {
        val dwords = linkedMapOf<String, Long>()
        val strings = linkedMapOf<String, String>()
        val devicePresent = mutableMapOf(MODE_DEVICE to true, HDR_DEVICE to true, REPLACEMENT_MODE_DEVICE to true, REPLACEMENT_HDR_DEVICE to true)
        val events = mutableListOf<String>()
        var expectedModeDevice = MODE_DEVICE
        var expectedMode = Triple(3840L, 2160L, 60L)
        var expectedHdrDevice = HDR_DEVICE
        var expectedOriginalHdr = false
        var expectedModeRestores = listOf<ModeRestore>()
        var expectedHdrRestores = listOf<HdrRestore>()
        var modeRestoreAttempts = 0
        var hdrRestoreAttempts = 0
        var modeRestoreSucceeds = true
        var hdrRestoreSucceeds = true
        var modeMarkerClearSucceeds = true
        var hdrMarkerClearSucceeds = true
        var deleteSucceeds = true
        var finalModeMarkerWriteSucceeds = true
        var rejectedDwordWrite = ""
        var deleteAttempts = 0

        fun seedBoth() {
            dwords[VERSION] = 1
            dwords[MODE_CHANGED] = 1
            dwords[HDR_CHANGED] = 1
            dwords[ORIGINAL_WIDTH] = 3840
            dwords[ORIGINAL_HEIGHT] = 2160
            dwords[ORIGINAL_REFRESH_RATE] = 60
            dwords[ORIGINAL_HDR] = 0
            strings[MODE_DEVICE_NAME] = MODE_DEVICE
            strings[HDR_DEVICE_NAME] = HDR_DEVICE
        }

        fun copyFrom(other: FakeBackend) {
            dwords.putAll(other.dwords)
            strings.putAll(other.strings)
        }

        override fun recordExists() = dwords.isNotEmpty() || strings.isNotEmpty()
        override fun readDword(name: String) = dwords[name]
        override fun readString(name: String) = strings[name]

        override fun writeDword(name: String, value: Long): Boolean {
            val event = "write:$name=$value"
            events += event
            if (event == rejectedDwordWrite || (name == MODE_CHANGED && value == 1L && !finalModeMarkerWriteSucceeds)) return false
            dwords[name] = value
            return true
        }

        override fun writeString(name: String, value: String): Boolean {
            events += "write:$name"
            strings[name] = value
            return true
        }

        override fun isDevicePresent(device: String) = devicePresent[device] == true

        override fun restoreMode(device: String, width: Long, height: Long, refreshRate: Long): Boolean {
            if (expectedModeRestores.isEmpty()) {
                assertEquals(expectedModeDevice, device, "mode restore must use its persisted display")
                assertEquals(expectedMode, Triple(width, height, refreshRate), "mode restore must use persisted originals")
            } else {
                assertTrue(modeRestoreAttempts < expectedModeRestores.size, "mode recovery made an unexpected extra restore")
                val expected = expectedModeRestores[modeRestoreAttempts]
                assertEquals(expected.device, device, "mode handoff restore order must be deterministic")
                assertEquals(Triple(expected.width, expected.height, expected.rate), Triple(width, height, refreshRate))
            }
            modeRestoreAttempts++
            events += "restore:mode"
            return modeRestoreSucceeds
        }

        override fun restoreHdr(device: String, enabled: Boolean): Boolean {
            if (expectedHdrRestores.isEmpty()) {
                assertEquals(expectedHdrDevice, device, "HDR restore must use its independently persisted display")
                assertEquals(expectedOriginalHdr, enabled, "HDR restore must use the persisted original state")
            } else {
                assertTrue(hdrRestoreAttempts < expectedHdrRestores.size, "HDR recovery made an unexpected extra restore")
                val expected = expectedHdrRestores[hdrRestoreAttempts]
                assertEquals(expected.device, device)
                assertEquals(expected.enabled, enabled)
            }
            hdrRestoreAttempts++
            events += "restore:hdr"
            return hdrRestoreSucceeds
        }

        override fun clearMarker(name: String): Boolean {
            events += "clear:$name"
            val succeeds = if (name == MODE_CHANGED) modeMarkerClearSucceeds else hdrMarkerClearSucceeds
            if (succeeds) dwords[name] = 0
            return succeeds
        }

        override fun deleteRecord(): Boolean {
            deleteAttempts++
            events += "delete"
            if (!deleteSucceeds) return false
            dwords.clear()
            strings.clear()
            return true
        }

        fun has(event: String) = event in events
        fun index(event: String) = events.indexOf(event).let { if (it < 0) events.size else it }
    }

    private fun applyMode(backend: FakeBackend, device: String = MODE_DEVICE, width: Long = 3840, height: Long = 2160, rate: Long = 60, osSucceeds: Boolean = true): Boolean {
        if (!DisplayRecovery.prepareMode(backend, device, width, height, rate)) return false
        backend.events += if (osSucceeds) "os:mode" else "os:mode:failed"
        DisplayRecovery.finalize(backend, Kind.MODE, osSucceeds)
        return osSucceeds
    }

    private fun applyHdr(backend: FakeBackend, device: String = HDR_DEVICE, enabled: Boolean = false, osSucceeds: Boolean = true): Boolean {
        if (!DisplayRecovery.prepareHdr(backend, device, enabled)) return false
        backend.events += if (osSucceeds) "os:hdr" else "os:hdr:failed"
        DisplayRecovery.finalize(backend, Kind.HDR, osSucceeds)
        return osSucceeds
    }

    @Test
    fun markersArePersistedBeforeMutation() {
        val mode = FakeBackend()
        assertTrue(applyMode(mode))
        val marker = mode.index("write:ModeChanged=1")
        assertTrue(marker < mode.index("os:mode"), "the mode marker must be durable before the OS mutation")
        for (e in listOf("write:ModeDeviceName", "write:OriginalWidth=3840", "write:OriginalHeight=2160", "write:OriginalRefreshRate=60", "write:ModeTakeoverEligible=0", "write:ModeRecoverySlot=0")) {
            assertTrue(mode.index(e) < marker, "$e must precede the operation marker")
        }

        val hdr = FakeBackend()
        assertTrue(applyHdr(hdr))
        val hdrMarker = hdr.index("write:HDRChanged=1")
        for (e in listOf("write:HDRDeviceName", "write:OriginalHDREnabled=0", "write:HDRTakeoverEligible=0", "write:HDRRecoverySlot=0")) {
            assertTrue(hdr.index(e) < hdrMarker, "$e must precede the HDR marker")
        }
        assertTrue(hdrMarker < hdr.index("os:hdr"))

        val failedMarker = FakeBackend().apply { finalModeMarkerWriteSucceeds = false }
        assertFalse(applyMode(failedMarker), "no OS mutation when the final marker can't be persisted")
        assertFalse(failedMarker.has("os:mode"))
    }

    @Test
    fun malformedRecordIsIgnored() {
        val backend = FakeBackend().apply { seedBoth(); dwords[VERSION] = 2; strings[LEGACY_DEVICE_NAME] = MODE_DEVICE }
        assertFalse(DisplayRecovery.recover(backend))
        assertFalse(backend.has("restore:mode") || backend.has("restore:hdr"))
        assertEquals(1, backend.deleteAttempts)
        assertFalse(backend.recordExists())
    }

    @Test
    fun validModeSurvivesMalformedHdr() {
        val backend = FakeBackend().apply { seedBoth(); dwords[ORIGINAL_HDR] = 2 }
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode"))
        assertFalse(backend.has("restore:hdr"))
        assertTrue(backend.has("clear:HDRChanged"))
    }

    @Test
    fun validHdrSurvivesMalformedMode() {
        val backend = FakeBackend().apply { seedBoth(); dwords.remove(ORIGINAL_HEIGHT) }
        assertTrue(DisplayRecovery.recover(backend))
        assertFalse(backend.has("restore:mode"))
        assertTrue(backend.has("restore:hdr"))
        assertTrue(backend.has("clear:ModeChanged"))
    }

    @Test
    fun preparationClearsMalformedSibling() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_CHANGED] = 0; dwords[ORIGINAL_HDR] = 2 }
        assertTrue(applyMode(mode))
        assertEquals(0L, mode.dwords[HDR_CHANGED])

        val hdr = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0; dwords.remove(ORIGINAL_HEIGHT) }
        assertTrue(applyHdr(hdr))
        assertEquals(0L, hdr.dwords[MODE_CHANGED])
    }

    @Test
    fun modeAndHdrRestoreIndependently() {
        val backend = FakeBackend().apply { seedBoth(); modeRestoreSucceeds = false }
        assertFalse(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode") && backend.has("restore:hdr"))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])
        assertEquals(0L, backend.dwords[HDR_CHANGED])
        assertEquals(0L, backend.dwords[HDR_TAKEOVER])

        backend.events.clear()
        backend.modeRestoreSucceeds = true
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode"))
        assertFalse(backend.has("restore:hdr"))
    }

    @Test
    fun failedRestoreRemainsForTopologyRetry() {
        val backend = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0; devicePresent[MODE_DEVICE] = false }
        assertFalse(DisplayRecovery.recover(backend))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])
        assertFalse(backend.has("restore:mode"))

        backend.events.clear()
        backend.devicePresent[MODE_DEVICE] = true
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode"))
        assertFalse(backend.recordExists())
        assertNull(backend.dwords[MODE_TAKEOVER])
    }

    @Test
    fun markerClearFailureRemainsRetryable() {
        val backend = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0; modeMarkerClearSucceeds = false }
        assertFalse(DisplayRecovery.recover(backend))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])

        backend.events.clear()
        backend.modeMarkerClearSucceeds = true
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode"))
        assertFalse(backend.recordExists())
    }

    @Test
    fun lifecycleCleanupPreservesPersistedSibling() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.complete(mode, Kind.MODE))
        assertEquals(listOf(0L, 0L, 1L, 1L), listOf(mode.dwords[MODE_CHANGED], mode.dwords[MODE_TAKEOVER], mode.dwords[HDR_CHANGED], mode.dwords[HDR_TAKEOVER]))
        assertEquals(0L, mode.dwords[ORIGINAL_HDR])
        assertEquals(HDR_DEVICE, mode.strings[HDR_DEVICE_NAME])
        assertEquals(0, mode.deleteAttempts)

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.complete(hdr, Kind.HDR))
        assertEquals(listOf(0L, 0L, 1L, 1L), listOf(hdr.dwords[HDR_CHANGED], hdr.dwords[HDR_TAKEOVER], hdr.dwords[MODE_CHANGED], hdr.dwords[MODE_TAKEOVER]))
        assertEquals(3840L, hdr.dwords[ORIGINAL_WIDTH])
        assertEquals(MODE_DEVICE, hdr.strings[MODE_DEVICE_NAME])
        assertEquals(0, hdr.deleteAttempts)
    }

    @Test
    fun releasedLiveOperationRecoversAfterReconnect() {
        val backend = FakeBackend().apply { seedBoth(); devicePresent[MODE_DEVICE] = false }
        assertFalse(DisplayRecovery.recover(backend, modeLive = true, hdrLive = true))
        assertTrue(backend.events.isEmpty(), "live operations must not reach restore or persistence")
        assertNull(backend.dwords[MODE_TAKEOVER])
        assertNull(backend.dwords[HDR_TAKEOVER])

        assertFalse(DisplayRecovery.recover(backend, modeLive = false, hdrLive = true))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])
        assertEquals(1L, backend.dwords[HDR_CHANGED])

        backend.events.clear()
        backend.devicePresent[MODE_DEVICE] = true
        assertTrue(DisplayRecovery.recover(backend, modeLive = false, hdrLive = true))
        assertTrue(backend.has("restore:mode"))
        assertFalse(backend.has("restore:hdr"))
        assertEquals(0L, backend.dwords[MODE_CHANGED])
        assertEquals(0L, backend.dwords[MODE_TAKEOVER])
        assertEquals(1L, backend.dwords[HDR_CHANGED])
        assertEquals(0, backend.deleteAttempts)
    }

    @Test
    fun unfailedMarkersRejectSameKindTakeover() {
        val mode = FakeBackend().apply { seedBoth() }
        val modeDwords = mode.dwords.toMap()
        val modeStrings = mode.strings.toMap()
        assertFalse(applyMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertEquals(modeDwords, mode.dwords.toMap())
        assertEquals(modeStrings, mode.strings.toMap())
        assertTrue(mode.events.isEmpty())

        val hdr = FakeBackend().apply { seedBoth(); dwords[HDR_TAKEOVER] = 2 }
        val hdrDwords = hdr.dwords.toMap()
        assertFalse(applyHdr(hdr, REPLACEMENT_HDR_DEVICE, true), "only a disposition of exactly one may replace a marker")
        assertEquals(hdrDwords, hdr.dwords.toMap())
        assertTrue(hdr.events.isEmpty())
    }

    @Test
    fun absentModeTakeoverSurvivesRelaunchAndPreservesHdrSibling() {
        val failed = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 0; dwords[HDR_TAKEOVER] = 1; devicePresent[MODE_DEVICE] = false }
        assertFalse(DisplayRecovery.recover(failed, modeLive = false, hdrLive = true))
        assertEquals(1L, failed.dwords[MODE_CHANGED])
        assertEquals(1L, failed.dwords[MODE_TAKEOVER])
        assertEquals(1L, failed.dwords[HDR_CHANGED])
        assertEquals(1L, failed.dwords[HDR_TAKEOVER])

        // A new backend is the next process reading only persisted state.
        val relaunched = FakeBackend().apply { copyFrom(failed) }
        assertTrue(applyMode(relaunched, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertEquals(1L, relaunched.dwords[MODE_CHANGED])
        assertEquals(0L, relaunched.dwords[MODE_TAKEOVER])
        assertEquals(1L, relaunched.dwords[MODE_SLOT])
        assertEquals(listOf(2560L, 1440L, 120L), listOf(relaunched.dwords[ORIGINAL_WIDTH_ALT], relaunched.dwords[ORIGINAL_HEIGHT_ALT], relaunched.dwords[ORIGINAL_REFRESH_RATE_ALT]))
        assertEquals(REPLACEMENT_MODE_DEVICE, relaunched.strings[MODE_DEVICE_NAME_ALT])
        assertEquals(listOf(3840L, 2160L, 60L), listOf(relaunched.dwords[ORIGINAL_WIDTH], relaunched.dwords[ORIGINAL_HEIGHT], relaunched.dwords[ORIGINAL_REFRESH_RATE]))
        assertEquals(MODE_DEVICE, relaunched.strings[MODE_DEVICE_NAME])
        assertEquals(1L, relaunched.dwords[HDR_CHANGED])
        assertEquals(1L, relaunched.dwords[HDR_TAKEOVER])
        assertTrue(relaunched.index("write:ModeTakeoverEligible=0") < relaunched.index("write:ModeRecoverySlot=1"))
        assertTrue(relaunched.index("write:ModeRecoverySlot=1") < relaunched.index("os:mode"))
        assertFalse(relaunched.has("clear:ModeChanged") || relaunched.has("write:ModeChanged=1"))

        val recovery = FakeBackend().apply { copyFrom(relaunched); expectedModeDevice = REPLACEMENT_MODE_DEVICE; expectedMode = Triple(2560L, 1440L, 120L) }
        assertTrue(DisplayRecovery.recover(recovery, modeLive = false, hdrLive = true))
        assertTrue(recovery.has("restore:mode"))
    }

    @Test
    fun badModeHdrRestoreAllowsSameKindTakeover() {
        val backend = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 0; hdrRestoreSucceeds = false }
        assertFalse(DisplayRecovery.recover(backend, modeLive = true, hdrLive = false))
        assertTrue(backend.has("restore:hdr"))
        assertEquals(1L, backend.dwords[HDR_CHANGED])
        assertEquals(1L, backend.dwords[HDR_TAKEOVER])

        backend.events.clear()
        assertTrue(applyHdr(backend, REPLACEMENT_HDR_DEVICE, true))
        assertEquals(1L, backend.dwords[HDR_CHANGED])
        assertEquals(0L, backend.dwords[HDR_TAKEOVER])
        assertEquals(1L, backend.dwords[HDR_SLOT])
        assertEquals(1L, backend.dwords[ORIGINAL_HDR_ALT])
        assertEquals(REPLACEMENT_HDR_DEVICE, backend.strings[HDR_DEVICE_NAME_ALT])
        assertEquals(0L, backend.dwords[ORIGINAL_HDR])
        assertEquals(HDR_DEVICE, backend.strings[HDR_DEVICE_NAME])
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])
        assertTrue(backend.index("write:HDRTakeoverEligible=0") < backend.index("write:HDRRecoverySlot=1"))
        assertTrue(backend.index("write:HDRRecoverySlot=1") < backend.index("os:hdr"))
        assertFalse(backend.has("clear:HDRChanged") || backend.has("write:HDRChanged=1"))

        val recovery = FakeBackend().apply { copyFrom(backend); expectedHdrDevice = REPLACEMENT_HDR_DEVICE; expectedOriginalHdr = true }
        assertTrue(DisplayRecovery.recover(recovery, modeLive = true, hdrLive = false))
        assertTrue(recovery.has("restore:hdr"))
    }

    @Test
    fun failedOsApplyRollsBackTakeover() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertFalse(applyMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120, osSucceeds = false))
        assertEquals(listOf(1L, 0L, 1L, 0L), listOf(mode.dwords[MODE_CHANGED], mode.dwords[MODE_SLOT], mode.dwords[MODE_TAKEOVER], mode.dwords[MODE_HANDOFF]))
        assertEquals(MODE_DEVICE, mode.strings[MODE_DEVICE_NAME])
        assertEquals(1L, mode.dwords[HDR_CHANGED])
        assertTrue(mode.index("write:ModeHandoffPending=1") < mode.index("write:ModeRecoverySlot=1"))
        assertTrue(mode.index("write:ModeRecoverySlot=1") < mode.index("os:mode:failed"))
        assertTrue(mode.index("os:mode:failed") < mode.index("write:ModeRecoverySlot=0"))
        assertFalse(mode.has("clear:ModeChanged"))
        assertTrue(DisplayRecovery.recover(FakeBackend().apply { copyFrom(mode) }, modeLive = false, hdrLive = true))

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertFalse(applyHdr(hdr, REPLACEMENT_HDR_DEVICE, true, osSucceeds = false))
        assertEquals(listOf(1L, 0L, 1L, 0L, 0L), listOf(hdr.dwords[HDR_CHANGED], hdr.dwords[HDR_SLOT], hdr.dwords[HDR_TAKEOVER], hdr.dwords[HDR_HANDOFF], hdr.dwords[ORIGINAL_HDR]))
        assertEquals(HDR_DEVICE, hdr.strings[HDR_DEVICE_NAME])
        assertTrue(hdr.index("write:HDRHandoffPending=1") < hdr.index("write:HDRRecoverySlot=1"))
        assertTrue(hdr.index("write:HDRRecoverySlot=1") < hdr.index("os:hdr:failed"))
        assertTrue(hdr.index("os:hdr:failed") < hdr.index("write:HDRRecoverySlot=0"))
        assertFalse(hdr.has("clear:HDRChanged"))
        assertTrue(DisplayRecovery.recover(FakeBackend().apply { copyFrom(hdr) }, modeLive = true, hdrLive = false))
    }

    @Test
    fun crashDuringTakeoverHandoffRecoversBothOriginals() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.prepareMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertEquals(listOf(1L, 1L, 0L, 1L), listOf(mode.dwords[MODE_CHANGED], mode.dwords[MODE_HANDOFF], mode.dwords[MODE_PREVIOUS_SLOT], mode.dwords[MODE_SLOT]))
        mode.expectedModeRestores = listOf(ModeRestore(REPLACEMENT_MODE_DEVICE, 2560, 1440, 120), ModeRestore(MODE_DEVICE, 3840, 2160, 60))
        assertTrue(DisplayRecovery.recover(mode, modeLive = false, hdrLive = true))
        assertEquals(2, mode.modeRestoreAttempts)
        assertEquals(listOf(0L, 0L, 1L), listOf(mode.dwords[MODE_CHANGED], mode.dwords[MODE_HANDOFF], mode.dwords[HDR_CHANGED]))

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.prepareHdr(hdr, REPLACEMENT_HDR_DEVICE, true))
        assertEquals(listOf(1L, 1L, 0L, 1L), listOf(hdr.dwords[HDR_CHANGED], hdr.dwords[HDR_HANDOFF], hdr.dwords[HDR_PREVIOUS_SLOT], hdr.dwords[HDR_SLOT]))
        hdr.expectedHdrRestores = listOf(HdrRestore(REPLACEMENT_HDR_DEVICE, true), HdrRestore(HDR_DEVICE, false))
        assertTrue(DisplayRecovery.recover(hdr, modeLive = true, hdrLive = false))
        assertEquals(2, hdr.hdrRestoreAttempts)
        assertEquals(listOf(0L, 0L, 1L), listOf(hdr.dwords[HDR_CHANGED], hdr.dwords[HDR_HANDOFF], hdr.dwords[MODE_CHANGED]))
    }

    @Test
    fun failedHandoffRecoveryRollsBackForTakeover() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.prepareMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        mode.expectedModeRestores = listOf(ModeRestore(REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        mode.devicePresent[MODE_DEVICE] = false
        assertFalse(DisplayRecovery.recover(mode, modeLive = false, hdrLive = true))
        assertEquals(1, mode.modeRestoreAttempts)
        assertEquals(listOf(1L, 0L, 1L, 0L), listOf(mode.dwords[MODE_CHANGED], mode.dwords[MODE_SLOT], mode.dwords[MODE_TAKEOVER], mode.dwords[MODE_HANDOFF]))
        mode.events.clear()
        assertFalse(DisplayRecovery.recover(mode, modeLive = false, hdrLive = true))
        assertFalse(mode.has("restore:mode"), "retries must not keep restoring the surviving replacement")
        assertTrue(applyMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(DisplayRecovery.prepareHdr(hdr, REPLACEMENT_HDR_DEVICE, true))
        hdr.expectedHdrRestores = listOf(HdrRestore(REPLACEMENT_HDR_DEVICE, true))
        hdr.devicePresent[HDR_DEVICE] = false
        assertFalse(DisplayRecovery.recover(hdr, modeLive = true, hdrLive = false))
        assertEquals(1, hdr.hdrRestoreAttempts)
        assertEquals(listOf(1L, 0L, 1L, 0L), listOf(hdr.dwords[HDR_CHANGED], hdr.dwords[HDR_SLOT], hdr.dwords[HDR_TAKEOVER], hdr.dwords[HDR_HANDOFF]))
        hdr.events.clear()
        assertFalse(DisplayRecovery.recover(hdr, modeLive = true, hdrLive = false))
        assertFalse(hdr.has("restore:hdr"))
        assertTrue(applyHdr(hdr, REPLACEMENT_HDR_DEVICE, true))
    }

    @Test
    fun hdrReconnectRecoversBeforeTakeover() {
        val backend = FakeBackend().apply { seedBoth(); dwords[MODE_CHANGED] = 0; devicePresent[HDR_DEVICE] = false }
        assertFalse(DisplayRecovery.recover(backend))
        assertEquals(1L, backend.dwords[HDR_CHANGED])
        assertEquals(1L, backend.dwords[HDR_TAKEOVER])
        assertFalse(backend.has("restore:hdr"))

        backend.events.clear()
        backend.devicePresent[HDR_DEVICE] = true
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:hdr"))
        assertFalse(backend.recordExists())
    }

    @Test
    fun eligibleSameOriginalReuseResetsDisposition() {
        val mode = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(applyMode(mode))
        assertEquals(0L, mode.dwords[MODE_TAKEOVER])
        assertEquals(1L, mode.dwords[HDR_TAKEOVER])
        mode.events.clear()
        assertFalse(applyMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertTrue(mode.events.isEmpty())

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(applyHdr(hdr))
        assertEquals(0L, hdr.dwords[HDR_TAKEOVER])
        assertEquals(1L, hdr.dwords[MODE_TAKEOVER])
        hdr.events.clear()
        assertFalse(applyHdr(hdr, REPLACEMENT_HDR_DEVICE, true))
        assertTrue(hdr.events.isEmpty())
    }

    @Test
    fun repeatedModeTakeoverStagesOnlyTheInactiveSlot() {
        val backend = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1 }
        assertTrue(applyMode(backend, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))

        backend.events.clear()
        backend.devicePresent[REPLACEMENT_MODE_DEVICE] = false
        assertFalse(DisplayRecovery.recover(backend, modeLive = false, hdrLive = true))
        assertEquals(1L, backend.dwords[MODE_SLOT])
        assertEquals(1L, backend.dwords[MODE_TAKEOVER])

        backend.events.clear()
        backend.devicePresent[REPLACEMENT_MODE_DEVICE] = true
        backend.rejectedDwordWrite = "write:OriginalRefreshRate=75"
        assertFalse(applyMode(backend, MODE_DEVICE, 1920, 1080, 75))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertEquals(1L, backend.dwords[MODE_SLOT])
        assertEquals(listOf(2560L, 1440L, 120L), listOf(backend.dwords[ORIGINAL_WIDTH_ALT], backend.dwords[ORIGINAL_HEIGHT_ALT], backend.dwords[ORIGINAL_REFRESH_RATE_ALT]))
        assertEquals(REPLACEMENT_MODE_DEVICE, backend.strings[MODE_DEVICE_NAME_ALT])
        assertFalse(backend.has("os:mode"))

        val relaunched = FakeBackend().apply { copyFrom(backend); expectedModeDevice = REPLACEMENT_MODE_DEVICE; expectedMode = Triple(2560L, 1440L, 120L) }
        assertTrue(DisplayRecovery.recover(relaunched, modeLive = false, hdrLive = true))
    }

    @Test
    fun liveMarkersCannotBecomeEligibleOrBeTakenOver() {
        val mode = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0 }
        assertFalse(DisplayRecovery.recover(mode, modeLive = true, hdrLive = false))
        assertTrue(mode.events.isEmpty())
        assertNull(mode.dwords[MODE_TAKEOVER])
        assertFalse(applyMode(mode, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))

        val hdr = FakeBackend().apply { seedBoth(); dwords[MODE_CHANGED] = 0 }
        assertFalse(DisplayRecovery.recover(hdr, modeLive = false, hdrLive = true))
        assertTrue(hdr.events.isEmpty())
        assertNull(hdr.dwords[HDR_TAKEOVER])
        assertFalse(applyHdr(hdr, REPLACEMENT_HDR_DEVICE, true))
    }

    @Test
    fun takeoverPersistenceFailuresRemainConservative() {
        val failedGrant = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0; devicePresent[MODE_DEVICE] = false; rejectedDwordWrite = "write:ModeTakeoverEligible=1" }
        assertFalse(DisplayRecovery.recover(failedGrant))
        assertEquals(1L, failedGrant.dwords[MODE_CHANGED])
        assertNull(failedGrant.dwords[MODE_TAKEOVER])
        failedGrant.rejectedDwordWrite = ""
        failedGrant.events.clear()
        assertFalse(applyMode(failedGrant, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertTrue(failedGrant.events.isEmpty())

        val failedReuseReset = FakeBackend().apply { seedBoth(); dwords[HDR_TAKEOVER] = 1; rejectedDwordWrite = "write:HDRTakeoverEligible=0" }
        assertFalse(applyHdr(failedReuseReset))
        assertEquals(1L, failedReuseReset.dwords[HDR_CHANGED])
        assertEquals(1L, failedReuseReset.dwords[HDR_TAKEOVER])
        assertFalse(failedReuseReset.has("os:hdr"))

        val failedModeStage = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1; rejectedDwordWrite = "write:OriginalRefreshRateAlternate=120" }
        assertFalse(applyMode(failedModeStage, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertEquals(1L, failedModeStage.dwords[MODE_CHANGED])
        assertEquals(1L, failedModeStage.dwords[MODE_TAKEOVER])
        assertNull(failedModeStage.dwords[MODE_SLOT])
        assertEquals(listOf(3840L, 2160L, 60L), listOf(failedModeStage.dwords[ORIGINAL_WIDTH], failedModeStage.dwords[ORIGINAL_HEIGHT], failedModeStage.dwords[ORIGINAL_REFRESH_RATE]))
        assertEquals(1L, failedModeStage.dwords[HDR_CHANGED])
        assertFalse(failedModeStage.has("os:mode"))

        val failedModeCommit = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1; rejectedDwordWrite = "write:ModeRecoverySlot=1" }
        assertFalse(applyMode(failedModeCommit, REPLACEMENT_MODE_DEVICE, 2560, 1440, 120))
        assertEquals(listOf(1L, 1L, 0L, 0L), listOf(failedModeCommit.dwords[MODE_CHANGED], failedModeCommit.dwords[MODE_TAKEOVER], failedModeCommit.dwords[MODE_SLOT], failedModeCommit.dwords[MODE_HANDOFF]))
        assertEquals(2560L, failedModeCommit.dwords[ORIGINAL_WIDTH_ALT])
        assertEquals(REPLACEMENT_MODE_DEVICE, failedModeCommit.strings[MODE_DEVICE_NAME_ALT])
        assertFalse(failedModeCommit.has("os:mode"))
        val modeRelaunch = FakeBackend().apply { copyFrom(failedModeCommit) }
        assertTrue(DisplayRecovery.recover(modeRelaunch, modeLive = false, hdrLive = true))
        assertTrue(modeRelaunch.has("restore:mode"))

        val failedHdrStage = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1; rejectedDwordWrite = "write:OriginalHDREnabledAlternate=1" }
        assertFalse(applyHdr(failedHdrStage, REPLACEMENT_HDR_DEVICE, true))
        assertEquals(1L, failedHdrStage.dwords[HDR_CHANGED])
        assertEquals(1L, failedHdrStage.dwords[HDR_TAKEOVER])
        assertNull(failedHdrStage.dwords[HDR_SLOT])
        assertEquals(0L, failedHdrStage.dwords[ORIGINAL_HDR])
        assertFalse(failedHdrStage.has("os:hdr"))

        val failedHdrCommit = FakeBackend().apply { seedBoth(); dwords[MODE_TAKEOVER] = 1; dwords[HDR_TAKEOVER] = 1; rejectedDwordWrite = "write:HDRRecoverySlot=1" }
        assertFalse(applyHdr(failedHdrCommit, REPLACEMENT_HDR_DEVICE, true))
        assertEquals(listOf(1L, 1L, 0L, 0L), listOf(failedHdrCommit.dwords[HDR_CHANGED], failedHdrCommit.dwords[HDR_TAKEOVER], failedHdrCommit.dwords[HDR_SLOT], failedHdrCommit.dwords[HDR_HANDOFF]))
        assertEquals(1L, failedHdrCommit.dwords[ORIGINAL_HDR_ALT])
        assertFalse(failedHdrCommit.has("os:hdr"))
        val hdrRelaunch = FakeBackend().apply { copyFrom(failedHdrCommit) }
        assertTrue(DisplayRecovery.recover(hdrRelaunch, modeLive = true, hdrLive = false))
        assertTrue(hdrRelaunch.has("restore:hdr"))
    }

    @Test
    fun versionlessModeRecoveryAndCleanup() {
        val backend = FakeBackend().apply {
            dwords[MODE_CHANGED] = 1; dwords[HDR_CHANGED] = 0
            dwords[ORIGINAL_WIDTH] = 3840; dwords[ORIGINAL_HEIGHT] = 2160; dwords[ORIGINAL_REFRESH_RATE] = 60
            strings[LEGACY_DEVICE_NAME] = MODE_DEVICE
        }
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode"))
        assertEquals(1, backend.deleteAttempts)
        assertFalse(backend.recordExists())
    }

    @Test
    fun versionlessHdrRecoveryAndCleanup() {
        val backend = FakeBackend().apply {
            dwords[MODE_CHANGED] = 0; dwords[HDR_CHANGED] = 1; dwords[ORIGINAL_HDR] = 0
            strings[LEGACY_DEVICE_NAME] = HDR_DEVICE
        }
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:hdr"))
        assertEquals(1, backend.deleteAttempts)
        assertFalse(backend.recordExists())
    }

    @Test
    fun versionlessModeAndHdrUseSharedDevice() {
        val backend = FakeBackend().apply {
            dwords[MODE_CHANGED] = 1; dwords[HDR_CHANGED] = 1
            dwords[ORIGINAL_WIDTH] = 3840; dwords[ORIGINAL_HEIGHT] = 2160; dwords[ORIGINAL_REFRESH_RATE] = 60; dwords[ORIGINAL_HDR] = 0
            strings[LEGACY_DEVICE_NAME] = MODE_DEVICE
            expectedHdrDevice = MODE_DEVICE
        }
        assertTrue(DisplayRecovery.recover(backend))
        assertTrue(backend.has("restore:mode") && backend.has("restore:hdr"))
        assertEquals(1, backend.deleteAttempts)
        assertFalse(backend.recordExists())
    }

    @Test
    fun cleanupFailureDoesNotBlockNewOverride() {
        val backend = FakeBackend().apply { seedBoth(); dwords[HDR_CHANGED] = 0; deleteSucceeds = false }
        assertTrue(DisplayRecovery.recover(backend))
        assertEquals(0L, backend.dwords[MODE_CHANGED])
        assertEquals(0L, backend.dwords[MODE_TAKEOVER])
        assertEquals(1, backend.deleteAttempts)

        backend.events.clear()
        assertTrue(applyMode(backend))
        assertEquals(1L, backend.dwords[MODE_CHANGED])
        assertTrue(backend.index("write:ModeChanged=1") < backend.index("os:mode"))
    }

    private companion object {
        const val VERSION = "Version"
        const val LEGACY_DEVICE_NAME = "DeviceName"
        const val MODE_DEVICE_NAME = "ModeDeviceName"
        const val HDR_DEVICE_NAME = "HDRDeviceName"
        const val MODE_DEVICE_NAME_ALT = "ModeDeviceNameAlternate"
        const val HDR_DEVICE_NAME_ALT = "HDRDeviceNameAlternate"
        const val ORIGINAL_WIDTH = "OriginalWidth"
        const val ORIGINAL_HEIGHT = "OriginalHeight"
        const val ORIGINAL_REFRESH_RATE = "OriginalRefreshRate"
        const val ORIGINAL_HDR = "OriginalHDREnabled"
        const val ORIGINAL_WIDTH_ALT = "OriginalWidthAlternate"
        const val ORIGINAL_HEIGHT_ALT = "OriginalHeightAlternate"
        const val ORIGINAL_REFRESH_RATE_ALT = "OriginalRefreshRateAlternate"
        const val ORIGINAL_HDR_ALT = "OriginalHDREnabledAlternate"
        const val MODE_CHANGED = "ModeChanged"
        const val HDR_CHANGED = "HDRChanged"
        const val MODE_TAKEOVER = "ModeTakeoverEligible"
        const val HDR_TAKEOVER = "HDRTakeoverEligible"
        const val MODE_SLOT = "ModeRecoverySlot"
        const val HDR_SLOT = "HDRRecoverySlot"
        const val MODE_HANDOFF = "ModeHandoffPending"
        const val HDR_HANDOFF = "HDRHandoffPending"
        const val MODE_PREVIOUS_SLOT = "ModePreviousRecoverySlot"
        const val HDR_PREVIOUS_SLOT = "HDRPreviousRecoverySlot"
        const val MODE_DEVICE = "\\\\.\\DISPLAY1"
        const val HDR_DEVICE = "\\\\.\\DISPLAY2"
        const val REPLACEMENT_MODE_DEVICE = "\\\\.\\DISPLAY3"
        const val REPLACEMENT_HDR_DEVICE = "\\\\.\\DISPLAY4"
    }
}
