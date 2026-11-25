package com.edde746.plezy.ui.cast

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.style.TextAlign
import com.edde746.plezy.presentation.cast.CastPairingPrompt
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.ButtonStyle
import com.edde746.plezy.ui.components.ModalOverlay
import com.edde746.plezy.ui.components.OverlayActions
import com.edde746.plezy.ui.components.PlezyButton
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors

/**
 * The receiver's question as a sender asks to cast here: "Allow <device> to cast?" over everything (the player too; the
 * app's dialog: a card, on TV the panel docked along the right edge), the code the sender shows as well, what to check,
 * then Don't Allow and Allow, focused first. Only its buttons and
 * Back (which refuses) close it. Harness names `cast.prompt`, `cast.prompt.code`, `cast.prompt.allow`,
 * `cast.prompt.deny`.
 */
@Composable
fun CastPairingPromptDialog(prompt: CastPairingPrompt, onAllow: () -> Unit, onDeny: () -> Unit) {
    val allow = remember { FocusRequester() }
    ModalOverlay(prompt.title, onDismiss = onDeny, modifier = Modifier.layoutProbe("cast.prompt", reportsFocus = false), initialFocus = allow, dismissOnScrim = false) {
        PairingCode(prompt.code, Modifier.fillMaxWidth().layoutProbe("cast.prompt.code", reportsFocus = false))
        Text(prompt.message, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted, textAlign = TextAlign.Start)
        OverlayActions(primary = allow) {
            PlezyButton(T.cast.pairing.deny, onDeny, Modifier.layoutProbe("cast.prompt.deny"))
            PlezyButton(T.cast.pairing.allow, onAllow, Modifier.focusRequester(allow).layoutProbe("cast.prompt.allow"), style = ButtonStyle.PRIMARY)
        }
    }
}
