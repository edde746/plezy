package com.edde746.plezy.watchnext

import android.net.Uri
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.io.File
import java.io.FileNotFoundException
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A launcher reads the Watch Next posters straight from the provider, with no grant: one that isn't the home app gets
 * none. Any app that may read the TV provider's rows may open a poster, read-only, and nothing else of the app.
 */
@RunWith(RobolectricTestRunner::class)
class ShelfArtworkProviderTest {
    private val context = RuntimeEnvironment.getApplication()
    private val authority = ShelfArtwork.authority(context)
    private val provider = Robolectric.buildContentProvider(ShelfArtworkProvider::class.java).create(authority).get()
    private val ownerKey = ShelfArtwork.sha256("alice")
    private val key = ShelfArtwork.sha256("alice\u0000https://plex/poster.jpg")

    private fun uri(vararg path: String): Uri = Uri.Builder().scheme("content").authority(authority).apply { path.forEach(::appendPath) }.build()

    @Test
    fun aLauncherThatReadsTvListingsReachesThePostersWithoutAGrant() {
        val info = assertNotNull(context.packageManager.resolveContentProvider(authority, 0))
        assertTrue(info.exported, "a launcher that isn't the home app reaches the provider")
        assertEquals("com.android.providers.tv.permission.READ_EPG_DATA", info.readPermission)
    }

    @Test
    fun aLauncherOpensAPosterReadOnlyAndNothingElse() {
        val poster = File(context.cacheDir, "system_shelf_artwork/$ownerKey/$key.art")
        poster.parentFile!!.mkdirs()
        poster.writeBytes(byteArrayOf(1, 2, 3))
        File(context.cacheDir, "secret.art").writeBytes(byteArrayOf(9))
        File(context.filesDir, "$key.art").writeBytes(byteArrayOf(9))

        provider.openFile(uri("art", ownerKey, "$key.art"), "r").use { assertEquals(3L, it.statSize) }

        assertFailsWith<FileNotFoundException> { provider.openFile(uri("art", ownerKey, "$key.art"), "w") }
        assertFailsWith<FileNotFoundException> { provider.openFile(uri("art", ownerKey, "$key.art"), "rw") }
        for (other in listOf(
            uri("art", ownerKey, "${ShelfArtwork.sha256("missing")}.art"),
            uri("art", "..", "secret.art"),
            uri("art", ownerKey, "..", "..", "secret.art"),
            uri("secret.art"),
            uri("files", "$key.art"),
            Uri.parse("content://$authority/art/$ownerKey/..%2F..%2Fsecret.art"),
        )) {
            assertFailsWith<FileNotFoundException>("$other") { provider.openFile(other, "r") }
        }
        assertNull(provider.query(uri("art", ownerKey, "$key.art"), null, null, null, null))
        assertNull(provider.insert(uri("art", ownerKey, "x.art"), null))
        assertEquals(0, provider.delete(uri("art", ownerKey, "$key.art"), null, null))
        assertTrue(poster.isFile)
    }
}
