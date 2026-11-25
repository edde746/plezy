package com.edde746.plezy.data.tracker

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.Tx
import com.edde746.plezy.data.db.Profile_setting
import com.edde746.plezy.data.db.Tracker_write_queue
import com.edde746.plezy.data.settings.settingsJson
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.settings.ProfileSetting
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.trackers.AnimeIds
import com.edde746.plezy.trackers.TrackerContext
import com.edde746.plezy.trackers.TrackerMediaKind
import com.edde746.plezy.trackers.TrackerService
import kotlin.time.Instant
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.double
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/** A watched or unwatched write waiting for a retry. */
data class QueuedTrackerWrite(
    /** Identifies this queued write for [TrackerWriteQueue.complete] and [TrackerWriteQueue.recordFailure]. */
    val id: Long,
    val service: TrackerService,
    /** The remote row the write changes; the queue keeps one write per key. */
    val coalesceKey: String,
    /** The item, exactly as the failed write had it: a replay doesn't resolve it again. */
    val context: TrackerContext,
    /** A watched write, or with `false` its removal. */
    val watched: Boolean,
    /** For series-progress services: the progress the write claims; `null` for history writes and removals. */
    val progressClaim: Long?,
    /** When the watch happened, epoch milliseconds. */
    val watchedAt: Long,
    /** Failed attempts so far. */
    val attempts: Int,
)

/** A write to queue ([TrackerWriteQueue.enqueue]), as [QueuedTrackerWrite] describes its fields. */
data class TrackerWriteRequest(val coalesceKey: String, val context: TrackerContext, val watched: Boolean, val progressClaim: Long?)

/**
 * The persisted retry queue for failed tracker watched and unwatched writes, per profile scope ([profileUserScope]: a
 * Plex Home user's profiles on every account share theirs); every call takes a profile id. Live scrobbles are never
 * queued. The tracker coordinator drains it ([pending]) on connect, profile bind, app resume and network restore.
 *
 * Coalescing is by intent, per profile, service and [QueuedTrackerWrite.coalesceKey]:
 * - a history write ("watched" or "not watched") replaces any write queued for the same key and moves to the back, so a
 *   failed watched write never replays over a later un-watch;
 * - a progress claim ("at least episode N") is dropped when a higher claim for the key is queued, so the list never
 *   walks backwards.
 *
 * A write is given up on (dropped by the coordinator) once it failed [MAX_ATTEMPTS] times.
 */
class TrackerWriteQueue internal constructor(private val db: Db) {
    /**
     * The profile's queued writes, in the order their intents were expressed. A row that no longer decodes, or names a
     * service this build doesn't know, is dropped with an error log.
     */
    suspend fun pending(profileId: String): List<QueuedTrackerWrite> {
        val dropped = mutableListOf<Long>()
        val writes = db.read { trackerQueries.selectQueued(profileUserScope(profileId)).executeAsList() }.mapNotNull { row ->
            val service = TrackerService.fromId(row.service)
            if (service == null) {
                Log.e(TAG) { "queued write ${row.id} of unknown service '${row.service}' dropped" }
                dropped += row.id
                return@mapNotNull null
            }
            try {
                row.toModel(service)
            } catch (e: IllegalArgumentException) {
                Log.e(TAG, e) { "${service.id}: queued write ${row.id} unreadable, dropped" }
                dropped += row.id
                null
            }
        }
        if (dropped.isNotEmpty()) db.write { for (id in dropped) q.trackerQueries.deleteQueued(id) }
        return writes
    }

    /**
     * Queues each of [writes] as the surviving intent for its key, at the back with no attempts counted, in place of
     * any write queued for the key; a claim lower than one queued for its key is left out. [watchedAt]: when the watch
     * happened, epoch milliseconds. Returns how many were queued: none when the account they were written through is no
     * longer connected under [connectedAt] (it signed out or reconnected meanwhile, which dropped its queue), since the
     * rows would otherwise replay through the account that replaced it.
     */
    suspend fun enqueue(profileId: String, service: TrackerService, connectedAt: Long, writes: List<TrackerWriteRequest>, watchedAt: Long): Int =
        db.write {
            val scope = profileUserScope(profileId)
            val account = q.trackerQueries.selectAccount(scope, service.id).executeAsOneOrNull()
            if (account?.connected_at != connectedAt) return@write 0
            writes.count { write ->
                insert(scope, service, write.coalesceKey, write.context, write.watched, write.progressClaim, watchedAt, attempts = 0)
            }
        }

