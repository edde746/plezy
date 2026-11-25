package com.edde746.plezy.ui.music

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.hasContentDescription
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.presentation.music.TrackRowUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.player.PlayerProbe
import com.edde746.plezy.ui.probe.LocalLayoutProbe
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals

/** The music queue's rows: the playing one marked, its title in line with the others'. */
@OptIn(ExperimentalTestApi::class)
class QueueRowLineTest {
    private val rows = listOf("Morning Tone", "High Whistle", "Fifth Above").mapIndexed { index, title ->
        TrackRowUi(index, "k$index", "g$index", title, "Plezy Test Artist", trackNumber = null, duration = "0:30", isFirst = index == 0, isLast = index == 2, dimmed = index == 0)
    }

    /** The playing row carries the now-playing mark, the others none, and its title starts where theirs do. */
    @Test
    fun thePlayingRowIsMarkedAndItsTitleStartsWhereTheOthersDo() = runComposeUiTest {
        val probe = PlayerProbe()
        setContent {
            CompositionLocalProvider(LocalLayoutProbe provides probe) {
                PlezyTheme {
                    Column {
                        rows.forEach { row -> Row(Modifier.semantics(mergeDescendants = true) {}) { QueueRowLine(row, playingRow = row.index == 1, playing = true) } }
                    }
                }
            }
        }
        val nowPlaying = hasContentDescription(T.player.nowPlaying)
        onNode(hasText("High Whistle")).assert(nowPlaying)
        onNode(hasText("Morning Tone")).assert(!nowPlaying)
        onNode(hasText("Fifth Above")).assert(!nowPlaying)
        runOnIdle {
            val starts = rows.map { probe.bounds.getValue("music.queue.title.${it.index}").left }
            assertEquals(1, starts.distinct().size, "the titles start at $starts")
        }
    }
}
