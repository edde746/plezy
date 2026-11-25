package com.edde746.plezy.presentation.livetv.recordings

import com.edde746.plezy.app.testData
import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.backend.RecordingConflictException
import com.edde746.plezy.livetv.FakeLiveTv
import com.edde746.plezy.livetv.MediaSubscription
import com.edde746.plezy.livetv.MediaSubscriptionCreateRequest
import com.edde746.plezy.livetv.SubscriptionSetting
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaLibrary
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.settings.ServerSettingsRepository
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RecordOptionsStoreTest {
    private class Harness(backend: BackendKind) {
        val liveTv = FakeLiveTv()
        val client = FakeMediaBackend("server-1", backend).also { it.liveTv = liveTv }
        val created = mutableListOf<MediaSubscriptionCreateRequest>()
        val updated = mutableMapOf<String, Map<String, Any?>>()
        val outcomes = mutableListOf<RecordOutcome>()

        init {
            liveTv.create = {
                created += it
                null
            }
            liveTv.update = { id, prefs ->
                updated[id] = prefs
                null
            }
            client.libraries = { emptyList() }
        }
    }

    private fun TestScope.open(h: Harness, mode: RecordOptionsMode, settings: ServerSettingsRepository = testData().serverSettings): RecordOptionsStore {
        val store = RecordOptionsStore(h.client, settings, mode, backgroundScope) { h.outcomes += it }
        runCurrent()
        return store
    }

    private fun TestScope.saved(store: RecordOptionsStore, h: Harness): RecordOutcome? {
        store.save()
        runCurrent()
        return h.outcomes.singleOrNull()
    }

    @Test
    fun createSucceedsWithoutATargetWhenTheTemplateCarriesNone() = runTest {
        val h = Harness(BackendKind.JELLYFIN)
        val store = open(h, RecordOptionsMode.Create("Pilot", listOf(mediaBrowserEntry())))

        assertEquals(RecordOutcome.SCHEDULED, saved(store, h))
        val request = h.created.single()
        assertNull(request.targetLibrarySectionId)
        assertEquals("""{"ServiceName":"Emby"}""", request.parameters)
        assertEquals(60, request.prefs["PrePaddingSeconds"])
    }

    @Test
    fun createStillRequiresATargetWhenEligibleLibrariesExistAndNoneResolves() = runTest {
        val h = Harness(BackendKind.PLEX)
        h.client.libraries = { listOf(MediaLibrary(id = "5", backend = BackendKind.PLEX, title = "TV", kind = MediaKind.SHOW, serverId = "server-1")) }
        val store = open(h, RecordOptionsMode.Create("Pilot", listOf(mediaBrowserEntry())))

        assertEquals(RecordOutcome.TARGET_MISSING, saved(store, h))
        assertTrue(h.created.isEmpty())
    }

    @Test
    fun embyNumericLibraryIdsAreNotPlexRecordingTargets() = runTest {
        val h = Harness(BackendKind.EMBY)
        h.client.libraries = { listOf(MediaLibrary(id = "12", backend = BackendKind.EMBY, title = "TV", kind = MediaKind.SHOW, serverId = "server-1")) }
        val store = open(h, RecordOptionsMode.Create("Pilot", listOf(mediaBrowserEntry())))

        assertNull(store.state.value.target)
        assertEquals(RecordOutcome.SCHEDULED, saved(store, h))
        assertNull(h.created.single().targetLibrarySectionId)
    }

    @Test
    fun aRecordingConflictIsAlreadyScheduled() = runTest {
        val h = Harness(BackendKind.JELLYFIN)
        h.liveTv.create = { throw RecordingConflictException("duplicate") }
        val store = open(h, RecordOptionsMode.Create("Pilot", listOf(mediaBrowserEntry())))

        assertEquals(RecordOutcome.ALREADY_SCHEDULED, saved(store, h))
    }

    @Test
    fun clearingANumericInputKeepsTheOtherEditsWhenSaving() = runTest {
        val h = Harness(BackendKind.JELLYFIN)
        val rule = MediaSubscription(
            key = "rule-1",
            title = "Record Episode",
            settings = listOf(
                SubscriptionSetting(id = "PrePaddingSeconds", label = "Start early (seconds)", type = "int", value = 60),
                SubscriptionSetting(id = "PostPaddingSeconds", label = "End late (seconds)", type = "int", value = 120),
            ),
        )
        val store = open(h, RecordOptionsMode.Edit(rule))

        store.setText("PrePaddingSeconds", "90")
        store.setText("PostPaddingSeconds", "180")
        store.setText("PrePaddingSeconds", "")

        assertEquals(listOf("60", "180"), store.state.value.settings.map { (it as RecordSettingRow.Field).text })
        assertEquals(RecordOutcome.UPDATED, saved(store, h))
        assertEquals(mapOf("rule-1" to mapOf<String, Any?>("PostPaddingSeconds" to 180)), h.updated)
    }

    @Test
    fun theSavedPickIsTheTargetWhileEligibleAndOnlyAnExplicitPickIsRemembered() = runTest {
        val settings = testData().serverSettings
        settings.set("server-1", ServerSettings.dvrTargetSection(MediaSubscription.TYPE_SERIES), 7)
        val h = Harness(BackendKind.PLEX)
        h.client.libraries = {
            listOf(
                MediaLibrary(id = "5", backend = BackendKind.PLEX, title = "TV", kind = MediaKind.SHOW),
                MediaLibrary(id = "7", backend = BackendKind.PLEX, title = "Recorded TV", kind = MediaKind.SHOW),
                MediaLibrary(id = "8", backend = BackendKind.PLEX, title = "Friend's TV", kind = MediaKind.SHOW, isShared = true),
                MediaLibrary(id = "9", backend = BackendKind.PLEX, title = "Movies", kind = MediaKind.MOVIE),
            )
        }
        val series = MediaSubscription(key = "", type = MediaSubscription.TYPE_SERIES, title = "Record Series", targetLibrarySectionId = 5, targetSectionLocationId = 3)
        val store = open(h, RecordOptionsMode.Create("Show", listOf(series)), settings)

        val target = store.state.value.target!!
        assertEquals("Recorded TV", target.value)
        assertEquals(listOf(5, 7), target.options.map { it.sectionId })
        assertEquals(RecordOutcome.SCHEDULED, saved(store, h))
        assertEquals(7, h.created.single().targetLibrarySectionId)
        assertNull(h.created.single().targetSectionLocationId, "another section drops the template's location")

        settings.set("server-1", ServerSettings.dvrTargetSection(MediaSubscription.TYPE_SERIES), 0)
        val default = open(Harness(BackendKind.PLEX).also { it.client.libraries = h.client.libraries }, RecordOptionsMode.Create("Show", listOf(series)), settings)
        default.save()
        runCurrent()
        assertEquals(0, settings.value("server-1", ServerSettings.dvrTargetSection(MediaSubscription.TYPE_SERIES)), "the template's default is not remembered")

        val picking = open(h, RecordOptionsMode.Create("Show", listOf(series)), settings)
        picking.selectTarget(7)
        picking.save()
        runCurrent()
        assertEquals(7, settings.value("server-1", ServerSettings.dvrTargetSection(MediaSubscription.TYPE_SERIES)))
    }

    @Test
    fun switchingEntriesDropsTheEditsAndThePick() = runTest {
        val h = Harness(BackendKind.JELLYFIN)
        val episode = mediaBrowserEntry()
        val series = MediaSubscription(
            key = "",
            type = MediaSubscription.TYPE_SERIES,
            title = "Record Series",
            settings = listOf(SubscriptionSetting(id = "RecordNewOnly", label = "Only new episodes", type = "bool", value = false)),
        )
        val store = open(h, RecordOptionsMode.Create("Pilot", listOf(series, episode)))

        assertEquals(listOf(false, true), store.state.value.entries.map { it.selected }, "the selected entry opens first")
        store.setText("PrePaddingSeconds", "90")
        store.selectEntry(0)
        store.setToggle("RecordNewOnly", true)
        store.selectEntry(1)

        assertEquals("60", (store.state.value.settings.single() as RecordSettingRow.Field).text)
        assertEquals(RecordOutcome.SCHEDULED, saved(store, h))
        assertEquals(mapOf<String, Any?>("PrePaddingSeconds" to 60), h.created.single().prefs)
    }

    /** A MediaBrowser-shaped template entry: no target library section, settings keyed by timer field names. */
    private fun mediaBrowserEntry() = MediaSubscription(
        key = "",
        type = MediaSubscription.TYPE_EPISODE,
        title = "Record Episode",
        selected = true,
        parameters = """{"ServiceName":"Emby"}""",
        settings = listOf(SubscriptionSetting(id = "PrePaddingSeconds", label = "Start early (seconds)", type = "int", value = 60)),
    )
}
