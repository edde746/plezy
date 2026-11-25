package com.edde746.plezy.playback.tracks

import com.edde746.plezy.backend.SubtitlePreference

/**
 * What the next open or selection pass aims for, subtitle-wise.
 *
 * [Native] is an identity reference (a `source:` row, a sidecar's URI, or a raw player track) valid only within the
 * current item and media source. [Intent] carries semantics alone and is the only form that may cross an item or
 * source boundary ([demoteToIntent]). An intent's language and forced-ness are hard requirements: it only resolves to
 * a track of the same language and the same forced class, otherwise resolution declines and the selection falls back
 * to the server's own per-item choice. Its forced-ness is the effective one (flag or title), captured once here.
 */
sealed interface PreferredSubtitle {
    data object Off : PreferredSubtitle

    data class Native(val track: NativeSubtitleTrack) : PreferredSubtitle

    /** [intent]'s [SubtitlePreference.Track.sourceStreamId] is always null: an intent names no row. */
    data class Intent(val intent: SubtitlePreference.Track) : PreferredSubtitle

    /** What a server's playback negotiation needs: a `source:` reference keeps its row as the picked one. */
    fun toPreference(): SubtitlePreference = when (this) {
        Off -> SubtitlePreference.Off
        is Intent -> intent
        is Native -> (intentOf(track) ?: SubtitlePreference.Track()).copy(sourceStreamId = sourceStreamIdOf(track.id))
    }

    companion object {
        /**
         * The preference as it crosses an item or source boundary: identity references lose their meaning there, so a
         * track becomes its intent, or null when it has no semantics. Off and intents pass through.
         */
        fun demoteToIntent(preference: PreferredSubtitle?): PreferredSubtitle? = when (preference) {
            null, Off, is Intent -> preference
            is Native -> intentOf(preference.track)?.let(::Intent)
        }

        /**
         * The semantic intent of [track]: null when it is null or off, or carries no title, language or codec (an
         * intent that can never resolve is not worth carrying).
         */
        fun intentOf(track: NativeSubtitleTrack?): SubtitlePreference.Track? {
            if (track == null || track.id == NativeSubtitleTrack.OFF.id) return null
            if (track.title.isNullOrEmpty() && track.language.isNullOrEmpty() && track.codec.isNullOrEmpty()) return null
            return SubtitlePreference.Track(
                language = track.language,
                forced = track.effectiveForced,
                title = track.title,
                codec = track.codec,
                isExternal = track.isExternal,
            )
        }
    }
}
