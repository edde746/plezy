package com.edde746.plezy.desktop.linux

import com.edde746.plezy.desktop.DesktopMediaControls
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.player.MediaCommand
import com.edde746.plezy.presentation.player.MediaCommandHandler
import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingStatus
import com.edde746.plezy.settings.AppSettings
import org.freedesktop.dbus.DBusPath
import org.freedesktop.dbus.TypeRef
import org.freedesktop.dbus.annotations.DBusInterfaceName
import org.freedesktop.dbus.annotations.DBusProperty
import org.freedesktop.dbus.annotations.DBusProperty.Access
import org.freedesktop.dbus.connections.impl.DBusConnection
import org.freedesktop.dbus.connections.impl.DBusConnectionBuilder
import org.freedesktop.dbus.errors.NotSupported
import org.freedesktop.dbus.errors.InvalidMethodArgument
import org.freedesktop.dbus.errors.PropertyReadOnly
import org.freedesktop.dbus.errors.UnknownInterface
import org.freedesktop.dbus.errors.UnknownProperty
import org.freedesktop.dbus.exceptions.DBusException
import org.freedesktop.dbus.interfaces.DBusInterface
import org.freedesktop.dbus.interfaces.Properties
import org.freedesktop.dbus.messages.DBusSignal
import org.freedesktop.dbus.types.Variant
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URI
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.swing.SwingUtilities
import kotlin.math.abs
import kotlin.math.roundToLong

/**
 * MPRIS ([MediaControlsHost][com.edde746.plezy.presentation.player.MediaControlsHost] on Linux): while a playback
 * shows, the app is `org.mpris.MediaPlayer2.com.edde746.plezy` on the D-Bus session bus, so the desktop's media
 * controls (KDE's and GNOME's applets, the lock screen, media keys through the desktop, `playerctl`) show what plays and
 * control it. The name is under the app id, as the Flatpak's sandbox lets the app own it (`org.mpris.MediaPlayer2.<app
 * id>` and the names below it) without asking for more.
 *
 * The object `/org/mpris/MediaPlayer2` has the root interface (Identity, Raise; no Quit, no track list) and the Player
 * interface: PlaybackStatus, Metadata (track id, length, title, the episode line or a track's artist as artist, a
 * track's album, the artwork), Position (extrapolated from the last [NowPlaying] at its rate while playing, as the spec
 * asks), Rate, CanGoNext, CanGoPrevious (while the queue has an entry that way), CanPlay and
 * CanPause (while this device may control playback), CanSeek; Rate is writable, as the spec has it: while
 * [NowPlaying.canSetSpeed] a write sets the speed within MinimumRate and MaximumRate (the player's speeds) and 0
 * pauses, and otherwise a write changes nothing; the others are read-only. The methods Play, Pause, PlayPause, Stop,
 * Next, Previous, Seek and SetPosition. Changes go out as PropertiesChanged, and a jump in position (a seek) as Seeked.
 * The name is released when the playback ends ([hide]), so no player lingers on the bus. A second instance on the same
 * bus takes `org.mpris.MediaPlayer2.com.edde746.plezy.instance<pid>`, as the spec suggests.
 *
 * The artwork URL is never published: it carries the server's token. Its bytes are fetched here and shown as a private
 * file ([MprisArtwork]), so the artwork appears once it has loaded.
 *
 * Through dbus-java (MIT) over the bus's Unix socket. Every bus call runs on one thread; commands reach the
 * playback's [MediaCommandHandler] on the AWT event thread (the main thread). [onCommand] sees each command as it
 * arrives (the test report); [raise] brings the window up. Without a session bus, or with one that refuses both
 * names, the controls stay off for the process, logged once.
 */
