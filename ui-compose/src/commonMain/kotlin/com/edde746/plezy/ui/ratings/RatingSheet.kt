package com.edde746.plezy.ui.ratings

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.LoadingIndicator
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.disabled
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.toggleableState
import androidx.compose.ui.state.ToggleableState
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.presentation.ratings.RatingRowKey
import com.edde746.plezy.presentation.ratings.RatingRowStatus
import com.edde746.plezy.presentation.ratings.RatingSheetStore
import com.edde746.plezy.presentation.ratings.ServerRatingRow
import com.edde746.plezy.presentation.ratings.TrackerRatingRow
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowSize
import com.edde746.plezy.ui.components.PlezySheet
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.TimedToast
import com.edde746.plezy.ui.components.RowGroup
import com.edde746.plezy.ui.components.groupShape
import com.edde746.plezy.ui.focus.isFocusVisible
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import kotlin.math.roundToInt

/**
 * The rating sheet of [store]'s item ("Rate" in its menu), a [PlezySheet] (on TV the side
 * panel): one group of rows, the server's (its [backend]'s mark; five stars in half steps, or a Favorite toggle where the
 * server keeps favourites only), then a row per connected tracker (its mark, name, account or, in the error colour, why
 * it can't rate), or a line saying to connect one. Each row shows a spinner while it reads or saves and a check once
 * saved. A tap or a drag along the stars sets the score and saves it as the finger lifts; a remote's or keyboard's Left
 * and Right move it a half star (saved once the keys rest) and Select saves it now (flips the favourite); Up and Down
 * move between rows, the first taking focus as the sheet opens. A failed save shows as a toast. The store is released
 * once the sheet is gone ([onDismiss] stops showing it), its pending saves still going out. Harness names:
 * `ratingSheet`, `ratingSheet.row.server`, `ratingSheet.row.<tracker id>`, `ratingSheet.toast`.
 */
