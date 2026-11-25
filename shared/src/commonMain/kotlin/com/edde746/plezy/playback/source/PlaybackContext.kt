package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.MediaBackend
import com.edde746.plezy.backend.PlaybackInitializationResult
import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaVersion
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.ServerStream

/** Where the player reads the media from. */
enum class PlaybackSourceKind { LOCAL_FILE, REMOTE_DIRECT, REMOTE_TRANSCODE }

/**
 * Where progress and stop reports go: the server ([ONLINE]); the server, queued offline when a report fails, for a
 * downloaded copy played with the server reachable ([ONLINE_WITH_OFFLINE_FALLBACK]); the offline queue only
 * ([OFFLINE_QUEUE]); nowhere ([DISABLED]).
 */
enum class PlaybackReportingMode { ONLINE, OFFLINE_QUEUE, ONLINE_WITH_OFFLINE_FALLBACK, DISABLED }

/**
 * A resolved play request: what to open ([result]), where it comes from, where reports go and the headers the player
 * sends. [reportingClient] is null when no live server backs the playback; [streamHeaders] is null for a local file or
 * without a client.
 */
data class PlaybackContext(
    val item: MediaItem,
    val result: PlaybackInitializationResult,
    val sourceKind: PlaybackSourceKind,
    val reportingMode: PlaybackReportingMode,
    val reportingClient: MediaBackend? = null,
    val streamHeaders: Map<String, String>? = null,
) {
    val usesLocalMedia: Boolean get() = sourceKind == PlaybackSourceKind.LOCAL_FILE

    /** A failed server report goes to the offline queue instead. */
    val shouldQueueOnReportFailure: Boolean get() = reportingMode == PlaybackReportingMode.ONLINE_WITH_OFFLINE_FALLBACK

    /**
     * The server's stream the engine opens ([LoadRequest.server]): the selected version's container and bitrate, and
     * for direct play the source's frame rate and transfer; null for a local file.
     */
    val serverStream: ServerStream?
        get() {
            if (usesLocalMedia) return null
            val transcode = sourceKind == PlaybackSourceKind.REMOTE_TRANSCODE || result.isTranscoding
            val version = result.selectedVersion
            val display = result.mediaInfo?.displayCriteria?.takeIf { !transcode }
            return ServerStream(
                transcode = transcode,
                container = version?.container,
                bitrateKbps = version?.bitrate,
                frameRate = display?.fps?.takeIf { it > 0 },
                colorTransfer = display?.transfer,
                width = display?.width?.takeIf { it > 0 },
                height = display?.height?.takeIf { it > 0 },
            )
        }
}

/**
 * The source loaded in the player with its effective selections: [qualityPreset] is the requested one, or
 * [TranscodeQualityPreset.ORIGINAL] when the server fell back to direct play; [mediaSourceId] is the version actually
 * playing. Built once per resolve, so a failed resolve leaves the previous one in place.
 */
data class PlaybackSource(
    val context: PlaybackContext,
    val qualityPreset: TranscodeQualityPreset,
    val mediaSourceId: String? = null,
) {
    /** The effective version index after the backend clamped or fell back. */
    val mediaIndex: Int get() = context.result.selectedMediaIndex

    companion object {
        /**
         * The effective selections of [context]: a transcode fallback on a capped [requestedQualityPreset] plays at
         * Original; the source id is the result's own, else the id of the clamped version index, else
         * [requestedMediaSourceId].
         */
        fun of(context: PlaybackContext, requestedQualityPreset: TranscodeQualityPreset, requestedMediaSourceId: String? = null): PlaybackSource {
            val result = context.result
            val fellBackToOriginal = result.fallbackReason != null && !requestedQualityPreset.isOriginal
            return PlaybackSource(
                context = context,
                qualityPreset = if (fellBackToOriginal) TranscodeQualityPreset.ORIGINAL else requestedQualityPreset,
                mediaSourceId = result.selectedMediaSourceId
                    ?: mediaSourceIdForIndex(result.availableVersions, result.selectedMediaIndex)
                    ?: requestedMediaSourceId,
            )
        }

        private fun mediaSourceIdForIndex(versions: List<MediaVersion>, index: Int): String? = versions.getOrNull(index)?.id
    }
}
