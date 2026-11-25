package com.edde746.plezy.music.engine

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

/**
 * The audio player's gapless arm (`setNext`) over a scripted mpv: where each entry's HTTP headers go, when mpv may open
 * the armed entry ahead of the boundary, how an arm is cleared before and after mpv advanced into it, and Android's
 * `content://` descriptors, which the player closes only when the entry provably never opened.
 */
class MpvAudioPlayerTest {
    private val t1 = "https://example.test/t1.flac"
    private val t2 = "https://example.test/t2.flac"
    private val t3 = "https://example.test/t3.flac"

    private class Run(val core: FakeMpvAudioCore, val fds: FakeContentFds, val player: MpvAudioPlayer, val events: MutableList<AudioEvent>, val scope: TestScope) {
        val transitions get() = events.filterIsInstance<AudioEvent.TrackTransition>().map { it.uri }

        /** Opens a first track and lets its own file-loaded through, so a later one reads as a gapless advance. */
        suspend fun openFirst(media: AudioMedia = AudioMedia("https://example.test/t1.flac")) {
            player.open(media)
            fileLoaded()
        }

        fun fileLoaded() {
            core.listener.onFileLoaded()
            scope.runCurrent()
        }

        /** mpv rolls from the playing entry into the armed one. */
        fun advance() {
            core.mpv.advance()
            core.listener.onProperty("playlist-pos", "1")
            fileLoaded()
        }

        fun property(name: String, value: String?) {
            core.listener.onProperty(name, value)
            scope.runCurrent()
        }
    }

    private fun run(core: FakeMpvAudioCore = FakeMpvAudioCore(), body: suspend Run.() -> Unit) = runTest {
        val fds = FakeContentFds()
        val player = MpvAudioPlayer(core, emptyMap(), emptyList(), fds, StandardTestDispatcher(testScheduler))
        val events = mutableListOf<AudioEvent>()
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { player.events.collect { events += it } }
        val run = Run(core, fds, player, events, this)
        try {
            run.body()
        } finally {
            player.dispose()
        }
    }

    // -- content:// arms ----------------------------------------------------------------------------------------------

    @Test
    fun aContentArmOpensAsADescriptorAndItsTransitionNamesTheOriginalUri() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        assertEquals(listOf("content://downloads/t2"), fds.opened)
        assertEquals(listOf("loadfile", "fdclose://7", "append"), core.commands("loadfile").last().take(3))

        advance()

