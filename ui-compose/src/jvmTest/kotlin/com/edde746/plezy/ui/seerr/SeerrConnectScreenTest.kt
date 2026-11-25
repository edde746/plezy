package com.edde746.plezy.ui.seerr

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeUiTest
import androidx.compose.ui.test.ExperimentalTestApi
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsFocused
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onFirst
import androidx.compose.ui.test.onRoot
import androidx.compose.ui.test.performKeyInput
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextInputSelection
import androidx.compose.ui.test.pressKey
import androidx.compose.ui.test.v2.runComposeUiTest
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.seerr.SeerrConnectStep
import com.edde746.plezy.presentation.seerr.SeerrConnectUiState
import com.edde746.plezy.presentation.seerr.SeerrCredentialForm
import com.edde746.plezy.presentation.seerr.SeerrCredentialKind
import com.edde746.plezy.presentation.seerr.SeerrSignInMethod
import com.edde746.plezy.ui.adaptive.AdaptiveLayout
import com.edde746.plezy.ui.components.OverlayHostBox
import com.edde746.plezy.ui.focus.LocalKeyboardWaitsForSelect
import com.edde746.plezy.ui.focus.arrowKeyFocus
import com.edde746.plezy.ui.theme.PlezyTheme
import kotlin.test.Test

/** The Seerr connect screen over states built here. */
@OptIn(ExperimentalTestApi::class)
class SeerrConnectScreenTest {
    private val calls = mutableListOf<String>()

    /** A text field, editable or not: a disabled one has no set-text action. */
    private val field = SemanticsMatcher.keyIsDefined(SemanticsProperties.EditableText)

    /** While a probe runs the address can't be edited; once it ends it can again. */
    @Test
    fun theAddressIsLockedWhileProbing() = runComposeUiTest {
        var busy by mutableStateOf(true)
        screen { state(SeerrConnectStep.Url("seerr.local", "URL", "https://", "helper", "Continue"), busy) }
        onAllNodes(field).onFirst().assertIsNotEnabled()
        busy = false
        onAllNodes(field).onFirst().assertIsEnabled()
    }

    /** While signing in neither the identifier nor the password can be edited. */
    @Test
    fun theCredentialsAreLockedWhileSigningIn() = runComposeUiTest {
        screen { state(signIn(form(SeerrCredentialKind.JELLYFIN, "sam", "secret")), busy = true) }
        val fields = onAllNodes(field)
        fields.assertCountEquals(2)
        fields[0].assertIsNotEnabled()
        fields[1].assertIsNotEnabled()
    }

    /** Opening another form empties the fields the old one had filled and focuses its identifier. */
    @Test
    fun anotherFormStartsEmptyAndFocused() = runComposeUiTest {
        var step by mutableStateOf(signIn(form(SeerrCredentialKind.JELLYFIN, "sam", "secret")))
        screen { state(step) }
        onAllNodesWithText("sam").assertCountEquals(1)
        step = signIn(form(SeerrCredentialKind.LOCAL, "", ""))
        onAllNodesWithText("sam").assertCountEquals(0)
        onAllNodes(field)[0].assertIsFocused()
    }

    /**
     * On an Android TV a remote passing over the password raises no keyboard: the field isn't editable until Select.
     * It is a password to accessibility, and its text offers no Cut or Copy.
     */
    @Test
    fun theTvPasswordWaitsForSelectAndOffersNoCopy() = runComposeUiTest {
        screen(FormFactor.TV) { state(signIn(form(SeerrCredentialKind.JELLYFIN, "", ""))) }
        onAllNodes(field)[0].assertIsFocused()
        onRoot().performKeyInput { pressKey(Key.DirectionDown) }
        val password = onAllNodes(field)[1]
        password.assertIsFocused()
        password.assert(SemanticsMatcher.expectValue(SemanticsProperties.IsEditable, false))
        onRoot().performKeyInput { pressKey(Key.DirectionCenter) }
        password.assert(SemanticsMatcher.expectValue(SemanticsProperties.IsEditable, true))
        password.assert(SemanticsMatcher.keyIsDefined(SemanticsProperties.Password))
        password.performTextInput("secret")
        password.performTextInputSelection(TextRange(0, 6))
        password.assert(SemanticsMatcher.keyNotDefined(SemanticsActions.CopyText))
        password.assert(SemanticsMatcher.keyNotDefined(SemanticsActions.CutText))
    }

    private fun state(step: SeerrConnectStep, busy: Boolean = false) =
        SeerrConnectUiState(title = "Connect Seerr", step = step, busy = busy, error = null, done = false)

    private fun signIn(form: SeerrCredentialForm) = SeerrConnectStep.SignIn(
        instanceLabel = "Seerr",
        baseUrl = "https://seerr.local",
        changeLabel = "Change",
        plexLabel = null,
        form = form,
        methods = listOf(SeerrSignInMethod(SeerrCredentialKind.LOCAL, "Local account")),
        noMethodsMessage = null,
    )

    private fun form(kind: SeerrCredentialKind, identifier: String, password: String) = SeerrCredentialForm(
        kind = kind,
        identifier = identifier,
        password = password,
        identifierLabel = "Username",
        identifierIsEmail = kind == SeerrCredentialKind.LOCAL,
        passwordLabel = "Password",
        identifierError = null,
        passwordError = null,
        signInLabel = "Sign in",
        quickConnectLabel = null,
    )

    /** The screen in a phone's window, or with [formFactor] TV an Android TV's, whose fields wait for Select. */
    private fun ComposeUiTest.screen(formFactor: FormFactor = FormFactor.HANDHELD, state: () -> SeerrConnectUiState) = setContent {
        CompositionLocalProvider(LocalKeyboardWaitsForSelect provides true) {
            PlezyTheme {
                Box(Modifier.size(DpSize(411.dp, 900.dp))) {
                    AdaptiveLayout(formFactor, Modifier.arrowKeyFocus()) {
                        OverlayHostBox { SeerrConnectContent(state(), intents(), onBack = { calls += "back" }) }
                    }
                }
            }
        }
    }

    private fun intents() = SeerrConnectIntents(
        setUrl = { calls += "url:$it" },
        probe = { calls += "probe" },
        changeServer = { calls += "change" },
        chooseForm = { calls += "form:$it" },
        signInWithPlex = { calls += "plex" },
        setIdentifier = { calls += "identifier:$it" },
        setPassword = { calls += "password:$it" },
        signIn = { calls += "signIn" },
        startQuickConnect = { calls += "quickConnect" },
        cancelQuickConnect = { calls += "cancelQuickConnect" },
    )
}
