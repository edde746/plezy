package com.edde746.plezy.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Stable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusManager
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.InputMode
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEvent
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalInputModeManager
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.presentation.browse.HubIcon
import com.edde746.plezy.presentation.browse.HubUi
import com.edde746.plezy.presentation.browse.MediaCardUi
import com.edde746.plezy.presentation.browse.followFocus
import com.edde746.plezy.presentation.theme.Appearance
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.icons.PlezyIcons
import com.edde746.plezy.ui.probe.LocalPerfProbe
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.launch

/**
 * A hub as a [ShelfRow] of [PosterCard]s in the hub's shape: its title as the heading, the provider's total and the
 * server it comes from beside it. While the hub has more and [onViewAll] opens its View All, the heading ends in View
 * All ([ShelfHeadingAction]) for touch and the pointer, and the row ends in a [SeeAllCard] wherever a remote or the keyboard
 * moves focus (on TV, where the heading's link goes, and in keyboard mode on every other device), so the arrow keys
 * and Tab reach it as the next card. [cardModifier] goes on each card (its focus memory), [seeAllModifier] on the card
 * at the end; [onCardClick] and [onCardLongClick] are a card's press and long press. Focus follows a card as the hub's
 * cards change ([followFocus]). Harness names `hub.<id>`, its heading's link [viewAllProbe], its card
 * `<viewAllProbe>.card`.
 */
@Composable
fun HubRow(
    hub: HubUi,
    appearance: Appearance,
    modifier: Modifier = Modifier,
    state: LazyListState? = null,
    cardModifier: @Composable (MediaCardUi) -> Modifier = { Modifier },
    seeAllModifier: Modifier = Modifier,
    onCardClick: ((MediaCardUi) -> Unit)? = null,
    onCardLongClick: ((MediaCardUi) -> Unit)? = null,
    onViewAll: (() -> Unit)? = null,
) {
    val open = onViewAll?.takeIf { hub.more }
    val keys = LocalInputModeManager.current.inputMode == InputMode.Keyboard
    ShelfRow(
        title = hub.title,
        items = hub.items,
        key = { it.id },
        modifier = modifier.layoutProbe("hub.${hub.id}", reportsFocus = false),
        state = state ?: rememberLazyListState(),
        action = {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // The provider's total ("347 results").
                hub.totalResults?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.labelMedium,
                        color = PlezyColors.TextMuted,
                        maxLines = 1,
                        modifier = Modifier.padding(horizontal = 8.dp).layoutProbe("hub.totalResults"),
                    )
                }
                hub.serverName?.let {
                    Text(
                        it,
                        style = MaterialTheme.typography.labelMedium,
                        color = PlezyColors.TextMuted,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.padding(horizontal = 8.dp).layoutProbe("hub.${hub.id}.server"),
                    )
                }
                if (open != null && !appearance.tv) {
                    ShelfHeadingAction(T.common.viewAll, open, Modifier.layoutProbe(viewAllProbe(hub)), trailingIcon = PlezyIcons.ChevronRight)
                }
            }
        },
        end = if (open != null && (appearance.tv || keys)) ({ SeeAllCard(hub.shape, open, seeAllModifier.layoutProbe("${viewAllProbe(hub)}.card")) }) else null,
        follow = ::followFocus,
    ) { _, item ->
        PosterCard(
            item,
            onClick = onCardClick?.let { { it(item) } },
            modifier = cardModifier(item),
            shape = hub.shape,
            onLongClick = onCardLongClick?.let { { it(item) } },
        )
    }
}

/** The Material icon of a hub's kind (the TV rail's hub headings). */
val HubIcon.vector: ImageVector
    get() = when (this) {
        HubIcon.PLAY_CIRCLE -> PlezyIcons.PlayCircle
        HubIcon.TRENDING_UP -> PlezyIcons.TrendingUp
        HubIcon.WHATSHOT -> PlezyIcons.Whatshot
        HubIcon.CALENDAR_MONTH -> PlezyIcons.CalendarToday
        HubIcon.NEW_RELEASES -> PlezyIcons.NewReleases
        HubIcon.SCHEDULE -> PlezyIcons.Schedule
        HubIcon.STAR -> PlezyIcons.Star
        HubIcon.MILITARY_TECH -> PlezyIcons.MilitaryTech
        HubIcon.WARNING_AMBER -> PlezyIcons.WarningAmber
        HubIcon.MOOD -> PlezyIcons.Mood
        HubIcon.FLASH_ON -> PlezyIcons.FlashOn
        HubIcon.THEATER_COMEDY -> PlezyIcons.TheaterComedy
        HubIcon.AUTO_FIX_HIGH -> PlezyIcons.AutoFixHigh
        HubIcon.ROCKET_LAUNCH -> PlezyIcons.RocketLaunch
        HubIcon.NIGHTS_STAY -> PlezyIcons.NightsStay
        HubIcon.FAVORITE_BORDER -> PlezyIcons.FavoriteBorder
        HubIcon.EXPLORE -> PlezyIcons.Explore
        HubIcon.PLAYLIST_PLAY -> PlezyIcons.PlaylistPlay
        HubIcon.VISIBILITY_OFF -> PlezyIcons.VisibilityOff
        HubIcon.VISIBILITY -> PlezyIcons.Visibility
        HubIcon.TV -> PlezyIcons.Tv
        HubIcon.PERSON -> PlezyIcons.Person
        HubIcon.HISTORY -> PlezyIcons.History
        HubIcon.PLAY_ARROW -> PlezyIcons.PlayArrow
        HubIcon.THUMB_UP -> PlezyIcons.ThumbUp
        HubIcon.CATEGORY -> PlezyIcons.Category
        HubIcon.AUTO_AWESOME -> PlezyIcons.AutoAwesome
        HubIcon.BOOKMARK -> PlezyIcons.Bookmark
        HubIcon.EVENT_UPCOMING -> PlezyIcons.EventUpcoming
    }

