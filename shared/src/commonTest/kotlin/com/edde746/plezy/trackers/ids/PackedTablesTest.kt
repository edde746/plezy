package com.edde746.plezy.trackers.ids

import com.edde746.plezy.trackers.ids.PackedList.column
import com.edde746.plezy.trackers.ids.PackedList.dict
import com.edde746.plezy.trackers.ids.PackedList.file
import com.edde746.plezy.trackers.ids.PackedList.intDeltas
import com.edde746.plezy.trackers.ids.PackedList.intLists
import com.edde746.plezy.trackers.ids.PackedList.ints
import com.edde746.plezy.trackers.ids.PackedList.strLists
import com.edde746.plezy.trackers.ids.PackedList.strs
import com.edde746.plezy.trackers.ids.PackedList.table
import com.edde746.plezy.trackers.ids.PackedTables.Companion.NONE
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/**
 * anime-mappings' packed list as [PackedTables] reads it: tables of named columns of six types, whose layout is checked
 * as the file is read and whose values decode when asked for; columns, tables and types it doesn't know are skipped,
 * and ones the file lacks read as absent values.
 */
class PackedTablesTest {
    @Test
    fun everyColumnTypeReadsBackWithItsAbsentValues() {
        val t = PackedTables.read(
            file(
                table(
                    "t", 3,
                    column("int", PackedTables.INT, ints(5, null, -3)),
                    column("delta", PackedTables.INT_DELTA, intDeltas(100, null, 98)),
                    column("str", PackedTables.STR, strs("é", null, "")),
                    column("dict", PackedTables.DICT, dict("TV", null, "TV")),
                    column("ints", PackedTables.INT_LIST, intLists(listOf(1L, -2L), null, emptyList())),
                    column("strs", PackedTables.STR_LIST, strLists(listOf("a", "b"), null, emptyList())),
                    column("wide", PackedTables.INT, ints(Int.MAX_VALUE + 1L, Int.MAX_VALUE.toLong(), Int.MIN_VALUE - 1L)),
                    column("wideItems", PackedTables.INT_LIST, intLists(listOf(1L, 1L shl 40, 2L), null, null)),
                ),
            ),
        ).table("t")
        assertEquals(3, t.rows)
        assertEquals(listOf(5, NONE, -3), t.ints("int").toList())
        assertEquals(listOf(100, NONE, 98), t.ints("delta").toList(), "each value from the previous present one")
        assertEquals(listOf("é", null, ""), t.strings("str").toList())
        assertEquals(listOf("TV", null, "TV"), t.strings("dict").toList())
        assertEquals(listOf(listOf(1, -2), null, emptyList()), t.intLists("ints").map { it?.toList() })
        assertEquals(listOf(listOf("a", "b"), null, emptyList()), t.stringLists("strs").toList())
        // Numbers outside an Int's range: absent, and left out of a list.
        assertEquals(listOf(NONE, Int.MAX_VALUE, NONE), t.ints("wide").toList())
        assertEquals(listOf(1, 2), t.intLists("wideItems")[0]?.toList())
    }

    @Test
    fun columnsAndTablesItDoesntKnowAreSkipped() {
        val tables = PackedTables.read(
            file(
                table("later", 1, column("x", PackedTables.INT, ints(1))),
                table(
                    "t", 2,
                    column("a", PackedTables.INT, ints(1, 2)),
                    // A type a later file may bring, its data whatever it is, and a new column of a known type.
                    column("future", 9, byteArrayOf(-1, -1, -1, 0, 7)),
                    column("other", PackedTables.STR, strs("x", "y")),
                    column("b", PackedTables.STR, strs("one", "two")),
                ),
            ),
        )
        val t = tables.table("t")
        assertEquals(listOf(1, 2), t.ints("a").toList())
        assertEquals(listOf("one", "two"), t.strings("b").toList())
        assertEquals(listOf(NONE, NONE), t.ints("future").toList(), "an unknown type isn't read as a known one")
    }

    @Test
    fun aMissingTableOrColumnOrOneOfAnotherTypeReadsAsAbsent() {
        val t = PackedTables.read(file(table("t", 1, column("s", PackedTables.STR, strs("x"))))).table("t")
        assertEquals(0, PackedTables.read(file()).table("t").rows)
        assertEquals(listOf(NONE), t.ints("missing").toList())
        assertEquals(listOf(NONE), t.ints("s").toList())
        assertEquals(listOf(null), t.stringLists("s").toList())
    }

