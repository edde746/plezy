package com.edde746.plezy.settings

import com.edde746.plezy.data.testData
import com.edde746.plezy.model.LibraryFilter
import com.edde746.plezy.model.LibraryFilterOperator
import com.edde746.plezy.model.LibrarySort
import com.edde746.plezy.model.LibrarySortDirection.ASCENDING
import com.edde746.plezy.model.LibrarySortDirection.DESCENDING
import kotlinx.coroutines.test.runTest
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class LibraryPrefsTest {
    private val data = testData()
    private val prefs = data.libraryPrefs

    @AfterTest
    fun close() = data.close()

    private suspend fun activate(profileId: String) = data.deviceSettings.set(AppSettings.activeAppProfileId, profileId)

    // ---- Hidden libraries -------------------------------------------------------------------------------------------

    @Test
    fun hiddenLibrariesRoundTripAndOverwrite() = runTest {
        assertTrue(prefs.hiddenLibraries().isEmpty())
        prefs.setHiddenLibraries(setOf("lib-a", "lib-b"))
        assertEquals(setOf("lib-a", "lib-b"), prefs.hiddenLibraries())
        prefs.setHiddenLibraries(setOf("lib-c"))
        assertEquals(setOf("lib-c"), prefs.hiddenLibraries())
        prefs.setHiddenLibraries(emptySet())
        assertEquals("[]", data.storedJson("hidden_libraries"), "an empty set is stored, not removed")
        assertTrue(prefs.hiddenLibraries().isEmpty())
    }

    @Test
    fun explicitProfileReadsIsolateHiddenLibrariesFromActiveProfileChanges() = runTest {
        activate("owner")
        prefs.setHiddenLibraries(setOf("srv:movies"), profileId = "owner")
        activate("kids")
        prefs.setHiddenLibraries(setOf("srv:kids"), profileId = "kids")

        assertEquals(setOf("srv:movies"), prefs.hiddenLibraries("owner"))
        assertEquals(setOf("srv:kids"), prefs.hiddenLibraries("kids"))
        assertEquals(setOf("srv:kids"), prefs.hiddenLibraries())
    }

    @Test
    fun garbageHiddenLibrariesReadAsNone() = runTest {
        data.store("hidden_libraries", "\"not-json\"")
        assertTrue(prefs.hiddenLibraries().isEmpty())
    }

    @Test
    fun anotherProfilesReadDoesNotAdoptTheUnscopedHiddenLibraries() = runTest {
        data.store("hidden_libraries", """["legacy"]""")
        activate("local-user-1")

        assertTrue(prefs.hiddenLibraries("local-user-2").isEmpty())
        assertEquals(setOf("legacy"), prefs.hiddenLibraries("local-user-1"))
        assertNull(data.storedJson("hidden_libraries"))
    }

    // ---- Library order ----------------------------------------------------------------------------------------------

    @Test
    fun theOrderRoundTripsAsSaved() = runTest {
        assertNull(prefs.libraryOrder())
        prefs.setLibraryOrder(listOf("c", "a", "b"))
        assertEquals(listOf("c", "a", "b"), prefs.libraryOrder())
    }

    @Test
    fun anUnscopedOrderMovesIntoTheActiveProfile() = runTest {
        data.store("library_order", "\"[\\\"x\\\",\\\"y\\\"]\"")
        activate("local-user-1")

        assertEquals(listOf("x", "y"), prefs.libraryOrder())
        assertEquals("""["x","y"]""", data.storedProfileJson("local-user-1", "library_order"))
        assertNull(data.storedJson("library_order"))
    }

    @Test
    fun anAdoptedOrderIsNotInheritedByAnotherProfile() = runTest {
        data.store("library_order", """["legacy"]""")
        activate("local-user-1")
        assertEquals(listOf("legacy"), prefs.libraryOrder())

        activate("local-user-2")
        assertNull(prefs.libraryOrder())
    }

    @Test
    fun eachProfileKeepsItsOwnOrder() = runTest {
        activate("local-user-1")
        prefs.setLibraryOrder(listOf("u1-a", "u1-b"))
        activate("local-user-2")
        assertNull(prefs.libraryOrder())
        prefs.setLibraryOrder(listOf("u2-a"))

        activate("local-user-1")
        assertEquals(listOf("u1-a", "u1-b"), prefs.libraryOrder())
        activate("local-user-2")
        assertEquals(listOf("u2-a"), prefs.libraryOrder())
    }

    @Test
    fun aPlexHomeProfileKeepsItsChoicesUnderItsHomeUsersUuid() = runTest {
        val uuid = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
        data.storeProfile(uuid, "library_order", """["legacy"]""")
        activate("plex-home-plex.abc-def-123-$uuid")

        assertEquals(listOf("legacy"), prefs.libraryOrder())
        prefs.setLibraryOrder(listOf("x"))
        assertEquals("""["x"]""", data.storedProfileJson(uuid, "library_order"))
    }

    // ---- Filters, sort, grouping, tab ---------------------------------------------------------------------------

    @Test
    fun sharedFiltersRoundTripWithTheirOperators() = runTest {
        assertTrue(prefs.filters().isEmpty())
        val selection = listOf(
            LibraryFilter("genre", listOf("sci-fi", "horror")),
            LibraryFilter("year", listOf("2024"), LibraryFilterOperator.AT_LEAST),
            LibraryFilter("contentRating", listOf("R"), LibraryFilterOperator.IS_NOT),
        )
        prefs.setFilters(selection)
        assertEquals(selection, prefs.filters())
    }

    @Test
    fun aLibraryWithoutItsOwnFiltersTakesTheSharedOnes() = runTest {
        val shared = listOf(LibraryFilter("unwatched", listOf("1")))
        val own = listOf(LibraryFilter("genre", listOf("horror")))
        prefs.setFilters(shared)
        assertEquals(shared, prefs.filters("sec-1"))
        assertTrue(prefs.filters("downloads:tv", legacyGlobalFallback = false).isEmpty())

        prefs.setFilters(own, "sec-1")
        assertEquals(own, prefs.filters("sec-1"))
        assertEquals(shared, prefs.filters())
    }

    @Test
    fun unscopedLibraryFiltersMoveOnceIntoTheActiveProfile() = runTest {
        data.store("library_filters_sec-1", """[{"field":"genre","values":["drama"]}]""")
        activate("local-user-1")

        assertEquals(listOf(LibraryFilter("genre", listOf("drama"))), prefs.filters("sec-1"))
        assertNotNull(data.storedProfileJson("local-user-1", "library_filters_sec-1"))
        assertNull(data.storedJson("library_filters_sec-1"))

        activate("local-user-2")
        assertTrue(prefs.filters("sec-1").isEmpty())
    }

    @Test
    fun filtersSavedAsAFlatMapRestoreAsEqualityClauses() = runTest {
        data.store("library_filters_sec-legacy", """{"genre":"42,43","unwatched":"1"}""")
        assertEquals(
            listOf(LibraryFilter("genre", listOf("42", "43")), LibraryFilter("unwatched", listOf("1"))),
            prefs.filters("sec-legacy"),
        )
    }

    @Test
    fun aClauseWithAnUnknownOperatorIsDroppedNotDowngradedToInclude() = runTest {
        data.store(
            "library_filters_sec-future",
            """[{"field":"genre","op":"isNot","values":["42"]},{"field":"genre","op":"matchesFuzzily","values":["43"]}]""",
        )
        assertEquals(listOf(LibraryFilter("genre", listOf("42"), LibraryFilterOperator.IS_NOT)), prefs.filters("sec-future"))
    }

    @Test
    fun theSortRoundTripsWithItsDirection() = runTest {
        prefs.setSort("sec-1", "titleSort", descending = true)
        assertEquals(LibrarySort("titleSort", DESCENDING), prefs.sort("sec-1"))
        assertEquals("""{"key":"titleSort","descending":true}""", data.storedJson("library_sort_sec-1"))
        prefs.setSort("sec-1", "addedAt")
        assertEquals(LibrarySort("addedAt", ASCENDING), prefs.sort("sec-1"))
    }

    @Test
    fun aSortKeyStoredAloneReadsAscending() = runTest {
        data.store("library_sort_sec-1", "\"titleSort\"")
        assertEquals(LibrarySort("titleSort", ASCENDING), prefs.sort("sec-1"))
    }

    @Test
    fun clearingASortAlsoRemovesTheUnscopedOneSoItCannotComeBack() = runTest {
        activate("local-user-1")
        prefs.setSort("sec-1", "addedAt", descending = true)
        data.store("library_sort_sec-1", """{"key":"titleSort","descending":false}""")

        prefs.clearSort("sec-1")

        assertNull(prefs.sort("sec-1"))
        assertNull(data.storedJson("library_sort_sec-1"))
    }

    @Test
    fun groupingTabAndSelectedLibraryRoundTrip() = runTest {
        assertNull(prefs.grouping("sec-1"))
        prefs.setGrouping("sec-1", "shows")
        assertEquals("shows", prefs.grouping("sec-1"))

        assertNull(prefs.tab("sec-1"))
        prefs.setTab("sec-1", "recommended")
        assertEquals("recommended", prefs.tab("sec-1"))

        assertNull(prefs.selectedLibraryKey())
        prefs.setSelectedLibraryKey("lib-key-42")
        assertEquals("lib-key-42", prefs.selectedLibraryKey())
    }

    @Test
    fun aTabIndexOfEarlierReleasesReadsAsNone() = runTest {
        activate("local-user-1")
        data.storeProfile("local-user-1", "library_tab_sec-1", "2")
        assertNull(prefs.tab("sec-1"))
    }

    // ---- Clearing ----------------------------------------------------------------------------------------------------

    @Test
    fun clearingClearsTheActiveProfilesChoicesOnly() = runTest {
        activate("local-user-1")
        prefs.setLibraryOrder(listOf("u1-a", "u1-b"))
        prefs.setSelectedLibraryKey("u1-key")
        prefs.setFilters(listOf(LibraryFilter("genre", listOf("horror"))), "sec-1")
        prefs.setSort("sec-1", "titleSort", descending = true)
        prefs.setGrouping("sec-1", "shows")
        prefs.setTab("sec-1", "tabA")
        prefs.setHiddenLibraries(setOf("h-1"))

        activate("local-user-2")
        prefs.setLibraryOrder(listOf("u2-a"))
        prefs.setSelectedLibraryKey("u2-key")

        prefs.clearAll()
        assertNull(prefs.libraryOrder())
        assertNull(prefs.selectedLibraryKey())

        activate("local-user-1")
        assertEquals(listOf("u1-a", "u1-b"), prefs.libraryOrder())
        assertEquals("u1-key", prefs.selectedLibraryKey())
        assertEquals(listOf(LibraryFilter("genre", listOf("horror"))), prefs.filters("sec-1"))
        assertEquals(LibrarySort("titleSort", DESCENDING), prefs.sort("sec-1"))
        assertEquals("shows", prefs.grouping("sec-1"))
        assertEquals("tabA", prefs.tab("sec-1"))
        assertEquals(setOf("h-1"), prefs.hiddenLibraries())

        prefs.clearAll()
        assertNull(prefs.libraryOrder())
        assertNull(prefs.selectedLibraryKey())
        assertTrue(prefs.filters("sec-1").isEmpty())
        assertNull(prefs.sort("sec-1"))
        assertNull(prefs.grouping("sec-1"))
        assertNull(prefs.tab("sec-1"))
        assertTrue(prefs.hiddenLibraries().isEmpty())
    }

    @Test
    fun clearingAlsoConsumesUnscopedValuesNotAdoptedYet() = runTest {
        data.store("library_order", """["legacy"]""")
        data.store("library_filters_sec-1", """[{"field":"genre","values":["drama"]}]""")
        activate("local-user-1")

        prefs.clearAll()

        assertNull(prefs.libraryOrder())
        assertTrue(prefs.filters("sec-1").isEmpty())
        assertNull(data.storedJson("library_order"))
        assertNull(data.storedJson("library_filters_sec-1"))
    }

    @Test
    fun clearingAServerClearsOnlyThatProfilesChoicesForIt() = runTest {
        activate("local-user-1")
        prefs.setLibraryOrder(listOf("srv-a:movies", "srv-b:shows"))
        prefs.setSelectedLibraryKey("srv-a:movies")
        prefs.setHiddenLibraries(setOf("srv-a:movies", "srv-b:shows"))
        prefs.setFilters(listOf(LibraryFilter("genre", listOf("sci-fi"))), "srv-a:movies")
        prefs.setFilters(listOf(LibraryFilter("genre", listOf("drama"))), "srv-b:shows")
        prefs.setSort("srv-a:movies", "titleSort")
        prefs.setGrouping("srv-a:movies", "movies")
        prefs.setTab("srv-a:movies", "recommended")

        activate("local-user-2")
        prefs.setLibraryOrder(listOf("srv-a:movies"))
        prefs.setHiddenLibraries(setOf("srv-a:movies"))

        prefs.clearForServer("srv-a", profileId = "local-user-1")

        activate("local-user-1")
        assertEquals(listOf("srv-b:shows"), prefs.libraryOrder())
        assertNull(prefs.selectedLibraryKey())
        assertEquals(setOf("srv-b:shows"), prefs.hiddenLibraries())
        assertTrue(prefs.filters("srv-a:movies").isEmpty())
        assertEquals(listOf(LibraryFilter("genre", listOf("drama"))), prefs.filters("srv-b:shows"))
        assertNull(prefs.sort("srv-a:movies"))
        assertNull(prefs.grouping("srv-a:movies"))
        assertNull(prefs.tab("srv-a:movies"))

        activate("local-user-2")
        assertEquals(listOf("srv-a:movies"), prefs.libraryOrder())
        assertEquals(setOf("srv-a:movies"), prefs.hiddenLibraries())

        prefs.clearForServer("srv-b", profileId = "local-user-1")
        activate("local-user-1")
        assertNull(prefs.libraryOrder())
        assertTrue(prefs.hiddenLibraries().isEmpty())
    }

    @Test
    fun clearingAServerEverywhereClearsItFromEveryScope() = runTest {
        data.store("library_order", """["srv-a:legacy","srv-b:legacy"]""")
        data.store("hidden_libraries", """["srv-a:legacy","srv-b:legacy"]""")
        data.store("selected_library_key", "\"srv-a:legacy\"")
        data.store("library_sort_srv-a:legacy", """{"key":"titleSort","descending":false}""")
        data.store("library_grouping_srv-a:legacy", "\"movies\"")

        activate("local-user-1")
        prefs.setLibraryOrder(listOf("srv-a:movies", "srv-b:shows"))
        prefs.setHiddenLibraries(setOf("srv-a:movies", "srv-b:shows"))
        prefs.setSort("srv-a:movies", "titleSort")

        activate("local-user-2")
        prefs.setLibraryOrder(listOf("srv-a:movies"))
        prefs.setHiddenLibraries(setOf("srv-a:movies"))

        prefs.clearForServerEverywhere("srv-a")

        assertEquals("""["srv-b:legacy"]""", data.storedJson("library_order"))
        assertEquals("""["srv-b:legacy"]""", data.storedJson("hidden_libraries"))
        assertNull(data.storedJson("selected_library_key"))
        assertNull(data.storedJson("library_sort_srv-a:legacy"))
        assertNull(data.storedJson("library_grouping_srv-a:legacy"))

        activate("local-user-1")
        assertEquals(listOf("srv-b:shows"), prefs.libraryOrder())
        assertEquals(setOf("srv-b:shows"), prefs.hiddenLibraries())
        assertNull(prefs.sort("srv-a:movies"))

        activate("local-user-2")
        assertEquals(listOf("srv-b:legacy"), prefs.libraryOrder())
        assertEquals(setOf("srv-b:legacy"), prefs.hiddenLibraries())
    }

    @Test
    fun resettingAPreferenceOfTheActiveProfileAlsoRemovesTheUnscopedValue() = runTest {
        data.store("library_sort_sec-1", "\"titleSort\"")
        activate("local-user-1")

        prefs.resetPreference("sec-1", LibraryPreference.SORT, "local-user-1")

        assertNull(prefs.sort("sec-1"))
        assertNull(data.storedJson("library_sort_sec-1"))
    }
}