    /** Whether the write [id] is still queued (a newer write for its key replaces or covers it). */
    suspend fun isQueued(id: Long): Boolean = db.read { trackerQueries.selectQueuedId(id).executeAsOneOrNull() != null }

    /** The writes went through, no longer apply, or are given up on: drop them. A newer write queued for a key stays. */
    suspend fun complete(ids: List<Long>) {
        if (ids.isEmpty()) return
        db.write { for (id in ids) q.trackerQueries.deleteQueued(id) }
    }

    /** Counts a failed attempt of each write (not for transient errors: rate limits, outages, the network). */
    suspend fun recordFailure(ids: List<Long>) {
        if (ids.isEmpty()) return
        db.write { for (id in ids) q.trackerQueries.incrementAttempts(id) }
    }

    /**
     * Drops the queued writes of [service] that completed direct writes cover, by key: all of a key's when its applied
     * progress is `null` (a history write or a removal), otherwise only a claim up to it or a write that claims nothing.
     */
    suspend fun invalidate(profileId: String, service: TrackerService, applied: Map<String, Long?>) {
        if (applied.isEmpty()) return
        db.write {
            for ((key, appliedProgress) in applied) {
                val queued = q.trackerQueries.selectQueuedByKey(profileUserScope(profileId), service.id, key).executeAsOneOrNull() ?: continue
                if (covers(appliedProgress, queued.progress_claim)) q.trackerQueries.deleteQueued(queued.id)
            }
        }
    }

    /**
     * Drops every write of [service] queued for the profile, so none replays through the account that connects next
     * (a disconnect, a session found dead). Returns how many were dropped.
     */
    suspend fun removeService(profileId: String, service: TrackerService): Int = db.write {
        val scope = profileUserScope(profileId)
        val count = q.trackerQueries.selectQueued(scope).executeAsList().count { it.service == service.id }
        q.trackerQueries.deleteQueuedForService(scope, service.id)
        count
    }.also { if (it > 0) Log.i(TAG) { "${service.id}: dropped $it queued write(s) on disconnect" } }

    /**
     * Moves the writes Plezy's earlier releases left queued for the profile (imported as [ProfileSettings.trackerWriteQueue],
     * and Trakt's older [ProfileSettings.traktSyncQueue]) into this queue, then removes both settings, in one
     * transaction. A queue that doesn't read is kept aside as [ProfileSettings.trackerWriteQueueCorrupt]; Trakt's older
     * queue that doesn't read is dropped. Runs once per profile: there is nothing left the next time.
     */
    suspend fun importEarlierRelease(profileId: String) {
        val scope = profileUserScope(profileId)
        db.write {
            val stored = readSetting(scope, ProfileSettings.trackerWriteQueue)
            val legacy = readSetting(scope, ProfileSettings.traktSyncQueue)
            if (stored == null && legacy == null) return@write
            val items = mutableListOf<ImportedWrite>()
            if (stored != null) {
                try {
                    items += stored.jsonArray.map { earlierWrite(it.jsonObject) }
                } catch (e: IllegalArgumentException) {
                    Log.e(TAG, e) { "tracker write queue of an earlier release unreadable, kept aside" }
                    q.deviceSettingQueries.upsertProfileSetting(
                        Profile_setting(scope, ProfileSettings.trackerWriteQueueCorrupt.baseKey, settingsJson.encodeToString(JsonElement.serializer(), stored)),
                    )
                }
                q.deviceSettingQueries.deleteProfileSetting(scope, ProfileSettings.trackerWriteQueue.baseKey)
            }
            if (legacy != null) {
                try {
                    items += legacy.jsonArray.mapNotNull { legacyTraktWrite(it.jsonObject) }
                } catch (e: IllegalArgumentException) {
                    Log.e(TAG, e) { "Trakt write queue of an earlier release unreadable, dropped" }
                }
                q.deviceSettingQueries.deleteProfileSetting(scope, ProfileSettings.traktSyncQueue.baseKey)
            }
            val watchedAtNow = now()
            for (item in items) {
                insert(scope, item.service, item.coalesceKey, item.context, item.watched, item.progressClaim, item.watchedAt ?: watchedAtNow, item.attempts)
            }
            Log.i(TAG) { "${items.size} queued tracker write(s) of an earlier release imported" }
        }
    }

