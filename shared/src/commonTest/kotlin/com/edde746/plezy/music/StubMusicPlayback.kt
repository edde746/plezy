package com.edde746.plezy.music

import com.edde746.plezy.model.Lyrics
import com.edde746.plezy.model.MediaItem
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlin.time.Duration

/** A [MusicPlayback] that records what it was asked to play; everything else does nothing. */
open class StubMusicPlayback : MusicPlayback {
    override val state = MutableStateFlow(MusicState())
    override val position: StateFlow<Duration> = MutableStateFlow(Duration.ZERO)
    override val playheadJumps: Flow<Duration?> = emptyFlow()
    override val errors: Flow<Throwable> = emptyFlow()
    override val volumePreview: StateFlow<Double> = MutableStateFlow(100.0)

    private var intent = 0
    override fun beginPlayIntent(): Int = ++intent
    override fun isPlayIntentCurrent(intent: Int): Boolean = intent == this.intent
    override val queueSessionRevision: Int get() = 0

    /** Each [playFromList]: the track ids, the start track's id and the context. */
    val played = mutableListOf<Triple<List<String>, String?, MusicPlayContext>>()

    override suspend fun playFromList(
        tracks: List<MediaItem>,
        startTrack: MediaItem?,
        playContext: MusicPlayContext,
        shuffle: Boolean,
        initialPosition: Duration?,
        offline: Boolean,
    ) {
        beginPlayIntent()
        if (tracks.isEmpty()) return
        played += Triple(tracks.map { it.id }, startTrack?.id, playContext)
        state.value = MusicState(status = MusicPlaybackStatus.PLAYING, currentTrack = startTrack ?: tracks.first(), queue = tracks)
    }

    override suspend fun playInstantMix(seed: MediaItem): InstantMixOutcome = InstantMixOutcome.STARTED
    override suspend fun play() {}
    override suspend fun pause() {}
    override suspend fun togglePlayPause() {}
    override suspend fun next() {}
    override suspend fun previous() {}
    override suspend fun seek(position: Duration) {}
    override suspend fun setVolume(volume: Double, persist: Boolean) {}
    override fun setRepeatMode(mode: MusicRepeatMode) {}
    override fun toggleShuffle() {}
    override suspend fun jumpTo(index: Int) {}
    override fun removeAt(index: Int) {}
    override fun reorder(from: Int, to: Int) {}
    override fun addNext(tracks: List<MediaItem>) {}
    override fun addToEnd(tracks: List<MediaItem>) {}
    override fun clearUpcoming() {}
    override suspend fun stop() {}
    override fun setSleepTimer(duration: Duration?, endOfTrack: Boolean) {}
    override suspend fun fetchLyrics(track: MediaItem): Lyrics? = null
}
