package com.edde746.plezy.presentation.settings

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.MpvPreset
import com.edde746.plezy.strings.T
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * mpv.conf: edits written debounced as one whole document, one write at a time with the latest last, a
 * change made elsewhere replacing the text, a failed write kept to retry, the TV line editor, and the presets.
 */
class MpvConfigPageTest {
    private val key = AppSettings.mpvConfigText.key
    private val tv = SettingsPlatform(os = "Android", isTv = true, formFactor = FormFactor.TV, hasFileDialogs = false)

    private class Mpv(val fixture: SettingsFixture, val store: MpvConfigStore) {
        val messages = fixture.collect(store.messages)
        val state get() = store.state.value

        /** The documents written so far, oldest first. */
        val writes get() = fixture.writes(AppSettings.mpvConfigText.key).map { Json.decodeFromString<String>(it) }

        suspend fun stored() = fixture.data.deviceSettings.value(AppSettings.mpvConfigText)
    }

    private suspend fun TestScope.mpv(
        platform: SettingsPlatform = SettingsPlatform(),
        initial: String? = null,
        presets: List<MpvPreset> = emptyList(),
    ): Mpv {
        val fixture = settingsFixture(platform)
        initial?.let { fixture.data.deviceSettings.set(AppSettings.mpvConfigText, it) }
        if (presets.isNotEmpty()) fixture.data.deviceSettings.set(AppSettings.mpvConfigPresets, presets)
        fixture.recordWrites(key)
        val mpv = Mpv(fixture, fixture.stores.mpvConfig())
        runCurrent()
        return mpv
    }

    private fun TestScope.debounce(millis: Long = MpvConfigPage.DEBOUNCE_MILLIS) {
        advanceTimeBy(millis)
        runCurrent()
    }

    @Test
    fun aTypingBurstIsWrittenOnceAfterTheDebounce() = runTest {
        val mpv = mpv()
        mpv.store.edit("vo")
        mpv.store.edit("vol")
        mpv.store.edit("volume=80")

        debounce(MpvConfigPage.DEBOUNCE_MILLIS - 1)
        assertEquals(emptyList(), mpv.writes)
        debounce(1)
        assertEquals(listOf("volume=80"), mpv.writes)
        assertEquals("volume=80", mpv.stored())
    }

    @Test
    fun editsDuringAWriteWaitForItAndOnlyTheLatestFollows() = runTest {
        val mpv = mpv()
        mpv.fixture.io.held = true
        mpv.store.edit("first=1")
        debounce()
        mpv.store.edit("second=2")
        mpv.store.edit("final=3")
        debounce()

        mpv.fixture.io.held = false
        runCurrent()
        assertEquals(listOf("first=1", "final=3"), mpv.writes)
        assertEquals("final=3", mpv.state.text)
        assertEquals("final=3", mpv.stored())
    }

    @Test
    fun aChangeMadeElsewhereReplacesTheText() = runTest {
        val mpv = mpv(initial = "hwdec=auto")
        assertEquals("hwdec=auto", mpv.state.text)

        mpv.fixture.data.deviceSettings.set(AppSettings.mpvConfigText, "external=yes")
        runCurrent()
        assertEquals(listOf("external=yes"), mpv.writes, "the page writes nothing back")
        assertEquals("external=yes", mpv.state.text)
    }

    @Test
    fun aChangeMadeElsewhereDuringALocalWriteEndsUpStored() = runTest {
        val mpv = mpv()
        mpv.fixture.io.held = true
        mpv.store.edit("local=old")
        debounce()
        backgroundScope.launch { mpv.fixture.data.deviceSettings.set(AppSettings.mpvConfigText, "external=new") }
        runCurrent()

        mpv.fixture.io.held = false
        runCurrent()
        assertEquals("external=new", mpv.state.text)
        assertEquals("external=new", mpv.stored())
        assertEquals("external=new", mpv.writes.last())
    }

    @Test
    fun aFailedWriteSaysSoAndStaysPendingUntilARetrySucceeds() = runTest {
        val mpv = mpv()
        mpv.fixture.failWrites(key)
        mpv.store.edit("gpu-api=vulkan")

        assertFalse(mpv.store.flush())
        assertEquals(listOf(SettingsEvent.Message(T.settings.saveFailed, error = true)), mpv.messages)
        assertEquals("", mpv.stored())
        assertEquals("gpu-api=vulkan", mpv.state.text)

        mpv.fixture.allowWrites(key)
        assertTrue(mpv.store.flush())
        assertEquals("gpu-api=vulkan", mpv.stored())
    }

    @Test
    fun closingThePageStoresAnEditStillPending() = runTest {
        val mpv = mpv()
        mpv.store.edit("video-sync=display-resample")
        mpv.store.release()
        runCurrent()
        assertEquals("video-sync=display-resample", mpv.stored())
    }