        // The session matches transitions against the URL it resolved, never the fdclose:// form.
        assertEquals(listOf("content://downloads/t2"), transitions)
        assertEquals(listOf("playlist-remove", "0"), core.commands("playlist-remove").last())
        assertEquals(emptyList(), fds.closed, "mpv consumed the descriptor")
    }

    @Test
    fun aSpentEntryThatWontGoStillLeavesTheTransition() = run(FakeMpvAudioCore().apply { failRemove0 = true }) {
        openFirst()
        player.setNext(AudioMedia(t2))
        advance()

        assertEquals(listOf(t2), transitions)
        assertEquals(listOf("playlist-remove", "0"), core.commands("playlist-remove").last())
    }

    @Test
    fun anOpenOfAContentUriOpensItAsADescriptor() = run {
        player.open(AudioMedia("content://downloads/t1"))

        assertEquals(listOf("loadfile", "fdclose://7", "replace"), core.commands("loadfile").single().take(3))
        assertEquals(emptyList(), fds.closed)
    }

    @Test
    fun aNetworkArmOpensNoDescriptorAndARearmRemovesTheFirstArm() = run {
        openFirst()
        player.setNext(AudioMedia(t2))
        player.setNext(AudioMedia(t3))

        assertEquals(emptyList(), fds.opened)
        assertEquals(listOf(listOf("playlist-remove", "1")), core.commands("playlist-remove"))
        assertEquals(listOf("loadfile", t3, "append"), core.commands("loadfile").last().take(3))
    }

    @Test
    fun aContentArmThatDoesntOpenThrowsInsteadOfArmingTheRawUri() = run {
        openFirst()
        fds.fail = true

        assertFailsWith<IllegalStateException> { player.setNext(AudioMedia("content://downloads/t2")) }
        assertEquals(1, core.commands("loadfile").size, "only the open's load")
    }

    @Test
    fun anArmMpvRefusesLeavesNothingArmedAndClosesItsDescriptor() = run {
        openFirst()
        core.failAppend = true

        assertFailsWith<IllegalStateException> { player.setNext(AudioMedia("content://downloads/t2")) }
        assertEquals(listOf(7), fds.closed)

        core.failAppend = false
        player.setNext(null)
        assertEquals(emptyList(), core.commands("playlist-remove"), "nothing was armed to clear")
    }

    // -- prefetch-playlist --------------------------------------------------------------------------------------------

    @Test
    fun aNetworkArmTurnsPrefetchOnBeforeItJoinsThePlaylist() = run {
        openFirst()
        player.setNext(AudioMedia(t2))

        val (index, value) = core.lastPrefetchWrite()
        assertEquals("yes", value)
        assertTrue(index < core.lastAppendIndex(), "the option is live before the append")
    }

    @Test
    fun aDescriptorArmTurnsPrefetchOffBeforeItJoinsThePlaylist() = run {
        openFirst()
        player.setNext(AudioMedia(t2))
        player.setNext(AudioMedia("content://downloads/t3"))

        val (index, value) = core.lastPrefetchWrite()
        assertEquals("no", value, "a prefetch would consume the descriptor and invite a double close")
        assertTrue(index < core.lastAppendIndex())
        assertEquals(listOf("loadfile", "fdclose://7", "append"), core.commands("loadfile").last().take(3))
    }

    @Test
    fun aLocalFileArmTurnsPrefetchOff() = run {
        openFirst()
        player.setNext(AudioMedia("/storage/music/t2.flac"))

        assertEquals("no", core.lastPrefetchWrite().second)
    }

    // -- headers across gapless arms ----------------------------------------------------------------------------------

    private val plexHeaders = linkedMapOf(
        "X-Plex-Product" to "Plezy",
        "X-Plex-Device" to "Mac17,9",
        "X-Plex-Device-Name" to "Eddé's Mac, work\\",
        "X-Plex-Token" to "secret",
    )
    private val plexItems = plexHeaders.map { (k, v) -> "$k: $v" }
    private val plex1 = "https://media.example.test/plex/library/parts/1/file.flac"
    private val plex2 = "https://media.example.test/plex/library/parts/2/file.flac"
    private val plex3 = "https://media.example.test/plex/library/parts/3/file.flac"

    // Another server behind the same origin (a path-routed reverse proxy).
    private val jellyfin1 = "https://media.example.test/jellyfin/Audio/1/stream?ApiKey=k"
    private val jellyfin2 = "https://media.example.test/jellyfin/Audio/2/stream?ApiKey=k"

    @Test
    fun everyArmedTrackOfOneServerIsPrefetchedWithAllItsHeaders() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        player.setNext(AudioMedia(plex2, plexHeaders))
        advance()
        player.setNext(AudioMedia(plex3, plexHeaders))
        advance()

        assertEquals(mapOf(plex1 to plexItems, plex2 to plexItems, plex3 to plexItems), core.mpv.openedHeaders)
        assertEquals(setOf(plex2, plex3), core.mpv.prefetched, "arms of the same server keep the prefetch")
        assertEquals(listOf(plex2, plex3), transitions)
    }

    @Test
    fun anArmWithOtherHeadersNeverGetsThePlayingTracks() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        player.setNext(AudioMedia(jellyfin1))
        advance()
        player.setNext(AudioMedia(plex2, plexHeaders))
        advance()

        assertEquals(mapOf(plex1 to plexItems, jellyfin1 to emptyList(), plex2 to plexItems), core.mpv.openedHeaders)
        assertEquals(emptySet(), core.mpv.prefetched, "a prefetch sends the playing entry's headers")
    }

    @Test
    fun anOpenAfterAnAdvanceSendsOnlyItsOwnHeaders() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        player.setNext(AudioMedia(plex2, plexHeaders))
        advance()
        player.open(AudioMedia(jellyfin1))

        assertEquals(emptyList(), core.mpv.openedHeaders[jellyfin1])
    }

    @Test
    fun thePrefetchFollowsThePlayingTracksHeadersAcrossAnAdvance() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        player.setNext(AudioMedia(jellyfin1))
        assertEquals("no", core.lastPrefetchWrite().second)

        advance()
        player.setNext(AudioMedia(jellyfin2))
        assertEquals("yes", core.lastPrefetchWrite().second, "the Jellyfin track plays now")
        player.setNext(AudioMedia(plex2, plexHeaders))
        assertEquals("no", core.lastPrefetchWrite().second)

        openFirst(AudioMedia(plex3, plexHeaders))
        player.setNext(AudioMedia(plex2, plexHeaders))
        assertEquals("yes", core.lastPrefetchWrite().second)
    }

    @Test
    fun anArmIsAppendedAtTheEndOfThePlaylistWithItsOwnHeaderFields() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        player.setNext(AudioMedia(plex2, plexHeaders))
        player.setNext(AudioMedia(jellyfin1))

        val (plexArm, jellyfinArm) = core.commands("loadfile").filter { it[2] == "append" }
        assertEquals(listOf("loadfile", plex2, "append", "-1"), plexArm.take(4))
        assertTrue(plexArm[4].startsWith("http-header-fields="), plexArm[4])
        assertEquals(listOf("loadfile", jellyfin1, "append", "-1"), jellyfinArm.take(4))
        assertEquals("http-header-fields-clr=", jellyfinArm[4], "an arm without headers clears the playing entry's")
    }

    @Test
    fun anOpenMpvRefusesKeepsThePlayingEntrysHeadersForTheNextArm() = run {
        openFirst(AudioMedia(plex1, plexHeaders))
        core.failReplace = true
        assertFailsWith<IllegalStateException> { player.open(AudioMedia(jellyfin1)) }
        core.failReplace = false

        player.setNext(AudioMedia(plex2, plexHeaders))
        assertEquals("yes", core.lastPrefetchWrite().second, "plex1 still plays")
    }

    // -- armed descriptor ownership ------------------------------------------------------------------------------------

    @Test
    fun clearingAnUnconsumedArmClosesItsDescriptor() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "0")
        player.setNext(null)

        assertEquals(listOf(listOf("playlist-remove", "1")), core.commands("playlist-remove"))
        assertEquals(listOf(7), fds.closed)
        assertEquals(emptyList(), transitions)
    }

    @Test
    fun clearingAnArmMpvAlreadyPlaysAdoptsTheTransitionAndKeepsTheDescriptor() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += "1"
        player.setNext(null)

        assertEquals(listOf("content://downloads/t2"), transitions)
        assertEquals(listOf(listOf("playlist-remove", "0")), core.commands("playlist-remove"), "removing 1 would end the playing entry")
        assertEquals(emptyList(), fds.closed, "mpv opened the entry and owns the descriptor")

        // mpv's own file-loaded comes late: nothing is armed, so it is no second advance.
        fileLoaded()
        assertEquals(1, transitions.size)
    }

    @Test
    fun anUnclearPositionAfterTheRemoveLeaksTheDescriptor() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "-1")
        player.setNext(null)

        assertEquals(listOf(listOf("playlist-remove", "1")), core.commands("playlist-remove"))
        assertEquals(emptyList(), fds.closed)
    }

    @Test
    fun aRemoveMpvRefusesLeaksTheDescriptor() = run(FakeMpvAudioCore().apply { failRemove1 = true }) {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += "0"
        player.setNext(null)

        assertEquals(emptyList(), fds.closed)
        assertEquals(emptyList(), transitions)
    }

    @Test
    fun stopSettlesAnUnconsumedArmWithoutATransition() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "0")
        player.stop()

        assertEquals(listOf(7), fds.closed)
        assertEquals(emptyList(), transitions)
    }

    @Test
    fun stopAfterMpvRolledIntoTheArmReportsNoTransitionAndKeepsTheDescriptor() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += "1"
        player.stop()

        assertEquals(emptyList(), transitions, "playback is ending: nobody listens for that entry")
        assertEquals(emptyList(), fds.closed)
    }

    @Test
    fun anOpenDropsAnUnconsumedArm() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "0")
        player.open(AudioMedia(t3))

        assertEquals(listOf(7), fds.closed)
        assertEquals(emptyList(), transitions)
        assertEquals(listOf("loadfile", t3, "replace"), core.commands("loadfile").last().take(3))

        // The open's own file-loaded is no advance into the dropped arm.
        fileLoaded()
        assertEquals(emptyList(), transitions)
    }

    @Test
    fun disposeSettlesAnUnconsumedArm() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "0")
        player.dispose()

        assertEquals(listOf(7), fds.closed)
        assertEquals(listOf(listOf("playlist-remove", "1")), core.commands("playlist-remove"))
        assertTrue(core.destroyed)
        assertFailsWith<IllegalStateException> { player.play() }
    }

    @Test
    fun replacingAnUnconsumedContentArmClosesOnlyTheOldDescriptor() = run {
        openFirst()
        player.setNext(AudioMedia("content://downloads/t2"))

        core.playlistPos += listOf("0", "0")
        player.setNext(AudioMedia("content://downloads/t3"))

        assertEquals(listOf("content://downloads/t2", "content://downloads/t3"), fds.opened)
        assertEquals(listOf(7), fds.closed)
        assertEquals(listOf("loadfile", "fdclose://8", "append"), core.commands("loadfile").last().take(3))

        advance()
        assertEquals(listOf("content://downloads/t3"), transitions)
        assertEquals(listOf(7), fds.closed, "the consumed descriptor stays mpv's")
    }

    // -- the playhead across an advance --------------------------------------------------------------------------------

    @Test
    fun anAdvanceKeepsTheOutgoingTracksLastPositionAndStartsTheNewOneAtZero() = run {
        openFirst()
        player.setNext(AudioMedia(t2))
        property("time-pos", "29.5")
        // The boundary on the property flow, then the new entry's first report ahead of mpv's file-loaded.
        property("playlist-pos", "1")
        property("time-pos", "0.02")
        fileLoaded()

        assertEquals(29.5.seconds, player.outgoingSourcePosition)
        assertEquals(Duration.ZERO, player.state.position)
        val transition = events.indexOf(AudioEvent.TrackTransition(t2))
        assertEquals(AudioEvent.PlayheadJump(Duration.ZERO), events[transition - 1])
    }

    @Test
    fun aClearedArmsFrozenPositionIsntTheNextAdvancesOutgoingPosition() = run {
        openFirst()
        player.setNext(AudioMedia(t2))
        property("time-pos", "10")
        property("playlist-pos", "0")
        player.setNext(null)
        player.setNext(AudioMedia(t3))
        property("time-pos", "29")
        fileLoaded()

        assertEquals(29.seconds, player.outgoingSourcePosition)
    }

    @Test
    fun aSeekRefusedAfterAnAdvanceDoesntPutTheOldSourcesPositionBack() = run {
        openFirst()
        player.setNext(AudioMedia(t2))
        property("time-pos", "20")
        core.holdSeeks = true
        val seek = scope.launch { runCatching { player.seek(25.seconds) } }
        scope.runCurrent()
        assertEquals(25.seconds, player.state.position)

        advance()
        core.answerHeld("refused")
        seek.join()

        assertEquals(Duration.ZERO, player.state.position, "the refusal speaks for the old source only")
    }

    @Test
    fun aSeekMpvRefusesPutsThePlayheadBack() = run {
        openFirst()
        property("time-pos", "20")
        core.failSeek = true

        assertFailsWith<IllegalStateException> { player.seek(25.seconds) }
        assertEquals(20.seconds, player.state.position)
        assertEquals(AudioEvent.PlayheadJump(20.seconds), events.last())
    }

    @Test
    fun anOpenStartsTheEntryAtItsStartAsAFileOption() = run {
        player.open(AudioMedia(t1, start = 12.5.seconds), play = false)

        assertEquals("http-header-fields-clr=,start=12.5", core.commands("loadfile").single()[4])
        assertEquals(12.5.seconds, player.state.position)
        assertEquals(listOf("pause" to "yes"), core.properties.filter { it.first == "pause" })
    }

    @Test
    fun anAudioCoreThatDoesntStartFailsTheFirstCommand() = run(FakeMpvAudioCore().apply { startFailure = "mpv_initialize: error" }) {
        assertFailsWith<AudioPlayerInitializationException> { player.open(AudioMedia(t1)) }
        assertFailsWith<AudioPlayerInitializationException> { player.play() }
        assertEquals(1, core.starts)
    }

    @Test
    fun theAudioCoreStartsAudioOnlyWithGaplessAudio() = run {
        player.play()

        val options = core.startOptions
        assertEquals("weak", options["gapless-audio"])
        assertEquals("no", options["vid"])
        assertEquals("no", options["audio-display"])
        assertEquals("no", options["force-window"])
        assertEquals("yes", options["keep-open"])
        assertTrue("playlist-pos" in core.observed)
    }

    @Test
    fun positionReportsArriveInOrderAndAtMostFourTimesASecond() = run {
        openFirst()
        events.clear()
        property("time-pos", "1.0")
        property("time-pos", "1.1")
        assertEquals(listOf<AudioEvent>(AudioEvent.Position(1.seconds)), events)
        assertEquals(1100.milliseconds, player.state.position)
    }

    /** mpv sends an observed `duration` only when it changed: a next file of the same length gets none. */
    @Test
    fun anOpenOfATrackAsLongAsTheLastKeepsItsLength() = run {
        core.duration = "30.000000"
        openFirst()
        property("duration", "30.000000")
        assertEquals(30.seconds, player.state.duration)

        player.open(AudioMedia(t2))
        events.clear()
        fileLoaded()

        assertEquals(30.seconds, player.state.duration)
        assertEquals(listOf<AudioEvent>(AudioEvent.DurationChanged(30.seconds)), events.filterIsInstance<AudioEvent.DurationChanged>())
    }

    @Test
    fun aGaplessAdvanceIntoATrackAsLongAsTheLastKeepsItsLength() = run {
        core.duration = "30.000000"
        openFirst()
        property("duration", "30.000000")
        player.setNext(AudioMedia(t2))
        events.clear()
        advance()

        assertEquals(30.seconds, player.state.duration)
        assertEquals(listOf<AudioEvent>(AudioEvent.DurationChanged(30.seconds)), events.filterIsInstance<AudioEvent.DurationChanged>())
    }
}

