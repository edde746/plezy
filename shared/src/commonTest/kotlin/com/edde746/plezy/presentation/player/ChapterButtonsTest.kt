package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.Chapter
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** The previous and next chapter buttons name the chapter each seeks to from where the video is. */
class ChapterButtonsTest {
    private val chapters = listOf(Chapter("Opening", 0.0), Chapter("Part A", 90.0), Chapter("Credits", 540.0))

    @Test
    fun eachChapterButtonNamesTheChapterItSeeksTo() = playerTest {
        playing(position = 100.0, duration = 600.0)
        engineState { it.copy(chapters = chapters) }
        // Ten seconds into Part A: previous goes back to its start.
        assertEquals("Part A", state.previousChapterTitle)
        assertEquals("Credits", state.nextChapterTitle)
        dispatch(PlayerCommand.PreviousChapter)
        assertEquals(90.0, engine.seeks.last().first)

        // Just past its start, previous means the chapter before.
        position(91.0)
        assertEquals("Opening", state.previousChapterTitle)
        assertEquals("Credits", state.nextChapterTitle)

        // In the last chapter there is none to go to next.
        position(560.0)
        assertEquals("Credits", state.previousChapterTitle)
        assertNull(state.nextChapterTitle)
    }

    @Test
    fun beforeTheFirstChapterPreviousGoesToTheStartAndNamesNone() = playerTest {
        playing(position = 20.0, duration = 600.0)
        engineState { it.copy(chapters = chapters.drop(1)) }
        assertNull(state.previousChapterTitle)
        assertEquals("Part A", state.nextChapterTitle)
        dispatch(PlayerCommand.PreviousChapter)
        assertEquals(0.0, engine.seeks.last().first)
    }
}
