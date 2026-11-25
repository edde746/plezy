package com.edde746.plezy.servers

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.model.MediaVersion
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration

/** How much a server-side delete destroys. */
enum class DeleteImpactScope {
    /** Verified: exactly one file, which backs no other library item. */
    EXCLUSIVE,

    /** Verified: more than one file, or files that also back other items (a Plex `S01E01-E03.mkv`). */
    BROAD,

    /** Not established: the confirmation claims no scope. */
    UNVERIFIED,
}

/** Why a scope could not be established. */
enum class DeleteImpactUnverifiedReason {
    /** A metadata request failed or timed out: retrying may work. */
    PROBE_FAILED,

    /** The server answered without file paths (Plex hides them from restricted users): retrying never helps. */
    NO_FILE_INFO,
}

/**
 * What deleting one item destroys: [files], the server paths it removes (empty when unverified), and [sharedWith], the
 * other library items backed by one of them, which go with it.
 */
data class DeleteImpact(
    val scope: DeleteImpactScope,
    val files: Set<String> = emptySet(),
    val sharedWith: List<MediaItem> = emptyList(),
    val reason: DeleteImpactUnverifiedReason? = null,
) {
    val isUnverified: Boolean get() = scope == DeleteImpactScope.UNVERIFIED
    val isBroad: Boolean get() = scope == DeleteImpactScope.BROAD

    companion object {
        fun unverified(reason: DeleteImpactUnverifiedReason) = DeleteImpact(DeleteImpactScope.UNVERIFIED, reason = reason)

        internal fun verified(files: Set<String>, shared: List<MediaItem>) =
            DeleteImpact(if (files.size > 1 || shared.isNotEmpty()) DeleteImpactScope.BROAD else DeleteImpactScope.EXCLUSIVE, files, shared)
    }
}

/**
 * Every distinct file backing [versions], or null when the list can't be trusted to be complete: no versions, no
 * parts, or any part without a path (a version whose one part was made up because the payload carried none).
 */
fun completePartFiles(versions: List<MediaVersion>): Set<String>? {
    val files = mutableSetOf<String>()
    var sawPart = false
    for (version in versions) {
        for (part in version.parts) {
            sawPart = true
            val file = part.file
            if (file.isNullOrEmpty()) return null
            files += file
        }
    }
    return if (sawPart) files else null
}

/**
 * What deleting [item] destroys, established before asking: its own files (from the row, else the detail endpoint)
 * and, for an episode, the season's other episodes backed by one of them, resolved one at a time and stopping at the
 * first whose files stay unknown. Anything missing answers [DeleteImpactScope.UNVERIFIED], never a guess. Bounded by
 * [timeout]: at expiry the walk stops (the request in flight is cancelled with it) and the answer is a probe failure.
 */
suspend fun resolveDeleteImpact(
    item: MediaItem,
    client: MediaBackend,
    timeout: Duration = MediaServerTimeouts.DELETE_IMPACT_PROBE,
): DeleteImpact = try {
    withTimeoutOrNull(timeout) { resolve(item, client) } ?: run {
        Log.w(TAG) { "Delete impact probe timed out for ${item.backend.id} item ${item.id}" }
        DeleteImpact.unverified(DeleteImpactUnverifiedReason.PROBE_FAILED)
    }
} catch (e: CancellationException) {
    throw e
} catch (e: Exception) {
    Log.w(TAG, e) { "Delete impact probe failed for ${item.backend.id} item ${item.id}" }
    DeleteImpact.unverified(DeleteImpactUnverifiedReason.PROBE_FAILED)
}

private suspend fun resolve(item: MediaItem, client: MediaBackend): DeleteImpact {
    val (own, ownReason) = completeFilesFor(item, client)
    if (own == null) return DeleteImpact.unverified(ownReason!!)
    // Only an episode can share its file with another item; a movie's reach is its own parts.
    val parentId = if (item.kind == MediaKind.EPISODE) item.parentId else null
    if (parentId == null) return DeleteImpact.verified(own, emptyList())
    val shared = mutableListOf<MediaItem>()
    for (sibling in client.fetchChildren(parentId)) {
        if (sibling.id == item.id) continue
        val (files, reason) = completeFilesFor(sibling, client)
        // A sibling whose files stay unknown could be backed by this very file.
        if (files == null) return DeleteImpact.unverified(reason!!)
        if (files.any { it in own }) shared += sibling
    }
    return DeleteImpact.verified(own, shared)
}

/** Every file backing [item] (the row's, else the detail endpoint's), or why that list can't be trusted. */
private suspend fun completeFilesFor(item: MediaItem, client: MediaBackend): Pair<Set<String>?, DeleteImpactUnverifiedReason?> {
    completePartFiles(item.mediaVersions.orEmpty())?.let { return it to null }
    val full = try {
        client.fetchItem(item.id)
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Log.w(TAG, e) { "Delete impact: failed to resolve files for item ${item.id}" }
        return null to DeleteImpactUnverifiedReason.PROBE_FAILED
    } ?: return null to DeleteImpactUnverifiedReason.PROBE_FAILED
    val resolved = completePartFiles(full.mediaVersions.orEmpty())
    return if (resolved != null) resolved to null else null to DeleteImpactUnverifiedReason.NO_FILE_INFO
}

private const val TAG = "DeleteImpact"
