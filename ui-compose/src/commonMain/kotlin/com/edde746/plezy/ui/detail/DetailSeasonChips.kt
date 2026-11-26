package com.edde746.plezy.ui.detail

import com.edde746.plezy.ui.components.ArtworkPlaceholder
import com.edde746.plezy.presentation.browse.PlaceholderKind
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.focus.FocusEnterExitScope
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.detail.MediaDetailUiState
import com.edde746.plezy.presentation.detail.SeasonTabUi
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.components.PlezySurface
import com.edde746.plezy.ui.components.menuGestures
import com.edde746.plezy.ui.components.widestLook
import com.edde746.plezy.ui.focus.FocusMemory
import com.edde746.plezy.ui.focus.rememberFocus
import com.edde746.plezy.ui.focus.tvRow
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.image.RemoteImage
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.flow.first
import kotlin.math.roundToInt

/**
 * A show's seasons as a row of chips (`detail.season.<i>`; harness name of the row `detail.seasons`) on every layout:
 * the TV page, the one-column page and the episodes' column beside the details. The row opens with the selected
 * season's chip in view, its first name at [nameStart] from the row's start edge. A chip selects its season: off TV a
 * tap, a click or Select, and Left and Right on a focused chip move to the neighbour and select it; on TV (a D-pad) as
 * focus moves onto it, so the next season is one Right, and a move into the row from above or below lands on the
 * selected chip ([tvRow]), Up going where [up] puts focus. Each season's menu (a long press, a held Select, a right
 * click, the Menu key) is its media menu ([onMenu]: mark watched or unwatched, download, delete). With the setting
 * ([MediaDetailUiState.seasonPosters], never on TV) each chip shows its season's poster over its name.
 */
