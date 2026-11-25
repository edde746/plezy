package com.edde746.plezy.data.livetv

import com.edde746.plezy.data.testData
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.SerializationException
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class LiveTvFavoriteRepositoryTest {
    private val data = testData()
    private val favorites = data.liveTvFavorites
    private val connection = "abc/user-1"
    private val source = "server://abc/jellyfin"

    @AfterTest
    fun close() = data.close()

    private fun channel(id: String, title: String? = null) = FavoriteChannel(source = source, id = id, title = title)

    @Test
    fun aReplacedListReadsBackInOrderPerConnection() = runTest {
        assertEquals(emptyList(), favorites.favorites(connection))
        val list = listOf(channel("ch-2", "Two"), FavoriteChannel(source, "ch-1", "One", "/thumb", "7.1"), channel("ch-3"))
        favorites.replace(connection, list)
        favorites.replace("abc/user-2", listOf(channel("ch-9")))
        assertEquals(list, favorites.favorites(connection))

        favorites.replace(connection, listOf(channel("ch-3"), channel("ch-2", "Two"), channel("ch-3", "again")))
        assertEquals(listOf(channel("ch-3"), channel("ch-2", "Two")), favorites.favorites(connection), "a repeat keeps its first place")

        favorites.replace(connection, emptyList())
        assertEquals(emptyList(), favorites.favorites(connection))
        assertEquals(listOf(channel("ch-9")), favorites.favorites("abc/user-2"))

        favorites.clearAll()
        assertEquals(emptyList(), favorites.favorites("abc/user-2"))
    }

    @Test
    fun theStoredJsonListParses() {
        val parsed = parseFavoriteChannelList(
            """[{"source":"$source","id":"ch-1","title":"Channel 1"},{"source":"$source","id":"ch-2","thumb":null,"vcn":"4"},""" +
                """{"key":"ch-3"},{"title":"bare"}]""",
        )
        assertEquals(
            listOf(
                FavoriteChannel(source, "ch-1", title = "Channel 1"),
                FavoriteChannel(source, "ch-2", vcn = "4"),
                FavoriteChannel("", "ch-3"),
                FavoriteChannel("", "", title = "bare"),
            ),
            parsed,
        )
        assertEquals(emptyList(), parseFavoriteChannelList(""))
        assertEquals(emptyList(), parseFavoriteChannelList("[]"))
    }

    @Test
    fun aMalformedListThrows() {
        assertFailsWith<SerializationException> { parseFavoriteChannelList("not valid json") }
        for (json in listOf("""{"not": "a list"}""", """["ch-1"]""", """[{"id":5}]""", """[{"source":["a"],"id":"x"}]""", "null")) {
            assertFailsWith<IllegalArgumentException>(json) { parseFavoriteChannelList(json) }
        }
    }
}
