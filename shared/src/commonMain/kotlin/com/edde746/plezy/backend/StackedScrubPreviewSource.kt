package com.edde746.plezy.backend

import com.edde746.plezy.model.MediaPartTimeline
import kotlin.time.Duration

/**
 * Previews for an item stacked across several files: each file has its own source on its own clock and the seek bar
 * spans the whole item, so a time goes to the file holding it, shifted onto that file's clock. [sources] lines up with
 * [MediaPartTimeline.parts]; a file whose source failed to load (null) shows no frames.
 */
class StackedScrubPreviewSource(private val timeline: MediaPartTimeline, private val sources: List<ScrubPreviewSource?>) :
    ScrubPreviewSource {
    init {
        require(sources.size == timeline.parts.size) { "${sources.size} sources for ${timeline.parts.size} parts" }
    }

    override val isAvailable: Boolean get() = sources.any { it?.isAvailable == true }

    override fun frameAt(time: Duration): ScrubFrame? {
        val index = timeline.indexAt(time)
        return sources[index]?.frameAt(time - timeline.parts[index].start)
    }

    override fun dispose() {
        sources.forEach { it?.dispose() }
    }
}