    /**
     * Inserts a write under [scope] as the surviving intent for its key unless a higher claim for the key is queued;
     * returns whether it was.
     */
    private fun Tx.insert(
        scope: String,
        service: TrackerService,
        key: String,
        context: TrackerContext,
        watched: Boolean,
        progressClaim: Long?,
        watchedAt: Long,
        attempts: Int,
    ): Boolean {
        val queuedClaim = q.trackerQueries.selectQueuedByKey(scope, service.id, key).executeAsOneOrNull()?.progress_claim
        // A higher claim for the entry already waits; this one would only walk it backwards.
        if (progressClaim != null && queuedClaim != null && queuedClaim > progressClaim) return false
        q.trackerQueries.deleteQueuedByKey(scope, service.id, key)
        q.trackerQueries.insertQueued(
            scope, service.id, key, watched, contentJson.encodeToString(TrackerContext.serializer(), context),
            progressClaim, watchedAt, attempts.toLong(),
        )
        return true
    }

    private fun Tx.readSetting(scope: String, setting: ProfileSetting<JsonElement?>): JsonElement? =
        q.deviceSettingQueries.selectProfileSetting(scope, setting.baseKey).executeAsOneOrNull()?.let(setting::decode)

    /** A write of an earlier release's queue, before it is inserted; [watchedAt] `null` when its date didn't read. */
    private class ImportedWrite(
        val service: TrackerService,
        val coalesceKey: String,
        val context: TrackerContext,
        val watched: Boolean,
        val progressClaim: Long?,
        val watchedAt: Long?,
        val attempts: Int,
    )