    @Test
    fun savingAPresetStoresTheTextOnlyOnceItIsWritten() = runTest {
        val mpv = mpv()
        assertFalse(mpv.state.canSavePreset)
        mpv.fixture.io.held = true
        mpv.store.edit("preset-source=yes")
        assertTrue(mpv.state.canSavePreset)
        mpv.store.savePreset("  Saved ")
        runCurrent()
        assertEquals(emptyList(), mpv.messages)
        assertEquals(emptyList(), mpv.state.presets)

        mpv.fixture.io.held = false
        runCurrent()
        assertEquals(listOf("preset-source=yes"), mpv.writes)
        val saved = mpv.fixture.data.deviceSettings.value(AppSettings.mpvConfigPresets).single()
        assertEquals("Saved" to "preset-source=yes", saved.name to saved.text)
        assertEquals(listOf("Saved"), mpv.state.presets)
        assertEquals(listOf(SettingsEvent.Message(T.mpvConfig.presetSaved)), mpv.messages)

        // The same name replaces it.
        mpv.store.edit("preset-source=no")
        mpv.store.savePreset("Saved")
        runCurrent()
        assertEquals(listOf("preset-source=no"), mpv.fixture.data.deviceSettings.value(AppSettings.mpvConfigPresets).map { it.text })
    }

    @Test
    fun loadingAPresetWaitsForTheWriteInFlightAndIsStoredLast() = runTest {
        val mpv = mpv(presets = listOf(MpvPreset("Cinema", "profile=gpu-hq", "2026-01-01T00:00:00Z")))
        mpv.fixture.io.held = true
        mpv.store.edit("old-edit=yes")
        debounce()
        mpv.store.loadPreset("Cinema")
        runCurrent()
        assertEquals("profile=gpu-hq", mpv.state.text)
        assertEquals(emptyList(), mpv.messages)

        mpv.fixture.io.held = false
        runCurrent()
        assertEquals(listOf("old-edit=yes", "profile=gpu-hq"), mpv.writes)
        assertEquals("profile=gpu-hq", mpv.stored())
        assertEquals(listOf(SettingsEvent.Message(T.mpvConfig.presetLoaded)), mpv.messages)
    }

    @Test
    fun deletingAPresetRemovesIt() = runTest {
        val mpv = mpv(presets = listOf(MpvPreset("a", "x=1", "t"), MpvPreset("b", "y=2", "t")))
        assertEquals(listOf("a", "b"), mpv.state.presets)
        mpv.store.deletePreset("a")
        runCurrent()
        assertEquals(listOf("b"), mpv.state.presets)
        assertEquals(listOf(SettingsEvent.Message(T.mpvConfig.presetDeleted)), mpv.messages)
    }

    @Test
    fun theLineEditorIsTheTvsAndTheLinuxNoteLinuxs() = runTest {
        assertTrue(mpv(tv).state.lineEditor)
        val desktop = mpv(SettingsPlatform(os = "Windows"))
        assertFalse(desktop.state.lineEditor)
        assertNull(desktop.state.linuxNote)
        assertEquals(T.mpvConfig.embeddedVoHint, mpv(SettingsPlatform(os = "Linux")).state.linuxNote)
    }

    @Test
    fun theTvLineEditorShowsARowPerLineAndStoresThemJoined() = runTest {
        val mpv = mpv(tv, initial = "hwdec=auto\n# comment")
        assertEquals(listOf("hwdec=auto", "# comment"), mpv.state.lines)

        mpv.store.editLine(1, "# changed")
        debounce()
        assertEquals("hwdec=auto\n# changed", mpv.stored())
    }

    @Test
    fun aPastedValueWithLineBreaksBecomesRows() = runTest {
        val mpv = mpv(tv, initial = "first\nlast")
        mpv.store.editLine(0, "first\r\ngpu-api=vulkan\nhwdec=auto")
        assertEquals(listOf("first", "gpu-api=vulkan", "hwdec=auto", "last"), mpv.state.lines)
        debounce()
        assertEquals("first\ngpu-api=vulkan\nhwdec=auto\nlast", mpv.stored())
    }

    @Test
    fun removingRowsKeepsTheRestAndTheLastOneClearsToAnEmptyDocument() = runTest {
        val mpv = mpv(tv, initial = "a\nb")
        mpv.store.removeLine(0)
        debounce()
        assertEquals(listOf("b"), mpv.state.lines)
        assertEquals("b", mpv.stored())

        mpv.store.removeLine(0)
        debounce()
        assertEquals(listOf(""), mpv.state.lines)
        assertEquals("", mpv.stored())
    }

    @Test
    fun addLineAppendsAnEmptyRowAndAPresetReplacesTheRows() = runTest {
        val mpv = mpv(tv, initial = "a", presets = listOf(MpvPreset("quality", "profile=gpu-hq\ndeband=yes", "t")))
        mpv.store.addLine()
        assertEquals(listOf("a", ""), mpv.state.lines)

        mpv.store.loadPreset("quality")
        runCurrent()
        assertEquals(listOf("profile=gpu-hq", "deband=yes"), mpv.state.lines)
    }
}
