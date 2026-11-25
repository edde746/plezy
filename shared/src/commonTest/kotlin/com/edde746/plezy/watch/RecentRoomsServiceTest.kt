package com.edde746.plezy.watch

import com.edde746.plezy.data.testData
import com.edde746.plezy.settings.ProfileSettings
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.time.Clock
import kotlin.time.Instant

class RecentRoomsServiceTest {
    private val data = testData()
    private val settings = data.profileSettings
    private var nowMs = 1_000_000L
    private val clock = object : Clock {
        override fun now(): Instant = Instant.fromEpochMilliseconds(nowMs++)
    }
    private val service = RecentRoomsService(settings, clock)
    private val public = WatchPartyRelays.relayScopeOf(null)
    private val custom = WatchPartyRelays.relayScopeOf("https://relay.example.test")

    @AfterTest
    fun close() = data.close()

    private suspend fun rooms(profile: String, scope: String) = service.observe(profile, scope).first()

    private suspend fun codes(profile: String, scope: String) = rooms(profile, scope).map { it.code }

    private suspend fun stored(profile: String): List<JsonObject> =
        settings.value(profile, ProfileSettings.watchTogetherRecentRooms).orEmpty().map { it as JsonObject }

    private suspend fun seed(profile: String, rows: JsonArray) = settings.set(profile, ProfileSettings.watchTogetherRecentRooms, rows)

    private fun row(code: String, scope: String, lastUsed: Long, name: String? = null) = buildJsonObject {
        put("code", code)
        put("relayScope", scope)
        name?.let { put("name", it) }
        put("lastUsed", lastUsed)
    }

    @Test
    fun roomsAreKeptPerProfileAndPerRelayScope() = runTest {
        service.remember("profile-a", "K7MQ2X", public)

        assertEquals(listOf("K7MQ2X"), codes("profile-a", public))
        assertEquals(emptyList(), codes("profile-b", public))
        assertEquals(emptyList(), codes("profile-a", custom))
    }

    @Test
    fun theSameCodeOnTwoRelaysIsRenamedAndRemovedIndependently() = runTest {
        service.remember("profile-a", "K7MQ2X", public)
        service.remember("profile-a", "K7MQ2X", custom)

        service.rename("profile-a", "K7MQ2X", public, "Movie night")
        assertEquals("Movie night", rooms("profile-a", public).single().name)
        assertNull(rooms("profile-a", custom).single().name)

        service.remove("profile-a", "K7MQ2X", custom)
        assertEquals(emptyList(), codes("profile-a", custom))
        assertEquals(listOf("K7MQ2X"), codes("profile-a", public))
    }

    @Test
    fun renamingToNullClearsTheNameRenamingAnUnknownRoomChangesNothing() = runTest {
        service.remember("profile-a", "K7MQ2X", public)
        service.rename("profile-a", "K7MQ2X", public, "Movie night")
        service.rename("profile-a", "K7MQ2X", public, null)
        assertNull(rooms("profile-a", public).single().name)
        assertFalse("name" in stored("profile-a").single())

        val before = stored("profile-a")
        service.rename("profile-a", "ABCDEF", public, "Nope")
        assertEquals(before, stored("profile-a"))
    }

    @Test
    fun joiningAKnownRoomAgainMovesItFirstAndKeepsItsName() = runTest {
        seed("profile-a", JsonArray(listOf(row("K7MQ2X", public, 1, "Old friends"), row("ABCDEF", public, 2))))
        assertEquals(listOf("ABCDEF", "K7MQ2X"), codes("profile-a", public))

        service.remember("profile-a", "K7MQ2X", public)

        val rooms = rooms("profile-a", public)
        assertEquals(listOf("K7MQ2X", "ABCDEF"), rooms.map { it.code })
        assertEquals("Old friends", rooms.first().name)
        assertEquals(2, stored("profile-a").size)
    }

    @Test
    fun keepsThe20MostRecentRoomsAcrossRelayScopes() = runTest {
        seed("profile-a", JsonArray((0 until 20).map { row(code(it), if (it % 2 == 0) public else custom, it + 1L) }))

        service.remember("profile-a", code(20), custom)

        val rows = stored("profile-a")
        assertEquals(20, rows.size)
        assertFalse(rows.any { it["code"]?.jsonPrimitive?.content == code(0) }, "the oldest room goes")
        assertEquals(code(20), rows.first()["code"]?.jsonPrimitive?.content)
        assertEquals(code(20), codes("profile-a", custom).first())
    }

    @Test
    fun codesOfTheFormerRelayAndUnnormalizedCodesAreNotShown() = runTest {
        seed(
            "profile-a",
            buildJsonArray {
                add(buildJsonObject { put("code", "ROOM1"); put("relayScope", public); put("name", "Former relay"); put("lastUsed", 3); put("controlMode", 0) })
                add(row("AB2CD", public, 2))
                add(row("k7m-q2x", public, 4))
                add(row("K7MQ2X", public, 1))
            },
        )

        assertEquals(listOf("K7MQ2X"), codes("profile-a", public))

        service.remember("profile-a", "ABCDEF", public)
        assertEquals(listOf("ABCDEF", "K7MQ2X"), stored("profile-a").map { it["code"]?.jsonPrimitive?.content })
    }

    @Test
    fun unreadableHistoryReadsAsEmptyAndGivesWayToTheNextRoom() = runTest {
        seed("profile-a", JsonArray(listOf(JsonPrimitive("not a room"), buildJsonObject { put("code", "K7MQ2X") })))
        assertEquals(emptyList(), codes("profile-a", public))

        service.remember("profile-a", "K7MQ2X", public)
        assertEquals(listOf("K7MQ2X"), codes("profile-a", public))
    }

    private fun code(index: Int) = "K7MQ${ALPHABET[index / ALPHABET.length]}${ALPHABET[index % ALPHABET.length]}"

    private companion object {
        const val ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ"
    }
}
