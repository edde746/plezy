package com.edde746.plezy.desktop.linux

import com.edde746.plezy.presentation.player.NowPlaying
import com.edde746.plezy.presentation.player.NowPlayingKind
import com.edde746.plezy.presentation.player.NowPlayingStatus
import org.freedesktop.dbus.DBusPath
import java.net.URI
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.attribute.PosixFilePermissions
import kotlin.io.path.createTempDirectory
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.readBytes
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** MPRIS never carries the artwork's URL (its token): only a private file of its bytes. */
class MprisArtworkTest {
    private val root: Path = createTempDirectory("mpris")
    private val directory: Path = root.resolve("com.edde746.plezy_artwork")
    private var now = 1_000L
    private val artwork = MprisArtwork(directory) { now }

    // The artwork file is MPRIS's, on Linux: its owner-only permissions are POSIX ones, which Windows has not.
    private val posix = "posix" in FileSystems.getDefault().supportedFileAttributeViews()

    @AfterTest
    fun cleanUp() {
        root.toFile().deleteRecursively()
    }

    private val track = NowPlaying(
        title = "Low Hum",
        subtitle = "Plezy Test Artist",
        artworkUrl = "https://music.example/Items/1/Images/Primary?api_key=secret-token",
        durationSeconds = 120.0,
        positionSeconds = 3.0,
        rate = 1.0,
        status = NowPlayingStatus.PLAYING,
        canSeek = true,
        canSkipNext = false,
        canSkipPrevious = true,
        live = false,
        kind = NowPlayingKind.MUSIC,
        album = "Sine Album",
    )

    @Test
    fun theMetadataNeverCarriesTheArtworkUrl() {
        val trackId = DBusPath("/com/edde746/plezy/track/1")
        val before = mprisMetadata(track, trackId, artUri = null)
        assertNull(before["mpris:artUrl"])
        val after = mprisMetadata(track, trackId, artUri = "file:///run/user/1000/com.edde746.plezy_artwork/artwork_1.jpg")
        assertEquals("file:///run/user/1000/com.edde746.plezy_artwork/artwork_1.jpg", after["mpris:artUrl"]?.value)
        for (metadata in listOf(before, after)) {
            assertFalse(metadata.values.any { it.value.toString().contains("secret-token") }, "$metadata")
        }
    }

    @Test
    fun aTrackShowsItsTitleArtistAndAlbum() {
        val metadata = mprisMetadata(track, DBusPath("/com/edde746/plezy/track/1"), artUri = null)
        assertEquals("Low Hum", metadata["xesam:title"]?.value)
        assertEquals(listOf("Plezy Test Artist"), metadata["xesam:artist"]?.value)
        assertEquals("Sine Album", metadata["xesam:album"]?.value)
        assertEquals(120_000_000L, metadata["mpris:length"]?.value)
    }

    @Test
    fun theArtworkIsAnOwnerOnlyFileUnderItsDirectory() {
        if (!posix) return
        val bytes = byteArrayOf(1, 2, 3)
        val uri = artwork.write(bytes)
        assertTrue(uri.startsWith("file:/"), uri)
        val file = Paths.get(URI(uri))
        assertEquals(directory, file.parent)
        assertContentEquals(bytes, file.readBytes())
        assertEquals(PosixFilePermissions.fromString("rwx------"), Files.getPosixFilePermissions(directory))
        assertEquals(PosixFilePermissions.fromString("rw-------"), Files.getPosixFilePermissions(file))
    }

    @Test
    fun aDirectoryOpenToOthersIsMadeOwnerOnly() {
        if (!posix) return
        Files.createDirectories(directory)
        Files.setPosixFilePermissions(directory, PosixFilePermissions.fromString("rwxr-xr-x"))
        artwork.write(byteArrayOf(1))
        assertEquals(PosixFilePermissions.fromString("rwx------"), Files.getPosixFilePermissions(directory))
    }

    @Test
    fun aNewArtworkReplacesTheLastAndClearTakesItAway() {
        if (!posix) return
        val first = Paths.get(URI(artwork.write(byteArrayOf(1))))
        now += 1
        val second = Paths.get(URI(artwork.write(byteArrayOf(2))))
        assertEquals(listOf(second), directory.listDirectoryEntries())
        assertFalse(Files.exists(first))
        artwork.clear()
        assertFalse(Files.exists(directory))
    }

    @Test
    fun twoArtworksInTheSameMillisecondGetTheirOwnFiles() {
        if (!posix) return
        val first = artwork.write(byteArrayOf(1))
        val second = artwork.write(byteArrayOf(2))
        assertTrue(first != second)
        assertContentEquals(byteArrayOf(2), Paths.get(URI(second)).readBytes())
    }

    @Test
    fun theDirectoryIsInTheRuntimeDirectoryOrTheFlatpaksSharedPart() {
        assertEquals(Paths.get("/run/user/1000/com.edde746.plezy_artwork"), MprisArtwork.directory(mapOf("XDG_RUNTIME_DIR" to "/run/user/1000"), "com.edde746.plezy"))
        assertEquals(
            Paths.get("/run/user/1000/app/com.edde746.plezy/com.edde746.plezy_artwork"),
            MprisArtwork.directory(mapOf("XDG_RUNTIME_DIR" to "/run/user/1000", "FLATPAK_ID" to "com.edde746.plezy"), "com.edde746.plezy"),
        )
        assertEquals(
            Paths.get(System.getProperty("java.io.tmpdir"), "com.edde746.plezy_artwork"),
            MprisArtwork.directory(emptyMap(), "com.edde746.plezy"),
        )
    }
}