/** Android's descriptors, scripted: each open hands out the next number from 7. */
private class FakeContentFds : ContentFds {
    val opened = mutableListOf<String>()
    val closed = mutableListOf<Int>()
    var fail = false
    private var next = 7

    override fun open(uri: String): Int {
        if (fail) throw IllegalStateException("no such document")
        opened += uri
        return next++
    }

    override fun close(fd: Int) {
        closed += fd
    }
}

/**
 * A scripted mpv audio core: it records every request, answers `playlist-pos` reads from [playlistPos] ("0" once
 * empty), refuses what the test says, and replays the requests through [mpv] for the headers each entry opens with.
 */
private class FakeMpvAudioCore : MpvAudioCore {
    lateinit var listener: MpvAudioCoreListener
    val calls = mutableListOf<List<String>>()
    val properties = mutableListOf<Pair<String, String>>()
    val playlistPos = mutableListOf<String>()
    val mpv = MpvHeaderModel()
    var startFailure: String? = null
    var starts = 0
    var startOptions: Map<String, String> = emptyMap()
    var observed: List<String> = emptyList()
    var destroyed = false
    var failRemove0 = false
    var failRemove1 = false
    var failAppend = false
    var failReplace = false
    var failSeek = false
    var holdSeeks = false

    /** The current entry's `duration` as mpv answers a read of it; null while it has none. */
    var duration: String? = null
    private val held = mutableListOf<(String?) -> Unit>()

