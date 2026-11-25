package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull

class MediaPlaylistTest {
    private fun playlist(
        id: String = "pl1",
        compositeImagePath: String? = null,
        thumbPath: String? = null,
        serverId: String? = "s1",
    ) = MediaPlaylist(
        id = id,
        backend = BackendKind.PLEX,
        title = "My Playlist",
        playlistType = "video",
        compositeImagePath = compositeImagePath,
        thumbPath = thumbPath,
        serverId = serverId,
    )

    @Test
    fun prefersTheUserAssignedThumbPathOverCompositeImagePath() {
        assertEquals("/thumb/single", playlist(compositeImagePath = "/composite/grid", thumbPath = "/thumb/single").displayImagePath)
    }

    @Test
    fun fallsBackToCompositeImagePathWhenThumbIsNull() {
        assertEquals("/composite/grid", playlist(compositeImagePath = "/composite/grid").displayImagePath)
    }

    @Test
    fun displayImagePathIsNullWhenBothAreNull() {
        assertNull(playlist().displayImagePath)
    }

    @Test
    fun usesServerIdColonIdWhenServerIdIsSet() {
        assertEquals("srv-9:pl-42", playlist(id = "pl-42", serverId = "srv-9").globalKey)
    }

    @Test
    fun fallsBackToBareIdWhenServerIdIsNull() {
        assertEquals("pl-42", playlist(id = "pl-42", serverId = null).globalKey)
    }

    @Test
    fun toleratesAllOptionalFieldsBeingNull() {
        val minimal = MediaPlaylist(id = "pl", backend = BackendKind.PLEX, title = "Min", playlistType = "video")
        assertNull(minimal.summary)
        assertNull(minimal.guid)
        assertFalse(minimal.smart)
        assertNull(minimal.durationMs)
        assertNull(minimal.leafCount)
        assertNull(minimal.viewCount)
        assertNull(minimal.addedAt)
        assertNull(minimal.updatedAt)
        assertNull(minimal.lastViewedAt)
        assertNull(minimal.compositeImagePath)
        assertNull(minimal.thumbPath)
        assertNull(minimal.serverId)
        assertNull(minimal.serverName)
        assertNull(minimal.displayImagePath)
        assertEquals("Min", minimal.displayTitle)
        assertEquals("pl", minimal.globalKey)
    }
}

class MediaPersonDetailsTest {
    private val born = CalendarDate(1992, 3, 13)

    @Test
    fun countsAYearOnlyOnceTheBirthdayHasComeRound() {
        val details = MediaPersonDetails(birthDate = born)
        assertEquals(33, details.ageOn(CalendarDate(2026, 3, 12)))
        assertEquals(34, details.ageOn(CalendarDate(2026, 3, 13)))
    }

    @Test
    fun stopsAtTheDeathDate() {
        val details = MediaPersonDetails(birthDate = CalendarDate(1979, 4, 4), deathDate = CalendarDate(2008, 1, 22))
        assertEquals(28, details.ageOn(CalendarDate(2026, 10, 14)))
    }

    @Test
    fun hasNoAgeWithoutABirthDateOrWithADeathBeforeTheBirth() {
        assertNull(MediaPersonDetails(deathDate = born).ageOn(CalendarDate(2026, 1, 1)))
        assertNull(MediaPersonDetails(birthDate = born, deathDate = CalendarDate(1990, 1, 1)).ageOn(CalendarDate(2026, 1, 1)))
    }

    @Test
    fun parseDateKeepsTheCalendarDayOfBothWireShapes() {
        assertEquals(CalendarDate(1992, 3, 13), MediaPersonDetails.parseDate("1992-03-13"))
        assertEquals(CalendarDate(1976, 6, 6), MediaPersonDetails.parseDate("1976-06-06T00:00:00.0000000Z"))
        assertNull(MediaPersonDetails.parseDate(""))
        assertNull(MediaPersonDetails.parseDate(19920313))
    }

    @Test
    fun personGlobalKeyIsNamespaced() {
        assertEquals("s1:person:7", MediaPerson(id = "7", name = "A", backend = BackendKind.PLEX, serverId = ServerId("s1")).globalKey)
    }
}