    companion object {
        /** The most attempts a write gets. */
        const val MAX_ATTEMPTS: Int = 5

        private const val TAG = "trackers"

        /** The context's JSON in `context_json`: fields a later build added are skipped. */
        private val contentJson = Json { ignoreUnknownKeys = true }

        /**
         * Whether a completed write that applied [appliedProgress] covers a queued one claiming [claim]: a `null`
         * applied progress (a history write, a removal) covers it outright, as does anything covering a write that
         * claims nothing.
         */
        fun covers(appliedProgress: Long?, claim: Long?): Boolean = appliedProgress == null || claim == null || claim <= appliedProgress

        /** @throws IllegalArgumentException when the row's context doesn't decode. */
        private fun Tracker_write_queue.toModel(service: TrackerService) = QueuedTrackerWrite(
            id = id,
            service = service,
            coalesceKey = coalesce_key,
            context = contentJson.decodeFromString(TrackerContext.serializer(), context_json),
            watched = watched,
            progressClaim = progress_claim,
            watchedAt = watched_at,
            attempts = attempts.toInt(),
        )

        /**
         * One item of an earlier release's queue: `{service, watched, ctx, coalesceKey, progressClaim?, watchedAtIso,
         * attempts}`. @throws IllegalArgumentException when it doesn't read.
         */
        private fun earlierWrite(json: JsonObject): ImportedWrite {
            val serviceName = json.getValue("service").jsonPrimitive.content
            val service = requireNotNull(TrackerService.fromId(serviceName)) { "unknown service $serviceName" }
            return ImportedWrite(
                service = service,
                coalesceKey = json.getValue("coalesceKey").jsonPrimitive.content,
                context = earlierContext(json.getValue("ctx").jsonObject),
                watched = json.getValue("watched").jsonPrimitive.boolean,
                progressClaim = json.number("progressClaim")?.toLong(),
                watchedAt = epochMillis(json.getValue("watchedAtIso").jsonPrimitive.content),
                attempts = json.number("attempts") ?: 0,
            )
        }

        /**
         * An earlier release's context: `{external{imdb,tmdb,tvdb,anidb}, anime{mal,anilist,simkl}?, isMovie, ratingKey,
         * libraryGlobalKey?, season?, episodeNumber?, animeProgress?}`.
         */
        private fun earlierContext(json: JsonObject): TrackerContext {
            val anime = json["anime"]?.takeUnless { it is JsonNull }?.jsonObject
            val movie = json.getValue("isMovie").jsonPrimitive.boolean
            return TrackerContext(
                kind = if (movie) TrackerMediaKind.MOVIE else TrackerMediaKind.EPISODE,
                ids = externalIds(json.getValue("external").jsonObject),
                anime = anime?.let { AnimeIds(mal = it.number("mal"), anilist = it.number("anilist"), simkl = it.number("simkl")) },
                season = json.number("season"),
                episode = json.number("episodeNumber"),
                animeProgress = json.number("animeProgress"),
                ratingKey = json.getValue("ratingKey").jsonPrimitive.content,
                libraryGlobalKey = json.string("libraryGlobalKey"),
            )
        }

        /**
         * One row of Trakt's queue before the shared one: `{ids, ratingKey, libraryGlobalKey, kind, season, number, op,
         * watchedAtIso, attempts}`, `op` `add` for a watched write. `null` for a row that names no item, which nothing
         * could have been written for.
         */
        private fun legacyTraktWrite(json: JsonObject): ImportedWrite? {
            val ids = externalIds(json.getValue("ids").jsonObject)
            val movie = json.string("kind") == "movie"
            val context = TrackerContext(
                kind = if (movie) TrackerMediaKind.MOVIE else TrackerMediaKind.EPISODE,
                ids = ids,
                season = if (movie) null else requireNotNull(json.number("season")) { "episode without a season" },
                episode = if (movie) null else requireNotNull(json.number("number")) { "episode without a number" },
                ratingKey = json.getValue("ratingKey").jsonPrimitive.content,
                libraryGlobalKey = json.string("libraryGlobalKey"),
            )
            val row = ids.rowIdentity() ?: return null
            val coordinate = if (movie) "movie" else "s${context.season}e${context.episode}"
            return ImportedWrite(
                service = TrackerService.TRAKT,
                coalesceKey = "${TrackerService.TRAKT.id}|$coordinate|$row",
                context = context,
                watched = json.string("op") == "add",
                progressClaim = null,
                watchedAt = epochMillis(json.getValue("watchedAtIso").jsonPrimitive.content),
                attempts = json.number("attempts") ?: 0,
            )
        }

        private fun externalIds(json: JsonObject) = ExternalIds(
            imdb = json.string("imdb"),
            tmdb = json.number("tmdb"),
            tvdb = json.number("tvdb"),
            anidb = json.number("anidb"),
        )

        /** An ISO-8601 instant as epoch milliseconds; `null` for one without a UTC offset or that doesn't read. */
        private fun epochMillis(iso: String): Long? = try {
            Instant.parse(iso).toEpochMilliseconds()
        } catch (e: IllegalArgumentException) {
            Log.w(TAG) { "queued write's date '$iso' unreadable, filed as now" }
            null
        }

        private fun JsonObject.string(name: String): String? = (get(name) as? JsonPrimitive)?.takeUnless { it is JsonNull }?.content

        /** A JSON number as an Int (a whole double too); @throws IllegalArgumentException for anything else. */
        private fun JsonObject.number(name: String): Int? {
            val value = get(name)?.takeUnless { it is JsonNull } ?: return null
            val primitive = value.jsonPrimitive
            require(!primitive.isString) { "$name is a string" }
            return primitive.intOrNull ?: primitive.double.toInt()
        }
    }
}