    override fun start(options: Map<String, String>, observed: List<String>, listener: MpvAudioCoreListener): String? {
        starts++
        startOptions = options
        this.observed = observed
        this.listener = listener
        return startFailure
    }

    override fun command(args: List<String>, done: (String?) -> Unit) {
        calls += args
        val refused = when {
            args == listOf("playlist-remove", "0") && failRemove0 -> "error"
            args == listOf("playlist-remove", "1") && failRemove1 -> "error"
            args.first() == "loadfile" && args[2] == "append" && failAppend -> "error"
            args.first() == "loadfile" && args[2] == "replace" && failReplace -> "error"
            args.first() == "seek" && failSeek -> "error"
            else -> null
        }
        if (args.first() == "seek" && holdSeeks) {
            held += done
            return
        }
        if (refused == null) mpv.command(args)
        done(refused)
    }

    fun answerHeld(error: String?) {
        held.forEach { it(error) }
        held.clear()
    }

    override fun setProperty(name: String, value: String, done: (String?) -> Unit) {
        calls += listOf("set", name, value)
        properties += name to value
        if (name == "prefetch-playlist") mpv.prefetch = value == "yes"
        done(null)
    }

    override fun getProperty(name: String, done: (String?, String?) -> Unit) {
        when (name) {
            "playlist-pos" -> done(if (playlistPos.isEmpty()) "0" else playlistPos.removeAt(0), null)
            "duration" -> done(duration, null)
            else -> error("unread property $name")
        }
    }

