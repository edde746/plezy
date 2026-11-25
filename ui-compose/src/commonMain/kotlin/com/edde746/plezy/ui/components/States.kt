package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalAccessibilityManager
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import androidx.compose.foundation.clickable
import androidx.compose.ui.input.pointer.PointerIcon
import androidx.compose.ui.input.pointer.pointerHoverIcon
import com.edde746.plezy.ui.focus.desktopApp
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.delay

/** Content is on its way: Material's (Expressive) loading indicator. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun LoadingState(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxSize().padding(LocalPlezyDimens.current.screenPadding), contentAlignment = Alignment.Center) {
        LoadingIndicator(Modifier.size(64.dp))
    }
}

/**
 * Something failed: [message] (worded by the store) and, with [onRetry], a retry button that takes focus so a remote
 * user can act at once.
 */
@Composable
fun ErrorState(
    message: String,
    modifier: Modifier = Modifier,
    title: String? = null,
    onRetry: (() -> Unit)? = null,
    retryLabel: String = T.nav.retry,
) {
    val retryFocus = remember { FocusRequester() }
    MessageState(icon = PlezyIcons.ErrorOutline, title = title, message = message, modifier = modifier) {
        if (onRetry != null) {
            PlezyButton(retryLabel, onRetry, Modifier.focusRequester(retryFocus), style = ButtonStyle.PRIMARY, icon = PlezyIcons.Refresh)
            LaunchedEffect(Unit) { retryFocus.requestFocus() }
        }
    }
}

/** Nothing to show: [message] (from the store; [title] over it) under [icon]; [action] for what the user can do about it. */
@Composable
fun EmptyState(
    message: String,
    modifier: Modifier = Modifier,
    title: String? = null,
    icon: ImageVector = PlezyIcons.Movie,
    action: (@Composable () -> Unit)? = null,
) {
    MessageState(icon = icon, title = title, message = message, modifier = modifier) { action?.invoke() }
}

/** Why an input wasn't taken, under the field it belongs to. TalkBack speaks it as it shows and as it changes. */
@Composable
fun InlineError(text: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(PlezyIcons.ErrorOutline, contentDescription = null, Modifier.size(18.dp), tint = PlezyColors.Error)
        Text(text, Modifier.semantics { liveRegion = LiveRegionMode.Polite }, style = MaterialTheme.typography.bodyMedium, color = PlezyColors.Error)
    }
}

/**
 * A store's one-off message at the bottom of a screen ("Sam joined", "Added to Downloads"; [probe] names it for the
 * harness) for [TOAST_MILLIS] ([ERROR_TOAST_MILLIS] for an [isError] one, long enough to read why), or for the longer
 * time the user's accessibility setting asks for (Android's "Time to take action"), then [onShown] (the store's
 * dismiss): a message the store keeps until told it was shown. A new [text] shows for the whole time again. On the
 * desktop a click dismisses it. TalkBack speaks the text as it shows and as it changes, wherever its focus is. An
 * [isError] message ("You can no longer request") is drawn on the error colour.
 */
@Composable
fun TimedToast(text: String, probe: String, onShown: () -> Unit, modifier: Modifier = Modifier, isError: Boolean = false) {
    val shown by rememberUpdatedState(onShown)
    val accessibility = LocalAccessibilityManager.current
    val millis = if (isError) ERROR_TOAST_MILLIS else TOAST_MILLIS
    LaunchedEffect(text) {
        delay(accessibility?.calculateRecommendedTimeoutMillis(millis, containsText = true) ?: millis)
        shown()
    }
    val dismiss = if (desktopApp) Modifier.pointerHoverIcon(PointerIcon.Hand).clickable(interactionSource = null, indication = null) { shown() } else Modifier
    Surface(
        modifier.layoutProbe(probe).then(dismiss),
        shape = MaterialTheme.shapes.extraLarge,
        color = if (isError) PlezyColors.Error else PlezyColors.SurfaceHighest,
        contentColor = if (isError) MaterialTheme.colorScheme.onError else PlezyColors.Text,
    ) {
        Text(
            text,
            Modifier.semantics { liveRegion = LiveRegionMode.Polite }.padding(horizontal = 18.dp, vertical = 10.dp),
            style = MaterialTheme.typography.bodyLarge,
        )
    }
}

/** How long a [TimedToast] shows unless the user's accessibility setting asks for longer. */
const val TOAST_MILLIS = 3_000L

/** How long an error's [TimedToast] shows unless the user's accessibility setting asks for longer. */
const val ERROR_TOAST_MILLIS = 4_000L

@Composable
private fun MessageState(
    icon: ImageVector,
    title: String?,
    message: String,
    modifier: Modifier,
    actions: @Composable () -> Unit,
) {
    Box(modifier.fillMaxSize().padding(LocalPlezyDimens.current.screenPadding), contentAlignment = Alignment.Center) {
        Column(
            Modifier.widthIn(max = 480.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(icon, contentDescription = null, Modifier.size(48.dp), tint = PlezyColors.TextFaint)
            if (title != null) Text(title, style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
            Text(
                message,
                style = MaterialTheme.typography.bodyLarge,
                color = PlezyColors.TextMuted,
                textAlign = TextAlign.Center,
            )
            actions()
        }
    }
}
