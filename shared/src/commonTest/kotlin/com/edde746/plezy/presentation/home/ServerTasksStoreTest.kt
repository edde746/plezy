package com.edde746.plezy.presentation.home

import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.plex.PlexActivity
import com.edde746.plezy.servers.NamedServer
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Plex servers answering after [LATENCY] ms, counting the requests and how many ran at once. */
private class FakeTaskServers : ServerTaskServers {
    val list = MutableStateFlow(listOf(NamedServer(ServerId("alpha"), "Alpha")))
    override val servers = list
    val tasks = mutableMapOf<ServerId, MutableList<PlexActivity>>()
    var fetches = 0
    var inFlight = 0
    var maxInFlight = 0
    var fail = false
    val cancelled = mutableListOf<String>()

    override suspend fun activities(serverId: ServerId): List<PlexActivity> {
        fetches++
        inFlight++
        maxInFlight = maxOf(maxInFlight, inFlight)
        try {
            delay(LATENCY)
            check(!fail) { "server error" }
            return tasks[serverId].orEmpty().toList()
        } finally {
            inFlight--
        }
    }

    override suspend fun cancel(serverId: ServerId, uuid: String) {
        delay(100)
        cancelled += uuid
        tasks[serverId]?.removeAll { it.uuid == uuid }
    }

    companion object {
        const val LATENCY = 500L
    }
}

private fun task(uuid: String, cancellable: Boolean = true) = PlexActivity(uuid, "media.generate.bif", "Task $uuid", "Movies", 40, cancellable)

class ServerTasksStoreTest {
    private val latency = FakeTaskServers.LATENCY
    private val poll = ServerTasksStore.POLL_MILLIS

    private fun TestScope.store(servers: FakeTaskServers, form: FormFactor = FormFactor.DESKTOP): ServerTasksStore =
        ServerTasksStore(servers, MutableStateFlow(form), backgroundScope).also { runCurrent() }

    @Test
    fun `the panel loads at once then polls 3 s after each answer one load at a time`() = runTest {
        val servers = FakeTaskServers()
        servers.tasks[ServerId("alpha")] = mutableListOf(task("a"))
        val store = store(servers)

        store.toggle()
        runCurrent()
        assertEquals(ServerTasksLoad.LOADING, store.state.value.load)
        assertEquals(1, servers.fetches)
        advanceTimeBy(latency + 1)
        assertEquals(ServerTasksLoad.CONTENT, store.state.value.load)
        assertEquals(listOf(ServerTasksGroup("alpha", "Alpha", listOf(task("a")))), store.state.value.groups)

        advanceTimeBy(poll - 2)
        assertEquals(1, servers.fetches, "the next poll waits 3 s after the answer")
        advanceTimeBy(2)
        assertEquals(2, servers.fetches)
        assertEquals(ServerTasksLoad.CONTENT, store.state.value.load, "a poll keeps what shows")
        advanceTimeBy(latency + poll + 1)
        assertEquals(3, servers.fetches)
        assertEquals(1, servers.maxInFlight)
    }

    @Test
    fun `closing the panel stops polling and drops the request in flight`() = runTest {
        val servers = FakeTaskServers()
        val store = store(servers)

        store.toggle()
        advanceTimeBy(latency + poll + 1)
        assertEquals(2, servers.fetches)
        assertEquals(1, servers.inFlight)

        store.toggle()
        runCurrent()
        assertFalse(store.state.value.open)
        assertEquals(0, servers.inFlight)
        advanceTimeBy(10 * poll)
        assertEquals(2, servers.fetches)
    }

    @Test
    fun `cancelling a task cancels it on its server then loads the panel again`() = runTest {
        val servers = FakeTaskServers()
        servers.tasks[ServerId("alpha")] = mutableListOf(task("a"), task("b", cancellable = false))
        val store = store(servers)
        store.toggle()
        advanceTimeBy(latency + 1)

        store.cancel("alpha", "a")
        advanceTimeBy(101)
        assertEquals(listOf("a"), servers.cancelled)
        assertEquals(ServerTasksLoad.LOADING, store.state.value.load)
        assertEquals(2, servers.fetches)
        advanceTimeBy(latency)
        assertEquals(listOf("b"), store.state.value.groups.single().tasks.map { it.uuid })

        // The refresh replaced the poll that was due: still one load at a time, 3 s after the answer.
        advanceTimeBy(poll + latency)
        assertEquals(3, servers.fetches)
        assertEquals(1, servers.maxInFlight)
    }

    @Test
    fun `a failed first load says so and stops while a failed poll keeps the tasks and polls on`() = runTest {
        val servers = FakeTaskServers()
        servers.tasks[ServerId("alpha")] = mutableListOf(task("a"))
        servers.fail = true
        val store = store(servers)

        store.toggle()
        advanceTimeBy(latency + 1)
        assertEquals(ServerTasksLoad.ERROR, store.state.value.load)
        advanceTimeBy(10 * poll)
        assertEquals(1, servers.fetches)

        store.toggle()
        servers.fail = false
        store.toggle()
        advanceTimeBy(latency + 1)
        assertEquals(ServerTasksLoad.CONTENT, store.state.value.load)
        servers.fail = true
        advanceTimeBy(poll + latency)
        assertEquals(ServerTasksLoad.CONTENT, store.state.value.load)
        assertEquals(listOf("a"), store.state.value.groups.single().tasks.map { it.uuid })
        servers.fail = false
        advanceTimeBy(poll + latency)
        assertEquals(4, servers.fetches)
    }

    @Test
    fun `servers without tasks leave nothing running`() = runTest {
        val servers = FakeTaskServers()
        servers.list.value = listOf(NamedServer(ServerId("alpha"), "Alpha"), NamedServer(ServerId("beta"), "Beta"))
        servers.tasks[ServerId("beta")] = mutableListOf(task("x"))
        val store = store(servers)

        store.toggle()
        advanceTimeBy(latency + 1)
        assertEquals(listOf("Beta"), store.state.value.groups.map { it.name }, "only servers running tasks are listed")

        servers.tasks.clear()
        advanceTimeBy(poll + latency)
        assertEquals(ServerTasksLoad.CONTENT, store.state.value.load)
        assertTrue(store.state.value.groups.isEmpty())
    }

    @Test
    fun `the button shows off phones and tablets while a Plex server is online`() = runTest {
        val handheld = FakeTaskServers()
        val phone = store(handheld, FormFactor.HANDHELD)
        assertFalse(phone.state.value.shown)
        phone.toggle()
        runCurrent()
        assertFalse(phone.state.value.open)
        assertEquals(0, handheld.fetches)

        assertTrue(store(FakeTaskServers(), FormFactor.TV).state.value.shown)

        val servers = FakeTaskServers()
        val desktop = store(servers)
        assertTrue(desktop.state.value.shown)
        desktop.toggle()
        advanceTimeBy(latency + 1)
        servers.list.value = emptyList()
        runCurrent()
        assertFalse(desktop.state.value.shown)
        assertFalse(desktop.state.value.open, "the last Plex server going closes the panel")
        advanceTimeBy(10 * poll)
        assertEquals(1, servers.fetches)
    }
}