internal class LinuxMediaControls(
    private val raise: () -> Unit,
    private val onCommand: (MediaCommand) -> Unit = {},
) : DesktopMediaControls {
    private val thread: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "mpris").apply { isDaemon = true } }
    private val fetcher: ExecutorService = Executors.newSingleThreadExecutor { Thread(it, "mpris-artwork").apply { isDaemon = true } }

    // The mpris thread's state.
    private var connection: DBusConnection? = null
    private var busName: String? = null
    private var failed = false
    private var track = 0
    private val artwork = MprisArtwork(MprisArtwork.directory(System.getenv(), DESKTOP_ENTRY))

    /** The artwork URL [artUri] is (or will be, once loaded) the file of; read by the artwork fetch to drop a superseded one. */
    @Volatile private var artworkSource: String? = null

    /** The `file://` URI of the artwork's private file, once loaded; read by the bus's threads. */
    @Volatile private var artUri: String? = null

    /** What the controls show, read by the bus's threads. */
    @Volatile private var shown: Shown? = null

    /** The playback's handler while the controls are up; read on the event thread. */
    @Volatile private var commands: MediaCommandHandler? = null

    private class Shown(val nowPlaying: NowPlaying, val trackId: DBusPath, val atNanos: Long) {
        /** The position now: [NowPlaying.positionSeconds] advanced at its rate while it plays. */
        fun positionMicros(): Long {
            val np = nowPlaying
            val elapsed = if (np.status == NowPlayingStatus.PLAYING) (System.nanoTime() - atNanos) / 1e9 * np.rate else 0.0
            val position = np.positionSeconds + elapsed
            val capped = if (np.durationSeconds > 0) position.coerceAtMost(np.durationSeconds) else position
            return (capped.coerceAtLeast(0.0) * 1e6).roundToLong()
        }
    }

    override fun show(nowPlaying: NowPlaying, commands: MediaCommandHandler) {
        this.commands = commands
        val at = System.nanoTime()
        post {
            val previous = shown
            val sameTrack = previous != null && sameTrack(previous.nowPlaying, nowPlaying)
            val trackId = if (sameTrack) previous.trackId else DBusPath("$TRACK_PATH/${++track}")
            val next = Shown(nowPlaying, trackId, at)
            shown = next
            val bus = connection ?: connect() ?: return@post
            loadArtwork(nowPlaying.artworkUrl)
            if (busName == null) {
                bus.exportObject(OBJECT_PATH, Exported())
                busName = requestName(bus)
                return@post // a new player: clients read everything
            }
            val before = previous?.let { playerProperties(it) }
            val changed = playerProperties(next).filter { (name, value) -> before?.get(name) != value }
            if (changed.isNotEmpty()) bus.sendMessage(Properties.PropertiesChanged(OBJECT_PATH, PLAYER, changed, emptyList()))
            // A seek, or a stall the controls should hear of: they extrapolate the position themselves otherwise.
            if (previous != null && sameTrack && abs(nowPlaying.positionSeconds * 1e6 - previous.positionMicros()) > DRIFT_MICROS) {
                bus.sendMessage(MprisPlayer.Seeked(OBJECT_PATH, next.positionMicros()))
            }
        }
    }

    override fun hide() {
        commands = null
        post {
            shown = null
            loadArtwork(null)
            val bus = connection ?: return@post
            busName?.let { name -> runCatching { bus.releaseBusName(name) } }
            busName = null
            bus.unExportObject(OBJECT_PATH)
        }
    }

    /**
     * Fetches [url]'s bytes (off this thread) into the private artwork file, then publishes the metadata with it; null
     * takes the artwork away. A newer artwork, or the end of the playback, drops a fetch still under way.
     */
    private fun loadArtwork(url: String?) {
        if (url == artworkSource) return
        artworkSource = url
        artUri = null
        artwork.clear()
        if (url == null) return
        fetcher.execute {
            val bytes = try {
                fetchArtwork(url) { artworkSource == url }
            } catch (e: Exception) {
                Log.w(TAG) { "artwork didn't load: ${e.javaClass.simpleName}" }
                null
            }
            if (bytes != null) {
                post {
                    if (artworkSource != url) return@post
                    artUri = artwork.write(bytes)
                    val bus = connection ?: return@post
                    if (busName != null) {
                        bus.sendMessage(Properties.PropertiesChanged(OBJECT_PATH, PLAYER, mapOf("Metadata" to Variant(metadata(shown), "a{sv}")), emptyList()))
                    }
                }
            }
        }
    }

    override fun close() {
        if (thread.isShutdown) return
        thread.execute {
            runCatching { connection?.close() }.onFailure { Log.w(TAG, it) { "MPRIS connection close failed" } }
            connection = null
            artwork.clear()
        }
        thread.shutdown()
        fetcher.shutdownNow()
        thread.awaitTermination(3, TimeUnit.SECONDS)
    }

    /** Runs [block] on the mpris thread unless the bus turned out to be unavailable; failures are logged, not thrown. */
    private fun post(block: () -> Unit) {
        if (thread.isShutdown) return
        thread.execute {
            if (failed) return@execute
            try {
                block()
            } catch (e: Exception) {
                Log.w(TAG, e) { "MPRIS update failed" }
            }
        }
    }

    private fun connect(): DBusConnection? = try {
        DBusConnectionBuilder.forSessionBus().withShared(false).build().also { connection = it }
    } catch (e: DBusException) {
        failed = true
        Log.w(TAG, e) { "no D-Bus session bus: media controls unavailable" }
        null
    }

    /**
     * Owns [BUS_NAME], else (another instance has it) its `.instance<pid>` name. When the bus refuses both, the object
     * goes again and the controls stay off: null, logged once.
     */
    private fun requestName(bus: DBusConnection): String? {
        val instance = "$BUS_NAME.instance${ProcessHandle.current().pid()}"
        return try {
            bus.requestBusName(BUS_NAME)
            BUS_NAME
        } catch (_: DBusException) {
            try {
                bus.requestBusName(instance)
                instance
            } catch (e: DBusException) {
                bus.unExportObject(OBJECT_PATH)
                failed = true
                Log.w(TAG) { "the session bus gave neither $BUS_NAME nor $instance (${e.message}): media controls unavailable" }
                null
            }
        }
    }

    /** Hands a command to the playback on the event thread (the handler current then). */
    private fun deliver(command: MediaCommand) {
        onCommand(command)
        SwingUtilities.invokeLater { commands?.perform(command) }
    }

    private fun rootProperties(): Map<String, Variant<*>> = linkedMapOf(
        "CanQuit" to Variant(false),
        "CanRaise" to Variant(true),
        "HasTrackList" to Variant(false),
        "Identity" to Variant(IDENTITY),
        "DesktopEntry" to Variant(DESKTOP_ENTRY),
        "SupportedUriSchemes" to Variant(emptyList<String>(), "as"),
        "SupportedMimeTypes" to Variant(emptyList<String>(), "as"),
    )

    /** The Player interface's properties for [s]; without a playback, a stopped player. */
    private fun playerProperties(s: Shown?, withPosition: Boolean = false): Map<String, Variant<*>> {
        val np = s?.nowPlaying
        val rate = np?.rate ?: 1.0
        return linkedMapOf(
            "PlaybackStatus" to Variant(
                when {
                    np == null || np.status == NowPlayingStatus.STOPPED -> "Stopped"
                    np.playing -> "Playing"
                    else -> "Paused"
                },
            ),
            "Rate" to Variant(rate),
            "MinimumRate" to Variant(if (np?.canSetSpeed == true) AppSettings.PLAYBACK_SPEED_RANGE.start else minOf(1.0, rate)),
            "MaximumRate" to Variant(if (np?.canSetSpeed == true) AppSettings.PLAYBACK_SPEED_RANGE.endInclusive else maxOf(1.0, rate)),
            "Metadata" to Variant(metadata(s), "a{sv}"),
            "Volume" to Variant(1.0),
            "CanGoNext" to Variant(np?.canSkipNext == true),
            "CanGoPrevious" to Variant(np?.canSkipPrevious == true),
            "CanPlay" to Variant(np?.canPlayPause == true),
            "CanPause" to Variant(np?.canPlayPause == true),
            "CanSeek" to Variant(np?.canSeek == true),
            "CanControl" to Variant(true),
        ).apply { if (withPosition) put("Position", Variant(s?.positionMicros() ?: 0L)) }
    }

    private fun metadata(s: Shown?): Map<String, Variant<*>> = s?.let { mprisMetadata(it.nowPlaying, it.trackId, artUri) } ?: emptyMap()

    /** The exported object: both MPRIS interfaces and their properties. Called on dbus-java's threads. */
    @Suppress("FunctionName")
    private inner class Exported : MprisRoot, MprisPlayer, Properties {
        override fun getObjectPath() = OBJECT_PATH

        override fun Raise() = SwingUtilities.invokeLater(raise)

        override fun Quit() = throw NotSupported("Plezy quits from its own window")

        override fun Next() {
            if (shown?.nowPlaying?.canSkipNext == true) deliver(MediaCommand.Next)
        }

        override fun Previous() {
            if (shown?.nowPlaying?.canSkipPrevious == true) deliver(MediaCommand.Previous)
        }

        override fun Pause() = deliver(MediaCommand.Pause)

        override fun PlayPause() = deliver(MediaCommand.TogglePause)

        override fun Stop() = deliver(MediaCommand.Stop)

        override fun Play() = deliver(MediaCommand.Play)

        override fun Seek(offset: Long) {
            if (shown?.nowPlaying?.canSeek == true) deliver(MediaCommand.SeekBy(offset / 1e6))
        }

        override fun SetPosition(trackId: DBusPath, position: Long) {
            val s = shown ?: return
            // The spec: ignore a stale track id and a position outside the track.
            val lengthMicros = s.nowPlaying.durationSeconds * 1e6
            if (!s.nowPlaying.canSeek || trackId.path != s.trackId.path || position < 0 || position > lengthMicros) return
            deliver(MediaCommand.SeekTo(position / 1e6))
        }

        override fun OpenUri(uri: String) = throw NotSupported("Plezy opens no URIs from MPRIS")

        @Suppress("UNCHECKED_CAST")
        override fun <A : Any?> Get(_interfaceName: String, _propertyName: String): A =
            (GetAll(_interfaceName)[_propertyName] ?: throw UnknownProperty("no property $_propertyName on $_interfaceName")) as A

        override fun GetAll(_interfaceName: String): Map<String, Variant<*>> = when (_interfaceName) {
            ROOT -> rootProperties()
            PLAYER -> playerProperties(shown, withPosition = true)
            else -> throw UnknownInterface("no interface $_interfaceName")
        }

        // Rate is writable (the spec's is): while the speed may change (not music, live or a guest), the video plays at
        // the rate written, within the player's speeds; 0 pauses, as the spec asks. Every other property is read-only,
        // Volume too: the session sets none of them.
        override fun <A : Any?> Set(_interfaceName: String, _propertyName: String, _value: A) {
            if (_interfaceName != PLAYER || _propertyName != "Rate") throw PropertyReadOnly("$_propertyName is read-only")
            val np = shown?.nowPlaying ?: return
            val rate = ((_value as? Variant<*>)?.value ?: _value) as? Number ?: throw InvalidMethodArgument("Rate takes a double")
            if (!np.canSetSpeed) return
            if (rate.toDouble() == 0.0) deliver(MediaCommand.Pause) else deliver(MediaCommand.SetSpeed(rate.toDouble().coerceIn(AppSettings.PLAYBACK_SPEED_RANGE)))
        }
    }

    private companion object {
        const val TAG = "MPRIS"
        const val BUS_NAME = "org.mpris.MediaPlayer2.com.edde746.plezy"
        const val OBJECT_PATH = "/org/mpris/MediaPlayer2"
        const val TRACK_PATH = "/com/edde746/plezy/track"
        const val ROOT = "org.mpris.MediaPlayer2"
        const val PLAYER = "org.mpris.MediaPlayer2.Player"
        const val IDENTITY = "Plezy"

        /** The desktop entry the Flatpak installs (com.edde746.plezy.desktop). */
        const val DESKTOP_ENTRY = "com.edde746.plezy"

        /** A position this far from where the controls extrapolate it is a seek: they hear of it as Seeked. */
        const val DRIFT_MICROS = 1_000_000.0
    }
}

