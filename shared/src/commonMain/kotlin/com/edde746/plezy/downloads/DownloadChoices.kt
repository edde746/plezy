package com.edde746.plezy.downloads

import com.edde746.plezy.backend.localizedErrorReason
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException

/** Which episodes a batch download (show or season) takes. */
enum class DownloadFilter { ALL, UNWATCHED }

/** The message for an episode-count entry: null when [text] is a valid count (0 only when [allowZero]). */
fun validateEpisodeCountInput(text: String, allowZero: Boolean): String? {
    val count = text.toIntOrNull()
    return if (count == null || count < 0 || (!allowZero && count == 0)) T.downloads.invalidEpisodeCount else null
}

/** The rows of the show and season download picker. */
enum class DownloadChoice {
    ALL,
    UNWATCHED,
    NEXT_5,
    NEXT_10,
    CUSTOM,

    /** Only offered when the item already has downloads. */
    DELETE,
    ;

    /** The filter this row queues with. */
    val filter: DownloadFilter get() = if (this == ALL) DownloadFilter.ALL else DownloadFilter.UNWATCHED

    /** The episode cap this row queues with; [customCount] for [CUSTOM]; null: no cap. */
    fun maxCount(customCount: Int? = null): Int? = when (this) {
        NEXT_5 -> 5
        NEXT_10 -> 10
        CUSTOM -> customCount
        else -> null
    }

    companion object {
        /** The rows offered, [DELETE] last when [hasDownloads]. */
        fun options(hasDownloads: Boolean): List<DownloadChoice> = if (hasDownloads) entries else entries - DELETE
    }
}

/** Whether a download is made once or kept synced by a rule. */
enum class SyncChoice { DOWNLOAD_ONCE, KEEP_SYNCED }

/** What removing a sync rule removed. */
enum class SyncRuleRemovalResult { RULE_ONLY, RULE_AND_DOWNLOADS }

fun syncRuleRemovalMessage(result: SyncRuleRemovalResult): String =
    if (result == SyncRuleRemovalResult.RULE_AND_DOWNLOADS) T.downloads.syncRuleAndDownloadsRemoved else T.downloads.syncRuleRemoved

/**
 * The outcome of a download request: [count] items queued, and whether a sync rule was created or updated.
 * [isListRule]: the rule mirrors a collection or playlist. [unit]: what the queued items are, for the toast's wording.
 */
data class DownloadResult(
    val count: Int,
    val syncRuleCreated: Boolean = false,
    val syncRuleUpdated: Boolean = false,
    val isListRule: Boolean = false,
    val unit: QueuedUnit = QueuedUnit.EPISODES,
) {
    fun toSnackBarMessage(): String = when {
        syncRuleUpdated -> T.downloads.syncRuleUpdated
        syncRuleCreated -> if (isListRule) T.downloads.syncRuleListCreated else T.downloads.syncRuleCreated(count = count.toString())
        count > 1 -> when (unit) {
            QueuedUnit.EPISODES -> T.downloads.episodesQueued(count = count.toString())
            QueuedUnit.TRACKS -> T.downloads.tracksQueued(count = count.toString())
            QueuedUnit.MOVIES -> T.downloads.moviesQueued(count = count.toString())
            QueuedUnit.ITEMS -> T.downloads.itemsQueued(count = count.toString())
        }
        else -> T.downloads.downloadQueued
    }
}

/** What a download request queued, which words its toast: a show's episodes, music's tracks, movies, or a mix. */
enum class QueuedUnit {
    EPISODES,
    TRACKS,
    MOVIES,
    ITEMS,
    ;

    companion object {
        /** The unit queuing [kind] yields: a show, season or episode queues episodes; music queues tracks. */
        fun of(kind: MediaKind): QueuedUnit = when {
            kind == MediaKind.MOVIE -> MOVIES
            kind == MediaKind.SHOW || kind == MediaKind.SEASON || kind == MediaKind.EPISODE -> EPISODES
            kind.isMusic -> TRACKS
            else -> ITEMS
        }

        /** The unit a list of [kinds] yields: theirs when they share one, else [ITEMS]. */
        fun of(kinds: Iterable<MediaKind>): QueuedUnit = kinds.map(::of).distinct().singleOrNull() ?: ITEMS
    }
}

/** Thrown when Wi-Fi-only downloads are on and cellular is the only link. */
class CellularDownloadBlockedException : IllegalStateException(T.settings.cellularDownloadBlocked)

/** A download request's feedback: [message] shown as success, or as an error when [isError]. */
data class DownloadFeedback(val message: String, val isError: Boolean)

/**
 * Runs a download request and turns its outcome into feedback: the result's message, the cellular-blocked message, or
 * the generic load error. Null when the request was cancelled (it returned null).
 */
suspend fun queueWithFeedback(request: suspend () -> DownloadResult?): DownloadFeedback? = try {
    request()?.let { DownloadFeedback(it.toSnackBarMessage(), isError = false) }
} catch (e: CellularDownloadBlockedException) {
    DownloadFeedback(T.settings.cellularDownloadBlocked, isError = true)
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.e("Downloads", e) { "Failed to queue download" }
    DownloadFeedback(T.messages.errorLoading(error = localizedErrorReason(e)), isError = true)
}
