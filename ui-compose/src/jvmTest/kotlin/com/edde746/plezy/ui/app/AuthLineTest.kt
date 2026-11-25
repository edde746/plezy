package com.edde746.plezy.ui.app

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.toPixelMap
import androidx.compose.ui.test.assertIsNotFocused
import androidx.compose.ui.test.captureToImage
import androidx.compose.ui.test.getBoundsInRoot
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.ui.TvFrame
import com.edde746.plezy.presentation.navigation.AuthErrorBannerUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * The refusing servers' line: a refused account has no sign-in, a rejected token's row keeps it beside one, and on TV
 * its Sign in again rests filled.
 */
@OptIn(ExperimentalTestApi::class)
class AuthLineTest {
    private var banner by mutableStateOf(AuthErrorBannerUi(sessionExpired = null, accessDenied = T.connections.accessDeniedOne("denied")))
    private var signIns = 0

    @Test
    fun aRefusedAccountIsExplainedWithoutASignInThatCannotHelp() = runComposeUiTest {
        setContent { PlezyTheme { AuthLine(banner, { signIns++ }) } }
        onNodeWithText(T.connections.accessDeniedOne("denied"), substring = true).assertExists()
        onNodeWithText(T.connections.signInAgain).assertDoesNotExist()
    }

    @Test
    fun aRejectedTokenKeepsItsSignInBesideARefusedAccount() = runComposeUiTest {
        banner = banner.copy(sessionExpired = T.connections.sessionExpiredOne("expired"), signInAgain = true)
        setContent { PlezyTheme { AuthLine(banner, { signIns++ }) } }
        onNodeWithText(T.connections.sessionExpiredOne("expired"), substring = true).assertExists()
        onNodeWithText(T.connections.accessDeniedOne("denied"), substring = true).assertExists()
        onNodeWithText(T.connections.signInAgain).performClick()
        assertEquals(1, signIns)
    }

    @Test
    fun theOpenSignInIsNotOfferedAgain() = runComposeUiTest {
        banner = banner.copy(sessionExpired = T.connections.sessionExpiredOne("expired"), signInAgain = false)
        setContent { PlezyTheme { AuthLine(banner, { signIns++ }) } }
        onNodeWithText(T.connections.sessionExpiredOne("expired"), substring = true).assertExists()
        onNodeWithText(T.connections.signInAgain).assertDoesNotExist()
    }

    /** On TV, Sign in again at rest is a filled button on the line, not one more piece of the line's text. */
    @Test
    fun onTvSignInAgainRestsFilledOnTheLine() = runComposeUiTest {
        banner = banner.copy(sessionExpired = T.connections.sessionExpiredOne("expired"), accessDenied = null, signInAgain = true)
        setContent { TvFrame { AuthLine(banner, { signIns++ }) } }
        val button = onNodeWithText(T.connections.signInAgain).assertIsNotFocused().getBoundsInRoot()
        val pixels = onRoot().captureToImage().toPixelMap()
        fun at(x: Dp) = pixels[(x.value * density.density).roundToInt(), ((button.top + button.bottom).value / 2 * density.density).roundToInt()]
        val fill = at(button.left + 4.dp)
        val line = at(button.left - 4.dp)
        assertTrue(abs(fill.luminance() - line.luminance()) > 0.05f, "button $fill, line $line")
    }
}
