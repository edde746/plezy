package com.edde746.plezy.watch

import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ProfileSettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put
import kotlin.time.Clock

/** A room this profile created or joined, to join again by its [code] on the relays of [relayScope]. */
data class RecentRoom(val code: String, val relayScope: String, val name: String?, val lastUsedMs: Long)

/**
 * Recent rooms per profile scope ([ProfileSettings.watchTogetherRecentRooms]), shown per relay scope
 * ([WatchPartyRelays.relayScopeOf]), newest first, the [MAX_ROOMS] most recent kept across relay scopes. Only Open Watch
 * Party codes (6 symbols, normalized) are kept: rooms of Plezy's former relay had 5, and no relay knows them any more.
 */
internal class RecentRoomsService(private val settings: ProfileSettingsRepository, private val clock: Clock) {
    private val mutex = Mutex()

    fun observe(profileScope: String, relayScope: String): Flow<List<RecentRoom>> =
        settings.observe(profileScope, ProfileSettings.watchTogetherRecentRooms).map { stored ->
            roomsOf(stored).filter { it.relayScope == relayScope }
        }

    /** Puts [code] first, keeping its name when it is already there. */
    suspend fun remember(profileScope: String, code: String, relayScope: String) = update(profileScope) { rooms ->
        val now = clock.now().toEpochMilliseconds()
        val index = rooms.indexOfFirst { it.relayScope == relayScope && it.code == code }
        if (index >= 0) rooms[index] = rooms[index].copy(lastUsedMs = now) else rooms += RecentRoom(code, relayScope, null, now)
        true
    }

    /** Names the room ([name] null clears it); a room that isn't there changes nothing. */
    suspend fun rename(profileScope: String, code: String, relayScope: String, name: String?) = update(profileScope) { rooms ->
        val index = rooms.indexOfFirst { it.relayScope == relayScope && it.code == code }
        if (index >= 0) rooms[index] = rooms[index].copy(name = name)
        index >= 0
    }

    /** Removes the room of [code] on [relayScope] only. */
    suspend fun remove(profileScope: String, code: String, relayScope: String) = update(profileScope) { rooms ->
        rooms.removeAll { it.relayScope == relayScope && it.code == code }
    }

    /** Applies [change] to the stored rooms and saves them when it reports a change. */
    private suspend fun update(profileScope: String, change: (MutableList<RecentRoom>) -> Boolean) {
        mutex.withLock {
            val rooms = roomsOf(settings.value(profileScope, ProfileSettings.watchTogetherRecentRooms)).toMutableList()
            if (!change(rooms)) return
            val kept = rooms.sortedByDescending { it.lastUsedMs }.take(MAX_ROOMS)
            settings.set(profileScope, ProfileSettings.watchTogetherRecentRooms, JsonArray(kept.map(::toJson)))
        }
    }

    private fun roomsOf(stored: JsonArray?): List<RecentRoom> =
        stored.orEmpty().mapNotNull(::fromJson)
            .filter { WatchPartyRelays.normalizeRoomCode(it.code) == it.code }
            .sortedByDescending { it.lastUsedMs }

    private fun fromJson(row: JsonElement): RecentRoom? {
        if (row !is JsonObject) return null
        fun string(key: String) = (row[key] as? JsonPrimitive)?.takeIf { it.isString }?.content
        val code = string("code") ?: return null
        val relayScope = string("relayScope") ?: return null
        val lastUsed = (row["lastUsed"] as? JsonPrimitive)?.takeIf { !it.isString }?.longOrNull ?: return null
        return RecentRoom(code, relayScope, string("name"), lastUsed)
    }

    private fun toJson(room: RecentRoom): JsonObject = buildJsonObject {
        put("code", room.code)
        put("relayScope", room.relayScope)
        room.name?.let { put("name", it) }
        put("lastUsed", room.lastUsedMs)
    }

    private companion object {
        const val MAX_ROOMS = 20
    }
}
