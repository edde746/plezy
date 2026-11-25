package com.edde746.plezy.ui.player

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.v2.runComposeUiTest
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.player.StillWatchingState
import com.edde746.plezy.strings.T
import kotlin.test.Test

/** The player's messages that show on their own, on a phone: TalkBack speaks them wherever its focus is. */
@OptIn(ExperimentalTestApi::class)
class PlayerSpokenMessagesTest {
    /** The transient message (volume, speed, zoom) is spoken as it shows and as it changes. */
    @Test
    fun theTransientMessageIsSpokenAsItShowsAndChanges() = runComposeUiTest {
        var state by mutableStateOf(testPlayerState().copy(osd = T.player.osd.zoom("150%")))
        player(FormFactor.HANDHELD) { state }
        onNodeWithText(T.player.osd.zoom("150%")).assert(spoken)
        state = state.copy(osd = T.player.osd.zoom("200%"))
        onNodeWithText(T.player.osd.zoom("200%")).assert(spoken)
    }

    /** A failure's title and message are spoken as its panel shows. */
    @Test
    fun anErrorIsSpokenAsItShows() = runComposeUiTest {
        player(FormFactor.HANDHELD) { testPlayerState(error = testError()) }
        onNodeWithText("Can't play this stream").assert(spoken)
        onNodeWithText("The stream is no longer available.").assert(spoken)
    }

    /** The sleep timer's question is spoken as its card shows; its countdown, whose text changes every second, isn't. */
    @Test
    fun theSleepTimersQuestionIsSpokenButNotItsCountdown() = runComposeUiTest {
        val asking = StillWatchingState(countdown = "Pausing in 25 seconds", secondsLeft = 25, progress = 1f / 6)
        player(FormFactor.HANDHELD) { testPlayerState(stillWatching = asking) }
        onNodeWithText(T.player.stillWatching.title).assert(spoken)
        onNodeWithText("Pausing in 25 seconds").assert(SemanticsMatcher.keyNotDefined(SemanticsProperties.LiveRegion))
    }

    private val spoken = SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite)
}
