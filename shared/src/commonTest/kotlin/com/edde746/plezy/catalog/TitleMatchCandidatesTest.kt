package com.edde746.plezy.catalog

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class TitleMatchCandidatesTest {
    @Test
    fun dropsEverySequelSuffixShapeSeenOnMalAndAniList() {
        val cases = mapOf(
            "You and I Are Polar Opposites Season 2" to "You and I Are Polar Opposites",
            "Mushoku Tensei: Jobless Reincarnation Season 2" to "Mushoku Tensei: Jobless Reincarnation",
            "[Oshi no Ko] 2nd Season" to "[Oshi no Ko]",
            "The Duke of Death and His Maid 3rd Season" to "The Duke of Death and His Maid",
            "My Hero Academia FINAL SEASON" to "My Hero Academia",
            "Dr. STONE: SCIENCE FUTURE Part 2" to "Dr. STONE: SCIENCE FUTURE",
            "Dr. STONE SCIENCE FUTURE Cour 2" to "Dr. STONE SCIENCE FUTURE",
            "Unnamed Memory Act.2" to "Unnamed Memory",
            "Kekkon Yubiwa Monogatari II" to "Kekkon Yubiwa Monogatari",
            "Isekai Quartet 3" to "Isekai Quartet",
        )
        for ((title, expected) in cases) assertEquals(expected, stripSeasonSuffix(title), title)
    }

    @Test
    fun collapsesStackedSuffixesInOnePass() {
        assertEquals("Mushoku Tensei: Jobless Reincarnation", stripSeasonSuffix("Mushoku Tensei: Jobless Reincarnation Season 2 Part 2"))
        assertEquals("JUJUTSU KAISEN", stripSeasonSuffix("JUJUTSU KAISEN Season 3: The Culling Game Part 1"))
        assertEquals("Solo Leveling", stripSeasonSuffix("Solo Leveling Season 2 -Arise from the Shadow-"))
        assertEquals("Classroom of the Elite", stripSeasonSuffix("Classroom of the Elite 4th Season: Second Year, First Semester"))
    }

    @Test
    fun aTitleWithoutASequelSuffixStripsToNull() {
        assertNull(stripSeasonSuffix("Frieren: Beyond Journey's End"))
        assertNull(stripSeasonSuffix("Cowboy Bebop"))
        // Stripping must not consume the whole title.
        assertNull(stripSeasonSuffix("86"))
    }

    @Test
    fun aTrailingNumberThatIsPartOfTheNameStays() {
        assertNull(stripSeasonSuffix("Kaiju No. 8"))
        assertEquals("Mob Psycho", stripSeasonSuffix("Mob Psycho 100"))
        assertNull(stripSeasonSuffix("Vol. 3"))
    }

    @Test
    fun eachTitleIsImmediatelyFollowedByItsStrippedForm() {
        assertEquals(
            listOf(
                "You and I Are Polar Opposites Season 2",
                "You and I Are Polar Opposites",
                "Seihantai na Kimi to Boku 2nd Season",
                "Seihantai na Kimi to Boku",
            ),
            titleMatchCandidates(listOf("You and I Are Polar Opposites Season 2", "Seihantai na Kimi to Boku 2nd Season")),
        )
    }

    @Test
    fun aNarrowerCapInterleavesRatherThanListingRawTitlesFirst() {
        assertEquals(
            listOf("You and I Are Polar Opposites Season 2", "You and I Are Polar Opposites"),
            titleMatchCandidates(listOf("You and I Are Polar Opposites Season 2", "Seihantai na Kimi to Boku 2nd Season"), limit = 2),
        )
    }

    @Test
    fun typographicPunctuationBothBackendsMissOnIsNormalized() {
        assertEquals(listOf("Frieren: Beyond Journey's End"), titleMatchCandidates(listOf("Frieren: Beyond Journey\u2019s End")))
        assertEquals(listOf("Kaguya-sama - Love is War"), titleMatchCandidates(listOf("Kaguya-sama \u2013 Love is War")))
    }

    @Test
    fun nullsBlanksAndCaseInsensitiveDuplicatesAreDropped() {
        assertEquals(
            listOf("Bocchi the Rock!"),
            titleMatchCandidates(listOf("Bocchi the Rock!", null, "   ", "BOCCHI THE ROCK!", "Bocchi the Rock!")),
        )
    }

    @Test
    fun aStrippedFormDuplicatingAProviderTitleIsNotRepeated() {
        assertEquals(listOf("Kaiju No. 8 Season 2", "Kaiju No. 8"), titleMatchCandidates(listOf("Kaiju No. 8 Season 2", "Kaiju No. 8")))
    }

    @Test
    fun thePreferredTitlesStrippedFormSurvivesALongAliasList() {
        // `II:` mid-title is not a sequel suffix, so the second family has no stripped form and the third title takes
        // the last slot.
        assertEquals(
            listOf(
                "Mushoku Tensei: Jobless Reincarnation Season 2",
                "Mushoku Tensei: Jobless Reincarnation",
                "Mushoku Tensei II: Isekai Ittara Honki Dasu",
                "Mushoku Tensei 2",
            ),
            titleMatchCandidates(
                listOf(
                    "Mushoku Tensei: Jobless Reincarnation Season 2",
                    "Mushoku Tensei II: Isekai Ittara Honki Dasu",
                    "Mushoku Tensei 2",
                    "MT2",
                ),
            ),
        )
    }
}