    override fun setLogLevel(level: String) = Unit

    override fun destroy() {
        destroyed = true
    }

    fun commands(first: String) = calls.filter { it.first() == first }

    fun lastPrefetchWrite(): Pair<Int, String?> {
        val index = calls.indexOfLast { it.size == 3 && it[0] == "set" && it[1] == "prefetch-playlist" }
        return index to calls.getOrNull(index)?.get(2)
    }

    fun lastAppendIndex() = calls.indexOfLast { it.first() == "loadfile" && it[2] == "append" }
}

/**
 * The HTTP headers mpv (0.41) opens each playlist entry's stream with, replayed from the requests:
 * - a `loadfile` options argument is a key/value list: a value is `%N%` and N UTF-8 bytes, or runs to the next `,`; a
 *   repeated key drops its earlier pair;
 * - as an entry starts, the header list is backed up and the entry's pairs apply in order; as it ends, the backup comes
 *   back. `-clr` empties the list, the bare key replaces it with its value split at `,` (a backslash right before one
 *   escapes it and is dropped);
 * - with `prefetch-playlist` on, the armed entry's stream opens while the current entry plays, with the current list;
 *   else as the entry starts, with its own pairs applied.
 * Recorded headers drop trailing whitespace, which HTTP strips.
 */
private class MpvHeaderModel {
    private var list: List<String> = emptyList()
    private var backup: List<String>? = null
    private var armed: Pair<String, String>? = null
    var prefetch = false
    val openedHeaders = linkedMapOf<String, List<String>>()
    val prefetched = linkedSetOf<String>()

