package com.edde746.plezy.presentation.settings

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Where a row shows its value: beside the title while it is short, else under it over the caption, never twice. */
class SettingValueRowTest {
    private fun choice(value: String, caption: String? = "What it does") =
        SettingChoiceRow("id", "Title", caption, listOf(SettingChoiceOption("a", value, selected = true)))

    @Test
    fun aShortValueSitsBesideTheTitleAndTheCaptionAlone() {
        val row = choice("Show button")
        assertEquals("Show button", row.trailingValue)
        assertEquals("What it does", row.subtitle)
    }

    @Test
    fun aLongerValueMovesUnderTheTitleAboveTheCaption() {
        val row = choice("Open Details")
        assertNull(row.trailingValue)
        assertEquals("Open Details\nWhat it does", row.subtitle)
    }

    @Test
    fun aLongValueWithoutACaptionIsTheWholeSubtitle() {
        val row = SettingLinkRow("id", "External Player", caption = null, valueLabel = "VLC media player")
        assertNull(row.trailingValue)
        assertEquals("VLC media player", row.subtitle)
    }

    @Test
    fun noValueLeavesTheCaption() {
        val link = SettingLinkRow("id", "About", caption = "Version 1")
        assertNull(link.trailingValue)
        assertEquals("Version 1", link.subtitle)
        val empty = SettingTextRow("id", "Relay", null, value = "", fieldLabel = "", hint = "", resetLabel = null)
        assertNull(empty.trailingValue)
        assertNull(empty.subtitle)
    }

    @Test
    fun theLimitIsElevenCharacters() {
        assertEquals("x".repeat(SHORT_VALUE_LENGTH), choice("x".repeat(SHORT_VALUE_LENGTH)).trailingValue)
        assertNull(choice("x".repeat(SHORT_VALUE_LENGTH + 1)).trailingValue)
        assertEquals(11, SHORT_VALUE_LENGTH)
    }

    @Test
    fun anUnselectedChoiceShowsItsPlaceholder() {
        val row = SettingChoiceRow("id", "Title", null, listOf(SettingChoiceOption("a", "A", selected = false)), unselectedLabel = "Default")
        assertEquals("Default", row.trailingValue)
        assertNull(row.subtitle)
    }
}
