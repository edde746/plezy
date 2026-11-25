package com.edde746.plezy.data.music

import com.edde746.plezy.data.Db
import com.edde746.plezy.data.db.Music_sessions

/** A profile's last music session, restored paused on the next launch. */
data class MusicSession(
    val profileId: String,
    /** The queue's items, a JSON array, as the player wrote it. */
    val queueJson: String,
    /** The play order, a JSON array of indexes into the queue (a permutation of it while shuffled). */
    val orderJson: String,
    /** The playing position in the play order. */
    val cursor: Int,
    val shuffled: Boolean,
    /** `off`, `all` or `one`. */
    val repeatMode: String,
    /** What the queue was started from (an album, a playlist), for its title. */
    val contextTitle: String?,
    val contextKind: String?,
    val positionMs: Long,
    /** Epoch milliseconds. */
    val updatedAt: Long,
)

/**
 * Each profile's last music session, written through during playback and dropped when the user ends the session or
 * the profile goes.
 */
class MusicSessionRepository internal constructor(private val db: Db) {
    suspend fun load(profileId: String): MusicSession? =
        db.read { musicSessionQueries.selectByProfile(profileId).executeAsOneOrNull() }?.toModel()

    /** Replaces the profile's session with [session]. */
    suspend fun save(session: MusicSession) {
        db.write {
            q.musicSessionQueries.upsert(
                Music_sessions(
                    profile_id = session.profileId,
                    queue_json = session.queueJson,
                    order_json = session.orderJson,
                    cursor = session.cursor.toLong(),
                    shuffled = session.shuffled,
                    repeat_mode = session.repeatMode,
                    context_title = session.contextTitle,
                    context_kind = session.contextKind,
                    position_ms = session.positionMs,
                    updated_at = session.updatedAt,
                ),
            )
        }
    }

    /** Moves the stored session's cursor and playhead, leaving its queue alone; does nothing when none is stored. */
    suspend fun updateProgress(profileId: String, cursor: Int, positionMs: Long, updatedAt: Long) {
        db.write { q.musicSessionQueries.updateProgress(cursor.toLong(), positionMs, updatedAt, profileId) }
    }

    /** Drops the profile's session: the user ended it, or the profile went. */
    suspend fun deleteForProfile(profileId: String) {
        db.write { q.musicSessionQueries.deleteForProfile(profileId) }
    }

    /** Drops every profile's session (a full sign-out). */
    suspend fun clearAll() {
        db.write { q.musicSessionQueries.deleteAll() }
    }

    /** Replaces each profile's stored queue JSON with what [rewrite] makes of it, where that differs. */
    suspend fun rewriteQueues(rewrite: (String) -> String) {
        db.write {
            for (row in q.musicSessionQueries.selectQueues().executeAsList()) {
                val rewritten = rewrite(row.queue_json)
                if (rewritten != row.queue_json) q.musicSessionQueries.updateQueue(rewritten, row.profile_id)
            }
        }
    }
}

private fun Music_sessions.toModel() = MusicSession(
    profileId = profile_id,
    queueJson = queue_json,
    orderJson = order_json,
    cursor = cursor.toInt(),
    shuffled = shuffled,
    repeatMode = repeat_mode,
    contextTitle = context_title,
    contextKind = context_kind,
    positionMs = position_ms,
    updatedAt = updated_at,
)