    fun command(args: List<String>) {
        when {
            args.first() == "loadfile" && args[2] == "replace" -> {
                armed = null
                endCurrent()
                start(args[1], args.getOrElse(4) { "" })
            }
            args.first() == "loadfile" && args[2] == "append" -> armed = args[1] to args.getOrElse(4) { "" }
            args == listOf("playlist-remove", "1") -> armed = null
        }
    }

    fun advance() {
        val (uri, options) = checkNotNull(armed) { "nothing armed" }
        armed = null
        if (prefetch) {
            openedHeaders[uri] = sent(list)
            prefetched += uri
        }
        endCurrent()
        start(uri, options)
    }

    private fun endCurrent() {
        list = backup ?: list
        backup = null
    }

    private fun start(uri: String, options: String) {
        backup = list
        for ((key, value) in keyValuePairs(options)) {
            list = when (key) {
                "http-header-fields-clr" -> emptyList()
                "http-header-fields" -> splitList(value)
                else -> continue
            }
        }
        openedHeaders.getOrPut(uri) { sent(list) }
    }

    private fun sent(list: List<String>) = list.map { it.trimEnd() }

    private fun keyValuePairs(options: String): List<Pair<String, String>> {
        val bytes = options.encodeToByteArray()
        var i = 0
        fun read(terminator: Byte): String {
            if (i < bytes.size && bytes[i] == '%'.code.toByte()) {
                val lengthEnd = (i + 1 until bytes.size).first { bytes[it] == '%'.code.toByte() }
                val end = lengthEnd + 1 + bytes.decodeToString(i + 1, lengthEnd).toInt()
                val value = bytes.decodeToString(lengthEnd + 1, end)
                i = end
                return value
            }
            val start = i
            while (i < bytes.size && bytes[i] != terminator) i++
            return bytes.decodeToString(start, i)
        }
        val pairs = mutableListOf<Pair<String, String>>()
        while (i < bytes.size) {
            val key = read('='.code.toByte())
            check(i < bytes.size && bytes[i++] == '='.code.toByte()) { "expected = after $key in $options" }
            val value = read(','.code.toByte())
            pairs.removeAll { it.first == key }
            pairs += key to value
            check(i >= bytes.size || bytes[i] == ','.code.toByte()) { "garbage in $options" }
            i++
        }
        return pairs
    }

    private fun splitList(value: String): List<String> {
        val items = mutableListOf<String>()
        var item = StringBuilder()
        for (char in value) {
            when {
                char == ',' && item.endsWith("\\") -> item[item.length - 1] = ','
                char == ',' -> {
                    items += item.toString()
                    item = StringBuilder()
                }
                else -> item.append(char)
            }
        }
        return items + item.toString()
    }
}
