package com.edde746.plezy.livetv

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.model.ServerCapabilities
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class LiveTvAvailabilityTest {
    private fun backend(id: String, kind: BackendKind = BackendKind.PLEX, liveTv: FakeLiveTv) =
        FakeMediaBackend(id, kind).also { it.liveTv = liveTv }

    @Test
    fun aServerWithDvrsYieldsOneEntryPerDvrWithoutTheAvailabilityProbe() = runTest {
        val dvrs = listOf(LiveTvDvr("dvr-1", lineup = "lineup-a"), LiveTvDvr("dvr-2", lineup = "lineup-b"))
        val liveTv = FakeLiveTv().apply { this.dvrs = { dvrs } }

        val entries = liveTvServerEntries(backend("plex-machine", liveTv = liveTv))

        assertEquals(
            listOf(
                LiveTvServerEntry(ServerId("plex-machine"), "dvr-1", "lineup-a", dvrs),
                LiveTvServerEntry(ServerId("plex-machine"), "dvr-2", "lineup-b", dvrs),
            ),
            entries,
        )
        assertEquals(listOf("fetchDvrs"), liveTv.calls)
    }

    @Test
    fun aServerWithoutDvrsYieldsOneSynthesizedEntryWhenLiveTvIsAvailable() = runTest {
        val liveTv = FakeLiveTv().apply {
            dvrs = { emptyList() }
            available = { true }
        }

        val entries = liveTvServerEntries(backend("jellyfin-machine", BackendKind.JELLYFIN, liveTv))

        assertEquals(listOf(LiveTvServerEntry(ServerId("jellyfin-machine"), "jellyfin")), entries)
        assertEquals(listOf("fetchDvrs", "isAvailable"), liveTv.calls)
    }

    @Test
    fun aServerWithoutLiveTvYieldsNothing() = runTest {
        val liveTv = FakeLiveTv().apply {
            dvrs = { emptyList() }
            available = { false }
        }

        assertTrue(liveTvServerEntries(backend("emby-machine", BackendKind.EMBY, liveTv)).isEmpty())
    }

    @Test
    fun theDvrListIsGatedByTheDvrCapability() = runTest {
        val liveTv = FakeLiveTv().apply { available = { true } }
        val client = backend("plex-machine", liveTv = liveTv).also { it.capabilities = ServerCapabilities.PLEX.copy(liveTvDvr = false) }

        assertEquals(listOf(LiveTvServerEntry(ServerId("plex-machine"), "plex")), liveTvServerEntries(client))
        assertEquals(listOf("isAvailable"), liveTv.calls)
    }

    @Test
    fun aFailedDvrListThrows() = runTest {
        val liveTv = FakeLiveTv().apply { dvrs = { throw IllegalStateException("dvrs unavailable") } }

        assertFailsWith<IllegalStateException> { liveTvServerEntries(backend("plex-machine", liveTv = liveTv)) }
    }
}
