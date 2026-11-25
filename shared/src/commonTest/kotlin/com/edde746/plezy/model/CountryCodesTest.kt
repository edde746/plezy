package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class CountryCodesTest {
    @Test
    fun coversEveryAlpha2CodeWithShortNames() {
        assertEquals(249, COUNTRY_NAMES.size)
        assertEquals("United Kingdom", CountryCodes.getCountryName("GB"))
    }

    @Test
    fun countryNamesNormalizeTheCodeAndRejectOtherLengths() {
        assertEquals("United States", CountryCodes.getCountryName(" us "))
        assertNull(CountryCodes.getCountryName("USA"))
        assertNull(CountryCodes.getCountryName("SU"))
    }

    @Test
    fun displayNamesFallBackToTheNormalizedCode() {
        assertEquals("Japan", CountryCodes.getDisplayName("jp"))
        assertEquals("SU", CountryCodes.getDisplayName(" su"))
    }

    @Test
    fun codesResolveFromOfficialShortAndColloquialNames() {
        assertEquals("US", CountryCodes.getCountryCode("United States of America"))
        assertEquals("US", CountryCodes.getCountryCode("america"))
        assertEquals("GB", CountryCodes.getCountryCode(" United Kingdom "))
        assertEquals("DE", CountryCodes.getCountryCode("de"))
        assertNull(CountryCodes.getCountryCode("  "))
        assertNull(CountryCodes.getCountryCode("Atlantis"))
    }

    @Test
    fun normalizeCodeKeepsWhatItCannotResolve() {
        assertEquals("FR", CountryCodes.normalizeCode("France"))
        assertEquals("FR", CountryCodes.normalizeCode("fr"))
        assertEquals("ATLANTIS", CountryCodes.normalizeCode(" atlantis "))
    }
}
