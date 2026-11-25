package com.edde746.plezy.players

import android.content.Context
import android.os.Environment
import androidx.core.content.FileProvider
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import org.junit.Assume.assumeTrue
import org.junit.Before

/**
 * The file provider a download is handed to a player app through ([PlayerFiles]): the application id's `.fileprovider`
 * authority, and a URI for a file in any folder a download can be in, under the earlier releases' root names. On a
 * POSIX host only: FileProvider matches paths by `/`, as Android's are, so a Windows host's can't match.
 */
@RunWith(RobolectricTestRunner::class)
class PlayerFilesTest {
    private val context: Context = RuntimeEnvironment.getApplication()
    private val authority = "${context.packageName}.fileprovider"

    @Before
    fun posixPaths() = assumeTrue("FileProvider needs / paths", File.separatorChar == '/')

    private fun uri(file: File): String {
        file.parentFile!!.mkdirs()
        file.createNewFile()
        return FileProvider.getUriForFile(context, "${context.packageName}${AndroidPlayerApps.AUTHORITY_SUFFIX}", file).toString()
    }

    @Test
    fun `every folder a download can be in has its root under the provider authority`() {
        assertEquals("content://$authority/app_files/downloads/Movie.mkv", uri(File(context.filesDir, "downloads/Movie.mkv")))
        assertEquals("content://$authority/cache/Movie.srt", uri(File(context.cacheDir, "Movie.srt")))
        assertEquals("content://$authority/external_files/downloads/Movie.mkv", uri(File(context.getExternalFilesDir(null), "downloads/Movie.mkv")))
        assertEquals("content://$authority/external_cache/Movie.srt", uri(File(context.externalCacheDir, "Movie.srt")))
        @Suppress("DEPRECATION")
        val shared = File(Environment.getExternalStorageDirectory(), "Movies/Plezy/Movie.mkv")
        assertEquals("content://$authority/external/Movies/Plezy/Movie.mkv", uri(shared))
    }

    @Test
    fun `a path outside the app folders goes through the root`() {
        val beside = File(context.filesDir.parentFile, "app_flutter/downloads/Movie.mkv")
        assertEquals("content://$authority/root${beside.canonicalPath}", uri(beside))
    }
}