@Composable
internal fun SeasonChips(
    state: MediaDetailUiState,
    focus: FocusMemory,
    onSelect: (Int) -> Unit,
    onMenu: (String) -> Unit,
    nameStart: Dp,
    modifier: Modifier = Modifier,
    up: (FocusEnterExitScope.() -> Unit)? = null,
) {
    val seasons = state.seasons
    if (seasons.isEmpty()) return
    val selected = state.selectedSeason
    val list = rememberLazyListState()
    LaunchedEffect(Unit) { list.showWhole(selected) }
    LazyRow(
        state = list,
        modifier = modifier
            .fillMaxWidth()
            .layoutProbe("detail.seasons", reportsFocus = false)
            .tvRow(up = up) { focus.focus(seasonFocusKey(seasons[state.selectedSeason].id)) },
        contentPadding = PaddingValues(horizontal = nameStart - ChipInset, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        itemsIndexed(seasons, key = { _, season -> season.id }) { index, season ->
            SeasonChip(
                season,
                index,
                selected = index == selected,
                poster = state.seasonPosters,
                onSelect = { if (index != state.selectedSeason) onSelect(index) },
                onMenu = { onMenu(season.id) },
                modifier = Modifier
                    .rememberFocus(focus, seasonFocusKey(season.id))
                    .layoutProbe("detail.season.$index"),
            )
        }
    }
}

/** The focus key of the season chip [seasonId]. */
internal fun seasonFocusKey(seasonId: String): String = "season:$seasonId"

/** Scrolls the row to show item [index] whole, once the row has its first layout, where it doesn't already. */
private suspend fun LazyListState.showWhole(index: Int) {
    val info = snapshotFlow { layoutInfo }.first { it.totalItemsCount > 0 }
    val shown = info.visibleItemsInfo.firstOrNull { it.index == index }
    if (shown == null || shown.offset + shown.size > info.viewportEndOffset) scrollToItem(index)
}

/**
 * A season's chip, as tvOS draws its tabs over a picture: no fill at rest, the primary fill while it has focus (no
 * growth, no ring: the row keeps one height); hover and press tint it. The selected one's name is in the content colour
 * and SemiBold, the others' at [UNSELECTED_ALPHA] and Regular, each as wide as the wider of the two, so a pick moves no
 * chip of the row; a check marks a watched season and a ring of its watched share ([SeasonRing]) a partly watched one,
 * in the check's place and size, which screen readers hear as its state ("watched", "33 percent watched"). With
 * [poster] the season's poster sits over the name. [onSelect] runs on a tap, a click or Select, and with
 * [selectsOnFocus] (TV) as focus moves onto it; [onMenu] is its menu. [index] names its check and ring
 * (`detail.season.<index>.check`, `.progress`).
 */
@Composable
private fun SeasonChip(
    season: SeasonTabUi,
    index: Int,
    selected: Boolean,
    poster: Boolean,
    onSelect: () -> Unit,
    onMenu: () -> Unit,
    modifier: Modifier,
) {
    val art = season.poster.takeIf { poster }
    val progress = season.progress
    var focused by remember { mutableStateOf(false) }
    val state = when {
        season.watched -> T.accessibility.mediaCardWatched
        progress != null -> T.accessibility.mediaCardPartiallyWatched(percent = (progress * 100).roundToInt().toString())
        else -> null
    }
    PlezySurface(
        onClick = onSelect,
        modifier = modifier
            .menuGestures(onMenu)
            .heightIn(min = LocalPlezyDimens.current.chipHeight)
            .onFocusChanged {
                focused = it.isFocused
                if (it.isFocused) onSelect()
            }
            .then(if (state != null) Modifier.semantics { stateDescription = state } else Modifier),
        shape = if (art != null) MaterialTheme.shapes.medium else CircleShape,
        color = Color.Transparent,
        role = Role.Tab,
        selected = selected,
        onLongClick = onMenu,
        contentAlignment = Alignment.Center,
        grows = false,
    ) {
        val content = if (selected) LocalContentColor.current else LocalContentColor.current.copy(alpha = UNSELECTED_ALPHA)
        val style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Normal)
        val selectedStyle = style.copy(fontWeight = FontWeight.SemiBold)
        val measurer = rememberTextMeasurer()
        Column(Modifier.padding(horizontal = ChipInset, vertical = 4.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            if (art != null) {
                RemoteImage(
                    art,
                    contentDescription = null,
                    modifier = Modifier.padding(top = 4.dp, bottom = 6.dp).size(72.dp, 108.dp).clip(ThumbnailShape),
                    blank = PlezyColors.SurfaceHigh,
                    error = { ArtworkPlaceholder(PlaceholderKind.SHOW) },
                )
            }
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically) {
                if (season.watched) {
                    Icon(PlezyIcons.Check, contentDescription = null, Modifier.size(18.dp).testTag("detail.season.$index.check"), tint = content)
                } else if (progress != null) {
                    // The accent; on a focused chip, whose fill is the accent (a keyboard's focus) or the text colour (TV),
                    // the fill's own content colour.
                    val arc = if (focused) LocalContentColor.current else PlezyColors.Primary
                    SeasonRing(
                        progress.toFloat(),
                        arc.copy(alpha = content.alpha),
                        LocalContentColor.current.copy(alpha = RING_TRACK_ALPHA),
                        Modifier.size(18.dp).testTag("detail.season.$index.progress"),
                    )
                }
                Text(
                    season.title,
                    Modifier.widthIn(max = ChipMaxWidth).widestLook(measurer, season.title, style, 0, selectedStyle, 0),
                    style = if (selected) selectedStyle else style,
                    color = content,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}

/**
 * How much of a season is watched, as a ring the size of the watched check: [fraction] of it in [color] clockwise from
 * the top (counter-clockwise right to left) over a full [track].
 */
@Composable
private fun SeasonRing(fraction: Float, color: Color, track: Color, modifier: Modifier) {
    Spacer(
        modifier.drawBehind {
            val stroke = 2.dp.toPx()
            val inset = 2.dp.toPx() + stroke / 2
            val arc = Size(size.width - inset * 2, size.height - inset * 2)
            val topLeft = Offset(inset, inset)
            drawArc(track, 0f, 360f, useCenter = false, topLeft = topLeft, size = arc, style = Stroke(stroke))
            val sweep = 360f * fraction.coerceIn(0f, 1f) * if (layoutDirection == LayoutDirection.Rtl) -1 else 1
            drawArc(color, -90f, sweep, useCenter = false, topLeft = topLeft, size = arc, style = Stroke(stroke, cap = StrokeCap.Round))
        },
    )
}

/** How bright an unselected chip's name is: the selected name's 100 % and SemiBold set it apart. */
private const val UNSELECTED_ALPHA = 0.65f

/** How strong a season ring's track is against the chip's content colour. */
private const val RING_TRACK_ALPHA = 0.25f

/** How far a chip's focus fill reaches past its name; the first name lines up with what it sits over. */
private val ChipInset = 12.dp

/** The widest a chip's name gets before it is cut short. */
internal val ChipMaxWidth = 280.dp