/** The harness name of [hub]'s View All in its heading; its card at the row's end is `<this>.card`. */
internal fun viewAllProbe(hub: HubUi): String = "hub.${hub.id}.viewAll"

/** Whether this is Down's press (the arrow key, the D-pad, the number pad's). */
internal fun KeyEvent.isDown(): Boolean =
    type == KeyEventType.KeyDown && (key == Key.DirectionDown || key == Key.NumPadDirectionDown)

/**
 * Up and Down between the shelves of a lazy list ([state]'s), for the keyboard, the D-pad and the remote. Focus search
 * alone stops at the last shelf in view: a shelf below the screen isn't composed until it scrolls in, and a shelf's own
 * row doesn't look beyond its bounds vertically. A shelf wholly on screen takes focus at once; on TV ([onTv]) so does
 * one partly on screen, and the focused card's bring-into-view alone scrolls the list. Otherwise the list scrolls first
 * (Down: the current shelf to the top; Up: the shelf above to the top), then focus moves. Put [modifier] on the list
 * and [item] on each of its items.
 */
@Stable
internal class ShelfNavigation(
    private val state: LazyListState,
    private val focusManager: FocusManager,
    private val scope: CoroutineScope,
    private val onTv: Boolean,
) {
    /** The list item that holds focus; -1 before any has. */
    private var focused = -1

    /** The scroll a press launched, until it ends with its focus move. */
    private var scrolling: Job? = null

    // One modifier per index, so a shelf composed again with the same index gets an equal modifier and can skip.
    private val items = HashMap<Int, Modifier>()

    /** On the list item at [index] of the lazy list. */
    fun item(index: Int): Modifier = items.getOrPut(index) { Modifier.onFocusChanged { if (it.hasFocus) focused = index } }

    /** On the list. */
    val modifier: Modifier = Modifier.onKeyEvent(::onKey)

    private fun onKey(event: KeyEvent): Boolean {
        if (event.type != KeyEventType.KeyDown) return false
        val direction = when (event.key) {
            Key.DirectionDown, Key.NumPadDirectionDown -> FocusDirection.Down
            Key.DirectionUp, Key.NumPadDirectionUp -> FocusDirection.Up
            else -> return false
        }
        // A press while the list still scrolls for the last one (a held key's repeats) is dropped: a new scroll would
        // cancel that one, its focus move with it.
        if (scrolling?.isActive == true) return true
        val from = focused
        val target = if (direction == FocusDirection.Down) from + 1 else from - 1
        val layout = state.layoutInfo
        if (from < 0 || target !in 0 until layout.totalItemsCount) return false
        val shown = layout.visibleItemsInfo.firstOrNull { it.index == target }
        val whole = shown != null && shown.offset >= layout.viewportStartOffset && shown.offset + shown.size <= layout.viewportEndOffset
        if (whole || onTv && shown != null) return focusManager.moveFocus(direction)
        scrolling = scope.launch {
            state.animateScrollToItem(if (direction == FocusDirection.Down) from else target)
            focusManager.moveFocus(direction)
        }
        return true
    }
}

/**
 * The [ShelfNavigation] of [state]'s list. In a perf run ([LocalPerfProbe]) it marks `shelves.settled` each time the
 * list comes to rest after a scroll, with its first item and that item's offset in pixels (`first=`, `offset=`).
 */
@Composable
internal fun rememberShelfNavigation(state: LazyListState): ShelfNavigation {
    val focusManager = LocalFocusManager.current
    val scope = rememberCoroutineScope()
    val onTv = LocalWindowLayout.current.formFactor == FormFactor.TV
    val perf = LocalPerfProbe.current
    if (perf != null) {
        LaunchedEffect(state, perf) {
            snapshotFlow { state.isScrollInProgress }.drop(1).filter { !it }.collect {
                perf.mark("shelves.settled", "first=${state.firstVisibleItemIndex} offset=${state.firstVisibleItemScrollOffset}")
            }
        }
    }
    return remember(state, focusManager, scope, onTv) { ShelfNavigation(state, focusManager, scope, onTv) }
}