@Composable
fun RatingSheet(store: RatingSheetStore, backend: BackendKind, onDismiss: () -> Unit) {
    val state by store.state.collectAsState()
    DisposableEffect(store) { onDispose { store.release() } }
    PlezySheet(onDismiss = onDismiss, title = state.title, probe = "ratingSheet") {
        Column(
            Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(vertical = 4.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            val count = (if (state.server != null) 1 else 0) + state.trackers.size
            RowGroup {
                state.server?.let { ServerRow(it, backend, store, groupShape(0, count)) }
                val offset = count - state.trackers.size
                state.trackers.forEachIndexed { index, row -> TrackerRow(row, store, groupShape(offset + index, count)) }
            }
            state.noConnectedServices?.let {
                Text(it, Modifier.padding(horizontal = 16.dp), style = MaterialTheme.typography.bodyMedium, color = PlezyColors.TextMuted)
            }
        }
        state.message?.let { TimedToast(it, "ratingSheet.toast", store::messageShown, Modifier.align(Alignment.CenterHorizontally)) }
    }
}

@Composable
private fun ServerRow(row: ServerRatingRow, backend: BackendKind, store: RatingSheetStore, shape: Shape) {
    val key = RatingRowKey.Server
    RatingRow(
        probe = "ratingSheet.row.server",
        shape = shape,
        leading = { BackendLogo(backend, size = 22.dp) },
        title = row.title,
        subtitle = row.subtitle,
        status = row.status,
        loading = row.loading,
        onStep = { store.step(key, it) },
        onSubmit = { store.submit(key) },
    ) {
        if (row.favoriteOnly) {
            FavoriteControl(row.favorite, enabled = !row.loading) { store.submit(key, if (row.favorite) 0 else 1) }
        } else {
            StarControl(row.value, enabled = !row.loading, onChange = { store.change(key, it) }, onSubmit = { store.submit(key, it) })
        }
    }
}

@Composable
private fun TrackerRow(row: TrackerRatingRow, store: RatingSheetStore, shape: Shape) {
    val key = RatingRowKey.Tracker(row.service)
    RatingRow(
        probe = "ratingSheet.row.${row.service.id}",
        shape = shape,
        leading = { TrackerLogo(row.service, size = 24.dp) },
        title = row.title,
        subtitle = row.subtitle,
        status = row.status,
        loading = row.loading,
        onStep = { store.step(key, it) },
        onSubmit = { store.submit(key) },
    ) {
        StarControl(row.value, enabled = !row.loading, onChange = { store.change(key, it) }, onSubmit = { store.submit(key, it) })
    }
}

/**
 * A row of the sheet's group, in [shape]: [leading] mark, [title] (then, right beside it, the spinner while [loading],
 * else [status]'s check or error mark, as on Apple) over [subtitle] (or an error [status]'s text in the error colour),
 * then the [control]. The row is the focus target: Left and Right [onStep] its control, Select [onSubmit]s it; focus
 * fills it (no growth: a row of a list).
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
private fun RatingRow(
    probe: String,
    shape: Shape,
    leading: @Composable () -> Unit,
    title: String,
    subtitle: String,
    status: RatingRowStatus?,
    loading: Boolean,
    onStep: (Int) -> Unit,
    onSubmit: () -> Unit,
    control: @Composable () -> Unit,
) {
    val narrow = LocalWindowSize.current.value.width < NarrowWindow
    PlezySurface(
        onClick = onSubmit,
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 56.dp)
            .onKeyEvent { event ->
                if (event.type != KeyEventType.KeyDown) return@onKeyEvent false
                when (event.key) {
                    Key.DirectionLeft -> onStep(-1)
                    Key.DirectionRight -> onStep(1)
                    else -> return@onKeyEvent false
                }
                true
            }
            .layoutProbe(probe),
        shape = shape,
        contentAlignment = Alignment.CenterStart,
        grows = false,
    ) {
        Row(Modifier.padding(start = 16.dp, end = 12.dp, top = 10.dp, bottom = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(24.dp), contentAlignment = Alignment.Center) { leading() }
            Spacer(Modifier.width(16.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        title,
                        Modifier.weight(1f, fill = false),
                        style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Medium),
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    if (loading || status != null) {
                        Spacer(Modifier.width(6.dp))
                        if (loading) {
                            LoadingIndicator(Modifier.size(16.dp), color = LocalContentColor.current)
                        } else if (status != null) {
                            Icon(
                                if (status.isError) PlezyIcons.Error else RatingGlyphs.CheckCircle,
                                contentDescription = status.text,
                                Modifier.size(16.dp),
                                tint = if (status.isError) PlezyColors.Error else LocalContentColor.current,
                            )
                        }
                    }
                }
                val error = status?.takeIf { it.isError }
                Text(
                    error?.text ?: subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = if (error != null) PlezyColors.Error else PlezyColors.MutedContent,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Spacer(Modifier.width(8.dp))
            Box(Modifier.width(if (narrow) 124.dp else 142.dp)) { control() }
        }
    }
}

/**
 * Five stars at the control's end, each half a point of [value] (0–10): lit in the row's content colour up to it (half
 * a star at an odd value), the rest a dim solid fill. A press sets the score at the finger ([starValueAt] across the
 * whole control) and so does each move of a drag ([onChange]); the release saves the last one ([onSubmit]).
 */
@Composable
private fun StarControl(value: Int, enabled: Boolean, onChange: (Int) -> Unit, onSubmit: (Int) -> Unit) {
    val change by rememberUpdatedState(onChange)
    val submit by rememberUpdatedState(onSubmit)
    BoxWithConstraints(
        Modifier
            .fillMaxWidth()
            .height(34.dp)
            .pointerInput(enabled) {
                if (!enabled) return@pointerInput
                awaitEachGesture {
                    val down = awaitFirstDown()
                    down.consume()
                    var score = starValueAt(down.position.x, size.width.toFloat())
                    change(score)
                    while (true) {
                        val event = awaitPointerEvent()
                        val pointer = event.changes.firstOrNull { it.id == down.id } ?: break
                        if (!pointer.pressed) {
                            pointer.consume()
                            break
                        }
                        val next = starValueAt(pointer.position.x, size.width.toFloat())
                        pointer.consume()
                        if (next != score) {
                            score = next
                            change(score)
                        }
                    }
                    submit(score)
                }
            },
    ) {
        val starWidth = minOf(maxWidth / 5, 27.dp)
        val iconSize: Dp = minOf(starWidth * 0.9f, 24.dp)
        val lit = LocalContentColor.current
        val dim = lit.copy(alpha = 0.2f)
        Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
            for (star in 1..5) {
                val threshold = star * 2
                val fill = when {
                    value >= threshold -> 1f
                    value == threshold - 1 -> 0.5f
                    else -> 0f
                }
                Box(Modifier.width(starWidth), contentAlignment = Alignment.Center) {
                    Icon(PlezyIcons.Star, contentDescription = null, Modifier.size(iconSize), tint = dim)
                    if (fill > 0f) {
                        Icon(
                            PlezyIcons.Star,
                            contentDescription = null,
                            Modifier.size(iconSize).drawWithContent {
                                val edge = size.width * fill
                                if (layoutDirection == LayoutDirection.Rtl) {
                                    clipRect(left = size.width - edge) { this@drawWithContent.drawContent() }
                                } else {
                                    clipRect(right = edge) { this@drawWithContent.drawContent() }
                                }
                            },
                            tint = lit,
                        )
                    }
                }
            }
        }
    }
}

/**
 * A heart at the row's end, where the stars end, red and filled while [favorite], in a 48 dp touch target; a tap
 * [onToggle]s it. The heart has no label (as on iOS); a screen reader reads "Favorite" or "Favorited" and the toggle state.
 */
@Composable
private fun FavoriteControl(favorite: Boolean, enabled: Boolean, onToggle: () -> Unit) {
    val toggle by rememberUpdatedState(onToggle)
    val label = if (favorite) T.rateSheet.favorited else T.rateSheet.favorite
    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.CenterEnd) {
        Box(
            Modifier
                // The target runs past the control into the row's end padding, so the heart centres where the last star does.
                .offset(x = 11.dp)
                .size(48.dp)
                .pointerInput(enabled) { if (enabled) detectTapGestures { toggle() } }
                .semantics(mergeDescendants = true) {
                    contentDescription = label
                    role = Role.Switch
                    toggleableState = ToggleableState(favorite)
                    if (enabled) onClick { toggle(); true } else disabled()
                },
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                if (favorite) RatingGlyphs.Favorite else PlezyIcons.FavoriteBorder,
                contentDescription = null,
                Modifier.size(24.dp),
                tint = when {
                    favorite -> FavoriteRed
                    enabled -> PlezyColors.MutedContent
                    else -> PlezyColors.TextFaint
                },
            )
        }
    }
}

/** The score (0–10) at [x] across a star control [width] wide: its share of the width in half stars, rounded. */
internal fun starValueAt(x: Float, width: Float): Int {
    val span = if (width <= 0f) 1f else width
    return (x.coerceIn(0f, span) / span * 10).roundToInt().coerceIn(0, 10)
}

/** Below this window width the rows' controls narrow, leaving their names room on a small phone. */
private val NarrowWindow = 390.dp

/** The heart of a favourite. */
internal val FavoriteRed = Color(0xFFFF5252)