/**
 * The MPRIS metadata of [np] as track [trackId]: never its artwork URL, which carries the server's token, only
 * [artUri], the artwork's private `file://` copy, once there is one.
 */
internal fun mprisMetadata(np: NowPlaying, trackId: DBusPath, artUri: String?): Map<String, Variant<*>> = buildMap {
    put("mpris:trackid", Variant(trackId))
    if (np.durationSeconds > 0) put("mpris:length", Variant((np.durationSeconds * 1e6).roundToLong()))
    put("xesam:title", Variant(np.title))
    np.subtitle?.let { put("xesam:artist", Variant(listOf(it), "as")) }
    np.album?.let { put("xesam:album", Variant(it)) }
    artUri?.let { put("mpris:artUrl", Variant(it)) }
}

/** Whether [b] is still [a]'s track: the same item (its global key), or for a playback without one the same labels. */
internal fun sameTrack(a: NowPlaying, b: NowPlaying): Boolean =
    if (a.item != null || b.item != null) a.item?.globalKey == b.item?.globalKey else a.title == b.title && a.subtitle == b.subtitle

/**
 * [url]'s body, or null for an answer other than 2xx, an empty one, one over [maxBytes], or one not read within about
 * [deadlineMillis]; null too, unread, once [wanted] turns false (a newer artwork took its place).
 */
