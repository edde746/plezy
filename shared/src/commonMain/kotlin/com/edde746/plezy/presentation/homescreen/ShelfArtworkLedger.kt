package com.edde746.plezy.presentation.homescreen

/**
 * The bookkeeping of a home screen that stores its posters as files (the Apple TV's Top Shelf): which file each item of
 * the committed shelf shows, which files that shelf no longer uses, and when those may go. The platform does the
 * downloads and file operations; this decides.
 *
 * Files are named by the platform (a folder per owner and a file per poster source, `<folder>/<name>`). A poster whose
 * new source fails keeps the file the committed shelf showed for the same item and owner ([fallback]). A file the
 * committed shelf stops using is superseded, not deleted: the system may still draw the previous content from it, so it
 * goes only [graceMillis] after it was superseded, and only if the shelf committed by then doesn't use it again
 * ([prunable], at most [batch] files a pass). Files found on disk that no shelf of this process committed (a relaunch)
 * get the same grace from the first time they are seen.
 */
class ShelfArtworkLedger(private val graceMillis: Long = PRUNE_GRACE_MILLIS, private val batch: Int = PRUNE_BATCH) {
    private var owner: String? = null
    private var files: Map<String, String> = emptyMap()
    private val superseded = HashMap<String, Long>()

    /** The file the committed shelf of [owner] shows for [contentId], to keep when its new poster fails; null for none. */
    fun fallback(owner: String, contentId: String): String? = if (owner == this.owner) files[contentId] else null

    /**
     * Records the shelf just committed: [owner] (null: no owner) shows [files] (content id to file). Files of the
     * previous shelf it no longer uses become superseded at [nowMillis]; a superseded file used again is kept.
     */
    fun commit(owner: String?, files: Map<String, String>, nowMillis: Long) {
        val inUse = files.values.toSet()
        for (file in this.files.values) if (file !in inUse) superseded.getOrPut(file) { nowMillis }
        superseded.keys.removeAll(inUse)
        this.owner = owner
        this.files = files
    }

    /**
     * Of the files on disk ([existing]), those that may be deleted at [nowMillis]: superseded at least [graceMillis]
     * ago and not used by the committed shelf, at most [batch] of them. A file on disk the ledger hasn't seen before is
     * superseded now. Deleted files are forgotten.
     */
    fun prunable(existing: List<String>, nowMillis: Long): List<String> {
        val inUse = files.values.toSet()
        for (file in existing) if (file !in inUse) superseded.getOrPut(file) { nowMillis }
        val present = existing.toSet()
        superseded.keys.retainAll(present)
        val due = superseded.filter { (file, since) -> file !in inUse && nowMillis - since >= graceMillis }.keys.take(batch)
        superseded.keys.removeAll(due.toSet())
        return due
    }

    /** When the next file becomes prunable, in epoch milliseconds; null when none waits. */
    fun nextPruneAt(): Long? = superseded.values.minOrNull()?.plus(graceMillis)

    companion object {
        /** How long a superseded poster stays for the system's previous content: a minute. */
        const val PRUNE_GRACE_MILLIS: Long = 60_000

        /** How many files one prune pass deletes. */
        const val PRUNE_BATCH: Int = 64
    }
}

/**
 * The byte limits of one poster download within its shelf's budget: [accept] each chunk as it arrives and stop at the
 * first false, so an image of unknown length is cut off at the limit instead of being read whole. A response that
 * announces a length over the limit is refused before its body ([acceptsLength]).
 */
class PosterByteCap(private val budget: ShelfByteBudget, private val imageLimit: Long = POSTER_IMAGE_LIMIT) {
    private var received = 0L

    /** Whether a response announcing [length] bytes may be read at all; an unknown length (null or negative) may. */
    fun acceptsLength(length: Long?): Boolean = length == null || length < 0 || (length <= imageLimit && length <= budget.bytesLeft)

    /** Charges [count] more bytes to the image and the shelf; false once either limit is passed. */
    fun accept(count: Int): Boolean {
        received += count
        budget.bytesLeft -= count
        return received <= imageLimit && budget.bytesLeft >= 0
    }

    companion object {
        /** At most 2 MiB per poster. */
        const val POSTER_IMAGE_LIMIT: Long = 2L * 1024 * 1024
    }
}

/** One shelf's bytes for all its posters, 8 MiB: every poster's bytes count, a refused one's too. */
class ShelfByteBudget(var bytesLeft: Long = SHELF_LIMIT) {
    companion object {
        const val SHELF_LIMIT: Long = 8L * 1024 * 1024
    }
}
