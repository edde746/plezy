package com.edde746.plezy.downloads

import android.content.Context
import android.net.Uri
import android.provider.DocumentsContract
import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.test.runTest
import java.io.File
import kotlin.test.AfterTest
import kotlin.test.BeforeTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * [AndroidSafStorage] against a real documents provider ([FolderDocumentsProvider]) holding
 * `Movies/Film (2020)/Film.mkv` (5 bytes) and an empty `Empty` folder: what the downloads in a picked folder rely on.
 */
class AndroidSafStorageTest {
    private val context: Context = InstrumentationRegistry.getInstrumentation().targetContext
    private val folder = FolderDocumentsProvider.folder(context.cacheDir)
    private val storage = AndroidSafStorage(context)
    private val tree: Uri = DocumentsContract.buildTreeDocumentUri(FolderDocumentsProvider.AUTHORITY, FolderDocumentsProvider.ROOT_ID)
    private val treeUri = tree.toString()

    private fun documentUri(path: String): String =
        DocumentsContract.buildDocumentUriUsingTree(tree, "${FolderDocumentsProvider.ROOT_ID}/$path").toString()

    @BeforeTest
    fun createTree() {
        folder.deleteRecursively()
        File(folder, "Movies/Film (2020)").mkdirs()
        File(folder, "Movies/Film (2020)/Film.mkv").writeBytes(byteArrayOf(1, 2, 3, 4, 5))
        File(folder, "Empty").mkdirs()
    }

    @AfterTest
    fun removeTree() {
        folder.deleteRecursively()
    }

    @Test
    fun listGivesEachChildOfATreeWithItsKindAndSize() = runTest {
        val children = assertNotNull(storage.list(treeUri)).sortedBy { it.name }

        assertEquals(listOf("Empty", "Movies"), children.map { it.name })
        assertTrue(children.all { it.isDir && it.length == 0L })
        assertEquals(documentUri("Empty"), children[0].uri)

        val film = assertNotNull(storage.list(documentUri("Movies/Film (2020)"))).single()
        assertEquals(SafDocumentFile(documentUri("Movies/Film (2020)/Film.mkv"), "Film.mkv", false, 5, film.lastModified), film)
        assertTrue(film.lastModified > 0)
    }

    @Test
    fun listOfAnEmptyFolderIsEmptyAndOfAMissingOneIsNull() = runTest {
        assertEquals(emptyList(), storage.list(documentUri("Empty")))
        assertNull(storage.list(documentUri("Gone")))
        assertNull(storage.list("not a uri"))
    }

    @Test
    fun aTreeUriAndADocumentUriBothNameTheFolder() = runTest {
        val subtree = DocumentsContract.buildTreeDocumentUri(FolderDocumentsProvider.AUTHORITY, "${FolderDocumentsProvider.ROOT_ID}/Movies")

        assertEquals(listOf("Film (2020)"), storage.list(subtree.toString())?.map { it.name })
        assertEquals(listOf("Film (2020)"), storage.list(documentUri("Movies"))?.map { it.name })
        assertTrue(storage.exists(subtree.toString(), isDir = true))
    }

    @Test
    fun existsAnswersForFilesAndFoldersAndIsFalseWhenMissing() = runTest {
        assertTrue(storage.exists(treeUri, isDir = true))
        assertTrue(storage.exists(documentUri("Movies"), isDir = true))
        assertTrue(storage.exists(documentUri("Movies/Film (2020)/Film.mkv"), isDir = false))

        assertFalse(storage.exists(documentUri("Movies/Other.mkv"), isDir = false))
        assertFalse(storage.exists(documentUri("Gone"), isDir = true))
        assertFalse(storage.exists("not a uri", isDir = false))
    }

    @Test
    fun getChildWalksNamesAndIsNullWhenOneIsMissing() = runTest {
        val film = assertNotNull(storage.getChild(treeUri, listOf("Movies", "Film (2020)", "Film.mkv")))
        assertEquals(documentUri("Movies/Film (2020)/Film.mkv"), film.uri)
        assertEquals("Film.mkv", film.name)
        assertFalse(film.isDir)
        assertEquals(5, film.length)

        val movies = assertNotNull(storage.getChild(treeUri, listOf("Movies")))
        assertTrue(movies.isDir)
        assertEquals(0, movies.length)

        assertEquals(folder.name, storage.getChild(treeUri, emptyList())?.name)
        assertNull(storage.getChild(treeUri, listOf("Movies", "Other (2021)")))
        assertNull(storage.getChild(documentUri("Gone"), listOf("Film.mkv")))
    }

    @Test
    fun createNestedDirectoriesReusesFoldersAndRefusesAFileInTheWay() = runTest {
        val created = assertNotNull(storage.createNestedDirectories(treeUri, listOf("Movies", "New (2024)", "Season 1")))
        assertEquals(documentUri("Movies/New (2024)/Season 1"), created)
        assertTrue(File(folder, "Movies/New (2024)/Season 1").isDirectory)

        assertEquals(created, storage.createNestedDirectories(treeUri, listOf("Movies", "New (2024)", "Season 1")))
        assertEquals(listOf("Film (2020)", "New (2024)"), File(folder, "Movies").list()?.sorted())

        assertNull(storage.createNestedDirectories(treeUri, listOf("Movies", "Film (2020)", "Film.mkv", "Extras")))
        assertNull(storage.createNestedDirectories(documentUri("Gone"), listOf("Extras")))
    }

    @Test
    fun deleteRemovesAFileOrAWholeFolderAndIsFalseWhenNothingIsThere() = runTest {
        assertTrue(storage.delete(documentUri("Movies/Film (2020)/Film.mkv"), isDir = false))
        assertFalse(File(folder, "Movies/Film (2020)/Film.mkv").exists())

        assertTrue(storage.delete(documentUri("Movies"), isDir = true))
        assertFalse(File(folder, "Movies").exists())

        assertFalse(storage.delete(documentUri("Movies"), isDir = true))
    }

    @Test
    fun noGrantResolvesForATreeThisAppWasNeverGranted() = runTest {
        assertNull(storage.resolvePersistedPermissionUri(treeUri))
        assertEquals(false, storage.getPersistedPermissionUris()?.contains(treeUri))
        assertTrue(storage.releasePersistedPermission(treeUri))
    }
}
