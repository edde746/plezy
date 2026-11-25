package com.edde746.plezy.presentation.livetv

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.servers.LiveTvServerEntry
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class LiveTvServersTest {
    private val servers = FakeLiveTvServers(
        listOf(
            LiveTvServerEntry(ServerId("a"), "dvr-1"),
            LiveTvServerEntry(ServerId("a"), "dvr-2"),
            LiveTvServerEntry(ServerId("gone"), "dvr-3"),
            LiveTvServerEntry(ServerId("b"), "dvr-4"),
        ),
        listOf(FakeMediaBackend("a"), FakeMediaBackend("b")),
    )

    @Test
    fun serversAreVisitedOnceByDefaultAndEntriesWithoutAClientAreSkipped() = runTest {
        val visited = mutableListOf<String>()
        servers.forEachLiveTvServer { client, entry -> visited += "${client.serverId.value}/${entry.dvrKey}" }

        assertEquals(listOf("a/dvr-1", "b/dvr-4"), visited)
    }

    @Test
    fun perDvrLoadsVisitEveryEntry() = runTest {
        val visited = mutableListOf<String>()
        servers.forEachLiveTvServer(dedupeByServerId = false) { _, entry -> visited += entry.dvrKey }

        assertEquals(listOf("dvr-1", "dvr-2", "dvr-4"), visited)
    }

    @Test
    fun aFailureGoesToOnErrorAndTheNextServerStillRuns() = runTest {
        val visited = mutableListOf<String>()
        val errors = mutableListOf<String>()
        servers.forEachLiveTvServer(
            dedupeByServerId = false,
            onError = { client, entry, e -> errors += "${client.serverId.value}/${entry.dvrKey}: ${e.message}" },
        ) { _, entry ->
            if (entry.dvrKey == "dvr-1") error("boom")
            visited += entry.dvrKey
        }

        assertEquals(listOf("a/dvr-1: boom"), errors)
        assertEquals(listOf("dvr-2", "dvr-4"), visited)
    }

    @Test
    fun withoutOnErrorAFailureStopsTheIterationAndPropagates() = runTest {
        val visited = mutableListOf<String>()
        val failure = assertFailsWith<IllegalStateException> {
            servers.forEachLiveTvServer(dedupeByServerId = false) { _, entry ->
                visited += entry.dvrKey
                if (entry.dvrKey == "dvr-2") error("boom")
            }
        }

        assertEquals("boom", failure.message)
        assertEquals(listOf("dvr-1", "dvr-2"), visited)
    }

    @Test
    fun aLoadThatIsNoLongerCurrentStopsBeforeTheNextServer() = runTest {
        var current = true
        val visited = mutableListOf<String>()
        servers.forEachLiveTvServer(dedupeByServerId = false, isCurrent = { current }) { _, entry ->
            visited += entry.dvrKey
            current = false
        }

        assertEquals(listOf("dvr-1"), visited)
    }
}