internal fun fetchArtwork(
    url: String,
    maxBytes: Int = ARTWORK_MAX_BYTES,
    deadlineMillis: Int = ARTWORK_DEADLINE_MILLIS,
    wanted: () -> Boolean,
): ByteArray? {
    if (!wanted()) return null
    val start = System.nanoTime()
    val http = URI(url).toURL().openConnection() as HttpURLConnection
    http.connectTimeout = deadlineMillis
    http.readTimeout = deadlineMillis
    try {
        if (http.responseCode !in 200..299) {
            Log.w("MPRIS") { "artwork didn't load: HTTP ${http.responseCode}" }
            return null
        }
        val body = ByteArrayOutputStream()
        http.inputStream.use { input ->
            val buffer = ByteArray(1 shl 16)
            while (true) {
                if (!wanted()) return null
                if ((System.nanoTime() - start) / 1_000_000 > deadlineMillis) {
                    Log.w("MPRIS") { "artwork didn't load within $deadlineMillis ms" }
                    return null
                }
                val read = input.read(buffer)
                if (read == -1) break
                if (body.size() + read > maxBytes) {
                    Log.w("MPRIS") { "artwork over $maxBytes bytes: dropped" }
                    return null
                }
                body.write(buffer, 0, read)
            }
        }
        return body.toByteArray().takeIf { it.isNotEmpty() }
    } finally {
        http.disconnect()
    }
}

