package com.edde746.plezy.data.music

import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MusicSessionRepositoryTest {
    private val data = testData()
    private val sessions = data.musicSessions

    @AfterTest
    fun close() = data.close()

    private fun session(profileId: String, queueJson: String = "[]") = MusicSession(
        profileId = profileId,
        queueJson = queueJson,
        orderJson = "[1,0]",
        cursor = 0,
        shuffled = true,
        repeatMode = "all",
        contextTitle = "Album",
        contextKind = "album",
        positionMs = 1234,
        updatedAt = 1,
    )

    @Test
    fun eachProfileKeepsItsLastSessionUntilItEnds() = runTest {
        sessions.save(session("p1"))
        sessions.save(session("p2"))
        assertEquals(session("p1"), sessions.load("p1"))

        sessions.save(session("p1", queueJson = """[{"id":"t1"},{"id":"t2"}]"""))
        assertEquals("""[{"id":"t1"},{"id":"t2"}]""", sessions.load("p1")?.queueJson, "a save replaces the session")

        sessions.deleteForProfile("p1")
        assertNull(sessions.load("p1"))
        assertEquals(session("p2"), sessions.load("p2"))
        sessions.clearAll()
        assertNull(sessions.load("p2"))
    }

    @Test
    fun progressMovesTheCursorAndPlayheadOfAStoredSessionOnly() = runTest {
        sessions.save(session("p1", queueJson = "[1,2]"))
        sessions.updateProgress("p1", cursor = 1, positionMs = 5000, updatedAt = 9)
        assertEquals(session("p1", queueJson = "[1,2]").copy(cursor = 1, positionMs = 5000, updatedAt = 9), sessions.load("p1"))

        sessions.updateProgress("p2", cursor = 1, positionMs = 5000, updatedAt = 9)
        assertNull(sessions.load("p2"))
    }
}
