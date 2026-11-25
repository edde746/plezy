package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.TranscodeQualityPreset
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * The quality a player screen asks for and whether the user picked it. Only a picked quality outranks a downloaded
 * copy: the saved default carries no intent a local copy would violate, so the download still plays under it.
 */
data class QualityChoice(val preset: TranscodeQualityPreset, val explicit: Boolean) {
    /** A downloaded copy may replace [preset]. */
    val downloadOutranksQuality: Boolean get() = !explicit

    /** [picked] chosen in the player: explicit for the rest of the screen, its reloads and later episodes. */
    fun picked(picked: TranscodeQualityPreset): QualityChoice = QualityChoice(picked, explicit = true)

    companion object {
        /**
         * The quality a playback starts at: [requested] (a per-play pick) when given, explicit; else Original for the
         * offline library; else the saved default ([TranscodeQualityPreset.resolveStartupDefault]), where live TV
         * counts as able to transcode.
         */
        fun atStartup(
            requested: TranscodeQualityPreset?,
            offlineLibraryMode: Boolean,
            live: Boolean,
            serverSupportsTranscoding: Boolean,
            onCellularOnly: Boolean,
            cellularDefault: TranscodeQualityPreset?,
            generalDefault: TranscodeQualityPreset,
        ): QualityChoice {
            if (requested != null) return QualityChoice(requested, explicit = true)
            if (offlineLibraryMode) return QualityChoice(TranscodeQualityPreset.ORIGINAL, explicit = false)
            val preset = TranscodeQualityPreset.resolveStartupDefault(
                serverSupportsTranscoding = live || serverSupportsTranscoding,
                onCellularOnly = onCellularOnly,
                cellularDefault = cellularDefault,
                generalDefault = generalDefault,
            )
            return QualityChoice(preset, explicit = false)
        }
    }
}

/**
 * Where an opening item starts: an explicit [requested] position (a resume pick, a version switch, a recovery, Watch
 * Together) first; then zero for a shuffle that starts episodes from the beginning; then the offline progress
 * [offlineOffsetMs] when above zero; then the server's [viewOffsetMs]; else null (the player's own start). The resolver
 * gets the same value, so an item stacked over several files opens the file holding it.
 */
fun resolveOpenResumePosition(
    requested: Duration? = null,
    shuffleFromBeginning: Boolean = false,
    offlineOffsetMs: Long? = null,
    viewOffsetMs: Long? = null,
): Duration? = when {
    requested != null -> requested
    shuffleFromBeginning -> Duration.ZERO
    offlineOffsetMs != null && offlineOffsetMs > 0 -> offlineOffsetMs.milliseconds
    else -> viewOffsetMs?.milliseconds
}