    @Test
    fun aFileThatIsntAVersionOnePackedListIsRejected() {
        val good = file(
            table("t", 2, column("a", PackedTables.INT, ints(1, 300)), column("b", PackedTables.STR, strs("xy", null))),
        )
        assertEquals(listOf(1, 300), PackedTables.read(good).table("t").ints("a").toList())
        val rejected = mapOf(
            "another magic" to file(magic = "AMAQ"),
            "another version" to file(version = 2),
            "nothing after the magic" to "AMAP".encodeToByteArray(),
            "bytes after the last table" to good + byteArrayOf(0),
            "a table more than it holds" to file().copyOf(5) + PackedList.varint(1),
        )
        for ((case, bytes) in rejected) assertFailsWith<IllegalArgumentException>(case) { PackedTables.read(bytes) }
        // Cut short anywhere: in the header, a table's or a column's name or length, a column's data.
        for (size in 0 until good.size) {
            assertFailsWith<IllegalArgumentException>("cut to $size bytes") { PackedTables.read(good.copyOf(size)) }
        }
    }

    @Test
    fun aColumnWhoseDataDoesntEndWithItsLastRowIsRejectedWhenRead() {
        val t = PackedTables.read(
            file(
                table(
                    "t", 2,
                    column("long", PackedTables.INT, ints(1, 2) + byteArrayOf(0)),
                    column("longStrings", PackedTables.STR, strs("a", null) + byteArrayOf(0)),
                    column("short", PackedTables.INT, ints(1)),
                    column("cutString", PackedTables.STR, PackedList.varint(5) + "ab".encodeToByteArray()),
                    column("badWord", PackedTables.DICT, dict("TV", "TV").also { it[it.size - 1] = 3 }),
                    column("fine", PackedTables.INT, ints(7, 8)),
                ),
            ),
        ).table("t")
        for (name in listOf("long", "short")) assertFailsWith<IllegalArgumentException>(name) { t.ints(name) }
        for (name in listOf("longStrings", "cutString", "badWord")) assertFailsWith<IllegalArgumentException>(name) { t.strings(name) }
        assertEquals(listOf(7, 8), t.ints("fine").toList(), "the other columns still read")
    }

    /** The excerpt's file, as edde746/anime-mappings' builder wrote it ([AnimeMappingIndexTest] has its source). */
    @Test
    fun theBuildersFileReads() {
        val tables = PackedTables.read(gunzip(animeMappingsExcerpt()))
        val fribb = tables.table("fribb")
        assertEquals(15, fribb.rows)
        assertEquals(listOf("TV", "TV", "MOVIE"), fribb.strings("type").take(3))
        assertEquals(listOf(23, 69, 1250), fribb.ints("anidb_id").take(3))
        // Galactic Railroad: a film with two IMDb ids; the My Hero Academia OVA has no MyAnimeList id.
        assertEquals(listOf("tt1920940", "tt0089206"), fribb.stringLists("imdb_id")[2])
        assertEquals(listOf(37585), fribb.intLists("themoviedb_id.movie")[2]?.toList())
        assertEquals(NONE, fribb.ints("themoviedb_id.tv")[2])
        assertEquals(NONE, fribb.ints("mal_id")[11])

        val lists = tables.table("anime_lists")
        assertEquals(15, lists.rows)
        assertEquals("movie" to NONE, lists.strings("tvdbid_text")[2] to lists.ints("tvdbid")[2])
        assertEquals("a" to NONE, lists.strings("defaulttvdbseason_text")[1] to lists.ints("defaulttvdbseason")[1])
        assertEquals("Cowboy Bebop", lists.strings("name")[0])
        val mappings = tables.table("anime_lists_mappings")
        assertEquals(58, mappings.rows)
        assertEquals(";4-0;", mappings.strings("text")[0])

        val indexes = AnimeMappings.read(gunzip(animeMappingsExcerpt()))
        assertEquals(15, indexes.fribb.size)
        assertEquals(1250, indexes.fribb.lookup(movie = true, imdb = "tt0089206").single().anidb)
        assertEquals(60, indexes.animeLists.lookupEpisode(tvdbId = 252322, tmdbId = null, season = 2, episode = 2)?.anidbEpisode)
    }
}
