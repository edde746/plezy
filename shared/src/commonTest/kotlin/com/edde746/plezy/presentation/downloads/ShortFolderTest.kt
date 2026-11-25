package com.edde746.plezy.presentation.downloads

import com.edde746.plezy.strings.T
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The download location row's value: a long folder path cut to its last two folders, placed by its length. */
class ShortFolderTest {
    @Test
    fun aDeepPathKeepsItsLastTwoFolders() {
        assertEquals("…/Media/Plezy", shortFolder("/storage/emulated/0/Media/Plezy"))
        assertEquals("…/Media/Plezy", shortFolder("/home/me/Media/Plezy/"))
    }

    @Test
    fun aShortPathShowsWhole() {
        assertEquals("/Media/Plezy", shortFolder("/Media/Plezy"))
        assertEquals("Plezy", shortFolder("Plezy"))
    }

    @Test
    fun aWindowsPathKeepsItsBackslashes() {
        assertEquals("…\\Videos\\Plezy", shortFolder("C:\\Users\\me\\Videos\\Plezy"))
    }

    @Test
    fun anAndroidTreeUriCountsTheFoldersItGrants() {
        assertEquals("…/Movies/Plezy", shortFolder("content://com.android.externalstorage.documents/tree/primary%3ADownload%2FMovies%2FPlezy"))
        assertEquals("Download/Plezy", shortFolder("content://com.android.externalstorage.documents/tree/primary%3ADownload%2FPlezy"))
    }

    @Test
    fun appStorageSitsBesideTheTitleAndALongFolderUnderIt() {
        val app = DownloadLocationUiState()
        assertEquals(T.settings.downloadLocationAppStorage, app.rowTrailingValue)
        assertNull(app.rowSubtitle)
        val custom = DownloadLocationUiState(currentPath = "/home/me/Media/Plezy", isCustom = true)
        assertNull(custom.rowTrailingValue)
        assertEquals("…/Media/Plezy", custom.rowSubtitle)
    }
}
