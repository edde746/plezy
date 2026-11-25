package com.edde746.plezy.desktop

import com.edde746.plezy.desktop.windows.WindowsKnownFolders
import com.edde746.plezy.downloads.BaseDirectory
import io.ktor.client.HttpClient
import java.io.File
import java.nio.file.Files
import kotlin.io.path.ExperimentalPathApi
import kotlin.io.path.deleteRecursively
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

@OptIn(ExperimentalPathApi::class)
class DesktopDownloadsTest {
    private val http = HttpClient()
    private val dir = Files.createTempDirectory("downloads")

    @AfterTest
    fun cleanUp() {
        http.close()
        dir.deleteRecursively()
    }

    @Test
    fun theBaseDirectoriesAreTheEarlierReleasesDataFolderAndDocuments() {
        val platform = DesktopDownloads(http, supportDirectory = dir.toString(), documentsDirectory = { "/home/alex/Documents" })

        assertEquals(dir.toString(), platform.baseDirectoryPath(BaseDirectory.APPLICATION_SUPPORT))
        assertEquals("/home/alex/Documents", platform.baseDirectoryPath(BaseDirectory.APPLICATION_DOCUMENTS))
        assertEquals(File(dir.toFile(), "download_tasks").path, platform.tempDirectory)
    }

    @Test
    fun theDocumentsFolderIsFoundWithoutAnXdgDocumentsDirectory() {
        val documents = DesktopDownloads.userDocuments()
        assertTrue(File(documents).isAbsolute, documents)
        // Windows: from the Known Folder itself, not the %USERPROFILE%\Documents fallback.
        if (System.getProperty("os.name").startsWith("Windows")) assertEquals(WindowsKnownFolders.documents()?.toString(), documents)
    }

    @Test
    fun capacityIsTheNearestExistingDirectorysVolume() {
        val platform = DesktopDownloads(http, supportDirectory = dir.toString(), documentsDirectory = { dir.toString() })
        val capacity = assertNotNull(platform.capacity(dir.resolve("Movies").resolve("Title (2000)").toString()))
        assertTrue(capacity.total > 0)
        assertTrue(capacity.available in 1..capacity.total)
    }
}
