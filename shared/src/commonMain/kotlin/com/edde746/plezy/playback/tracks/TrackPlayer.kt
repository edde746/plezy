package com.edde746.plezy.playback.tracks

import kotlinx.coroutines.flow.StateFlow

/**
 * What track selection needs of the player: its track lists as they change, and the commands that pick from them.
 * The session adapts its engine to it (engine ids as [NativeAudioTrack.id] strings, sidecars with their URIs).
 */
interface TrackPlayer {
    /** The current file's tracks and selections; empty lists until the player listed them. */
    val tracks: StateFlow<NativeTracks>

    /** The playback rate the player runs at. */
    val rate: Double

    /** The player was released: nothing may be sent to it any more. */
    val disposed: Boolean

    /** The player can show a second subtitle (mpv's `secondary-sid`). */
    val supportsSecondarySubtitles: Boolean

    suspend fun selectAudioTrack(track: NativeAudioTrack)

    /** [NativeSubtitleTrack.OFF] turns subtitles off. */
    suspend fun selectSubtitleTrack(track: NativeSubtitleTrack)

    /** [NativeSubtitleTrack.OFF] turns the second subtitle off. */
    suspend fun selectSecondarySubtitleTrack(track: NativeSubtitleTrack)

    suspend fun setRate(rate: Double)
}