private const val ARTWORK_MAX_BYTES = 8 shl 20
private const val ARTWORK_DEADLINE_MILLIS = 20_000

/** The types of the MPRIS properties that aren't plain values, for the interfaces' introspection data. */
internal interface StringList : TypeRef<List<String>>
internal interface MetadataMap : TypeRef<Map<String, Variant<*>>>

@Suppress("FunctionName")
@DBusInterfaceName("org.mpris.MediaPlayer2")
@DBusProperty(name = "CanQuit", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanRaise", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "HasTrackList", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "Identity", type = String::class, access = Access.READ)
@DBusProperty(name = "DesktopEntry", type = String::class, access = Access.READ)
@DBusProperty(name = "SupportedUriSchemes", type = StringList::class, access = Access.READ)
@DBusProperty(name = "SupportedMimeTypes", type = StringList::class, access = Access.READ)
internal interface MprisRoot : DBusInterface {
    fun Raise()
    fun Quit()
}

@Suppress("FunctionName")
@DBusInterfaceName("org.mpris.MediaPlayer2.Player")
@DBusProperty(name = "PlaybackStatus", type = String::class, access = Access.READ)
@DBusProperty(name = "Rate", type = Double::class, access = Access.READ_WRITE)
@DBusProperty(name = "Metadata", type = MetadataMap::class, access = Access.READ)
@DBusProperty(name = "Volume", type = Double::class, access = Access.READ)
@DBusProperty(name = "Position", type = Long::class, access = Access.READ)
@DBusProperty(name = "MinimumRate", type = Double::class, access = Access.READ)
@DBusProperty(name = "MaximumRate", type = Double::class, access = Access.READ)
@DBusProperty(name = "CanGoNext", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanGoPrevious", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanPlay", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanPause", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanSeek", type = Boolean::class, access = Access.READ)
@DBusProperty(name = "CanControl", type = Boolean::class, access = Access.READ)
internal interface MprisPlayer : DBusInterface {
    fun Next()
    fun Previous()
    fun Pause()
    fun PlayPause()
    fun Stop()
    fun Play()
    fun Seek(offset: Long)
    fun SetPosition(trackId: DBusPath, position: Long)
    fun OpenUri(uri: String)

    /** The position jumped (µs from the start). */
    class Seeked(path: String, val position: Long) : DBusSignal(path, position)
}
