package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals

class LibraryFilterValueIdTest {
    @Test
    fun aQueryKeyStandsForItsFilterParameter() {
        assertEquals("10", libraryFilterValueId("/library/sections/1/all?genre=10", "genre"))
        assertEquals("Sci Fi", libraryFilterValueId("/library/sections/1/all?type=1&genre=Sci+Fi", "genre"))
        assertEquals("b", libraryFilterValueId("/all?genre=a&genre=b", "genre"))
        assertEquals("", libraryFilterValueId("/all?genre", "genre"))
        assertEquals("/all?year=2020", libraryFilterValueId("/all?year=2020", "genre"))
    }

    @Test
    fun aPathKeyStandsForItsLastSegment() {
        assertEquals("1999", libraryFilterValueId("/library/sections/1/year/1999", "year"))
        assertEquals("PG-13", libraryFilterValueId("PG-13", "contentRating"))
    }

    @Test
    fun anEncodedIdIsDecodedToTheLiteralValue() {
        assertEquals("5.1", libraryFilterValueId("5%2E1", "audioLayout"))
        assertEquals("16+", libraryFilterValueId("/library/sections/1/contentRating/16%2B", "contentRating"))
        assertEquals("Café", libraryFilterValueId("Caf%C3%A9", "label"))
    }

    @Test
    fun aLiteralPercentKeepsTheIdAsItIs() {
        assertEquals("100%", libraryFilterValueId("100%", "label"))
        assertEquals("50%25 off%", libraryFilterValueId("50%25 off%", "label"))
        assertEquals("%zz", libraryFilterValueId("%zz", "label"))
        assertEquals("%C3", libraryFilterValueId("%C3", "label"))
    }
}
