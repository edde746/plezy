package com.edde746.plezy.watchnext

import android.media.tv.TvContract.WatchNextPrograms
import com.edde746.plezy.presentation.homescreen.HomeScreenItem

/**
 * One row of Android TV's Watch Next table ([WatchNextPrograms]) as this app writes it, and reads it back to see what
 * changed: the item [contentId] (the internal provider id, `plezy_<serverId>_<itemId>`) of profile [ownerId] (the
 * internal provider data). Continue Watching has one item per title.
 */
internal data class WatchNextProgram(
    val ownerId: String,
    val contentId: String,
    val type: Int,
    val watchNextType: Int,
    val title: String,
    val episodeTitle: String?,
    val description: String?,
    val seasonNumber: String?,
    val episodeNumber: String?,
    val posterUri: String?,
    val posterAspectRatio: Int?,
    val durationMillis: Int,
    val lastPlaybackPositionMillis: Int,
    val lastEngagementMillis: Long,
    val intentUri: String,
) {
    /** The row's key across profiles ([watchNextKey]). */
    val key: String get() = watchNextKey(ownerId, contentId)
}

/** A row's [WatchNextProgram.key]: `<profile id>/<content id>`. */
internal fun watchNextKey(ownerId: String, contentId: String): String = "$ownerId/$contentId"

/**
 * [this] item of [ownerId] as its Watch Next row: an episode as [WatchNextPrograms.TYPE_TV_EPISODE] with its title and
 * numbers, anything else as [WatchNextPrograms.TYPE_MOVIE]; [WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE] when it
 * resumes somewhere, else [WatchNextPrograms.WATCH_NEXT_TYPE_NEXT]; the poster ([posterUri], the app's own copy) at
 * 16:9; the duration and position only with a duration. [intentUri] is what selecting the row starts: the item's link,
 * in this app.
 */
internal fun HomeScreenItem.toWatchNextProgram(ownerId: String, intentUri: String, posterUri: String?): WatchNextProgram {
    val episode = isEpisode
    val duration = durationMillis.coerceIn(0, Int.MAX_VALUE.toLong()).toInt()
    return WatchNextProgram(
        ownerId = ownerId,
        contentId = contentId,
        type = if (episode) WatchNextPrograms.TYPE_TV_EPISODE else WatchNextPrograms.TYPE_MOVIE,
        watchNextType = if (positionMillis > 0) WatchNextPrograms.WATCH_NEXT_TYPE_CONTINUE else WatchNextPrograms.WATCH_NEXT_TYPE_NEXT,
        title = title,
        episodeTitle = episodeTitle?.takeIf { episode },
        description = description,
        seasonNumber = seasonNumber?.takeIf { episode }?.toString(),
        episodeNumber = episodeNumber?.takeIf { episode }?.toString(),
        posterUri = posterUri,
        posterAspectRatio = posterUri?.let { WatchNextPrograms.ASPECT_RATIO_16_9 },
        durationMillis = duration,
        lastPlaybackPositionMillis = if (duration > 0) positionMillis.coerceIn(0, Int.MAX_VALUE.toLong()).toInt() else 0,
        lastEngagementMillis = lastEngagedMillis,
        intentUri = intentUri,
    )
}

/**
 * A row of this app's in the Watch Next table as read back: its id, what it holds, and whether the home screen still
 * shows it ([WatchNextPrograms.COLUMN_BROWSABLE]: the launcher clears it when the user removes the row).
 */
internal data class PublishedRow(val id: Long, val program: WatchNextProgram, val browsable: Boolean)

/**
 * What a publish changes in the Watch Next table, and the user's removals in force after it ([removed]: each removed
 * item's key, with the last engagement it had when the user removed it).
 */
internal data class WatchNextPlan(
    val insert: List<WatchNextProgram>,
    val update: List<Pair<Long, WatchNextProgram>>,
    val delete: List<Long>,
    val removed: Map<String, Long>,
)

/**
 * The changes that make this app's Watch Next rows [rows] show [programs], [ownerId]'s items (null for none: no
 * profile, signed out, between two profiles), touching only what differs: a row whose values changed is updated in
 * place (a saved position updates its one row), a program without a row goes in, and a row whose item left (finished,
 * removed from Continue Watching, another profile's) goes out, as do a key's extra rows.
 *
 * The user's removals ([removed], updated in the result): a row the home screen no longer shows ([PublishedRow.browsable]
 * false) was removed by the user. It is deleted and its item recorded, and a recorded item stays off the home screen
 * until it is watched again, its last engagement moving past the one recorded. A record goes once its item leaves
 * [ownerId]'s list; another profile's records stay for when it runs again.
 */
internal fun planWatchNext(
    ownerId: String?,
    programs: List<WatchNextProgram>,
    rows: List<PublishedRow>,
    removed: Map<String, Long>,
): WatchNextPlan {
    val removals = removed.toMutableMap()
    for (row in rows) {
        if (!row.browsable) removals[row.program.key] = maxOf(removals[row.program.key] ?: Long.MIN_VALUE, row.program.lastEngagementMillis)
    }
    val keys = programs.mapTo(HashSet()) { it.key }
    if (ownerId != null) {
        val prefix = watchNextKey(ownerId, "")
        removals.keys.removeAll { it.startsWith(prefix) && it !in keys }
    }
    val shown = programs.filter { program ->
        val at = removals[program.key]
        if (at != null && program.lastEngagementMillis > at) removals.remove(program.key)
        program.key !in removals
    }
    val kept = HashMap<String, PublishedRow>()
    val delete = ArrayList<Long>()
    for (row in rows) {
        val key = row.program.key
        if (row.browsable && key in keys && key !in removals && key !in kept) kept[key] = row else delete += row.id
    }
    val insert = ArrayList<WatchNextProgram>()
    val update = ArrayList<Pair<Long, WatchNextProgram>>()
    for (program in shown) {
        val row = kept[program.key]
        when {
            row == null -> insert += program
            row.program != program -> update += row.id to program
        }
    }
    return WatchNextPlan(insert, update, delete, removals)
}
