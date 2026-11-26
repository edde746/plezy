package com.edde746.plezy.ui.components

import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.width
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
import androidx.compose.ui.draw.clip
import androidx.compose.ui.semantics.Role
import com.edde746.plezy.presentation.layout.CardShape
import com.edde746.plezy.presentation.browse.FocusFollow
import com.edde746.plezy.presentation.browse.followFocus
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.focus.focusRing
import com.edde746.plezy.ui.icons.PlezyIcons
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyItemScope
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.runtime.withFrameNanos
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.ui.adaptive.LocalWindowLayout
import com.edde746.plezy.ui.focus.DirectionalMoves
import com.edde746.plezy.ui.focus.focusReach
import com.edde746.plezy.ui.navigation.clipToNavigation
import com.edde746.plezy.ui.navigation.rememberNavigationClearance
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.ui.platform.LocalLayoutDirection
import com.edde746.plezy.ui.theme.LocalPlezyDimens
import com.edde746.plezy.ui.theme.PlezyColors
import com.edde746.plezy.ui.theme.PlezyDimens
import kotlinx.coroutines.flow.distinctUntilChanged

/**
 * A titled, horizontally scrolling row of cards (a catalog on the Board, Continue Watching, a search result group):
 * the heading ([SectionTitle], at the foot of a row [HeaderHeight] tall, taller where a large font's line needs it),
 * [LocalPlezyDimens]' `shelfHeaderGap` and the cards: the heading sits on its row, the gap between shelves above it. The
 * row's content padding holds the focused card's growth (TV) at its ends and bottom, so nothing clips it; lists of
 * shelves space them with `sectionSpacing` less that bottom room ([shelfSpacing]).
 *
 * Keyboard, D-pad and remote: left/right move between cards (right on the last card stays there) and the row scrolls to
 * keep the focused card in view; a mouse scrolls it on the desktop ([ScrollRow]);
 * moving into the row from above or below lands on the card that had focus last, else, on TV, the first, not the card
 * under the focus, which the cards' widths, their count and the row's scroll would decide (the first Down from Search's
 * field). Elsewhere it lands on the card under the focus: the heading's See all sits at the row's right end, and Down
 * from it to the first card would leave Up no way back to it. Compose's memory of a group's focused element
 * ([focusEntry][com.edde746.plezy.ui.focus.focusEntry]) gave the first card in a lazy row, so the row keeps the card
 * itself ([ShelfFocus.enter]). The row spans the shelf's width whatever its cards: Compose's Up and Down pick between
 * rows by their middles, so a row of one card, as wide as the card, would win over a full-width row nearer the focus
 * (Home's shortcuts under a Continue Watching of one card). A focused card that leaves the row (Continue Watching's,
 * watched to its end) hands focus to the card that takes its place, or at the row's end to the card before it, the
 * screen around it waiting meanwhile ([com.edde746.plezy.ui.focus.focusHome]): focus is never left on nothing, where
 * the remote does nothing. With [follow] focus follows the card instead where [follow] finds it ([followFocus]: the
 * played card Continue Watching moved to the front, the next episode that replaced a finished one, even a change
 * later), brought into view; the card the row remembers for focus coming back follows it too.
 * [state] is saveable, so the row keeps its scroll position across navigation; hoist it to keep it across the row
 * leaving the screen's list.
 *
 * @param title the row's heading (the catalog name, preformatted by the store).
 * @param action a trailing element in the heading ("See all").
 * @param onNearEnd the row's end came into view (its last [SHELF_LOAD_AHEAD] cards), or the items changed while it is in
 *   view: the row's next page, where it pages (the store ignores the call otherwise). After a page that fails, it comes
 *   again once the end leaves the view and comes back.
 * @param end an element after the last card (Home's See all card on a remote's UI).
 * @param header the row's heading in place of [title]'s ([title] still names the row).
 * @param contentPadding the cards' padding inside the row, in place of the screen's padding and the focus room.
 * @param spacing between cards, in place of the gutter.
 * @param follow where focus follows when the items change: the place of the card it was on, or of the card replacing
 *   it ([followFocus]).
 */
@Composable
fun <T> ShelfRow(
    title: String,
    items: List<T>,
    key: (T) -> Any,
    modifier: Modifier = Modifier,
    state: LazyListState = rememberLazyListState(),
    action: (@Composable () -> Unit)? = null,
    onNearEnd: (() -> Unit)? = null,
    end: (@Composable () -> Unit)? = null,
    header: (@Composable () -> Unit)? = null,
    contentPadding: PaddingValues? = null,
    spacing: Dp? = null,
    follow: ((items: List<T>, focused: T?, displaced: T?) -> FocusFollow<T>)? = null,
    itemContent: @Composable LazyItemScope.(index: Int, item: T) -> Unit,
) {
    val dimens = LocalPlezyDimens.current
    val forward = if (LocalLayoutDirection.current == LayoutDirection.Ltr) FocusDirection.Right else FocusDirection.Left
    val focus = remember { ShelfFocus<T>() }
    // The surfaces around the row wait while it hands focus on (FocusHome), rather than take the drop meanwhile.
    val appFocus = LocalOverlayHost.current?.appFocus
    val entry = if (LocalWindowLayout.current.formFactor == FormFactor.TV) items.firstOrNull()?.let(key) else null
    // Before the change is applied, while the row still holds focus: the card focus follows, else the card taking the
    // place of the focused card the items left. Kept once the change is applied, so a composition Compose drops leaves
    // no hand-off behind.
    val gone = focus.key
    val changed = items !== focus.items
    val previous = if (changed && gone != null) focus.items.indexOfFirst { key(it) == gone } else -1
    val followed = if (changed && follow != null) follow(items, focus.items.getOrNull(previous), focus.displaced) else null
    val target = when {
        followed != null && followed.index >= 0 -> key(items[followed.index]).takeIf { followed.index != previous || it != gone }
        changed && gone != null && previous >= 0 && items.isNotEmpty() && items.none { key(it) == gone } -> key(items[previous.coerceAtMost(items.lastIndex)])
        else -> null
    }
    SideEffect {
        if (!changed) return@SideEffect
        // A card arriving in front of a row at its start shows whole: the list would keep the old first card in place
        // and leave the new one a sliver at the row's edge (Continue Watching's played card). Before the next measure,
        // which applies the change.
        val atStart = state.firstVisibleItemIndex == 0 && state.firstVisibleItemScrollOffset == 0
        if (atStart && focus.items.isNotEmpty() && items.isNotEmpty() && key(items.first()) != key(focus.items.first())) state.requestScrollToItem(0)
        focus.items = items
        focus.keep(items.mapTo(HashSet()) { key(it) })
        if (follow != null) focus.displaced = followed?.displaced
        if (target == null) return@SideEffect
        if (focus.inRow) {
            focus.followed = target
            focus.handOff = HandOff(target)
            appFocus?.handOffs?.add(focus)
        } else if (followed != null && followed.index >= 0) {
            focus.key = target
        }
    }
    Column(modifier.fillMaxWidth()) {
        if (header != null) {
            header()
        } else {
            // At the row's foot: the room the heading's height leaves goes above it, between the shelves; the action
            // centred on the heading's line, whatever its own height. A large font's line takes more than the room.
            val line = with(LocalDensity.current) { sectionTitleStyle().lineHeight.toDp() }
            Row(
                Modifier.fillMaxWidth().heightIn(min = HeaderHeight).padding(horizontal = dimens.screenPadding),
                verticalAlignment = Alignment.Bottom,
            ) {
                SectionTitle(title, Modifier.weight(1f))
                if (action != null) Box(Modifier.height(line).wrapContentHeight(unbounded = true)) { action() }
            }
        }
        val padding = contentPadding
            ?: PaddingValues(start = dimens.screenPadding, end = dimens.screenPadding, top = dimens.shelfHeaderGap, bottom = dimens.shelfBottom)
        val direction = LocalLayoutDirection.current
        val padStart = padding.calculateStartPadding(direction)
        // The first card and its focus growth clear the rail or the TV column, wherever the row is placed.
        val (placed, clearance) = rememberNavigationClearance(padStart, NavigationCardGap)
        ScrollRow(
            state = state,
            // The heading's gap above; the focused card's growth at the ends and below (TV). Scrolled-away cards end at
            // the TV column's edge.
            contentPadding = PaddingValues(
                start = padStart + clearance,
                end = padding.calculateEndPadding(direction),
                top = padding.calculateTopPadding(),
                bottom = padding.calculateBottomPadding(),
            ),
            horizontalArrangement = Arrangement.spacedBy(spacing ?: dimens.gutter),
            modifier = Modifier
                .fillMaxWidth()
                .then(placed)
                .clipToNavigation()
                .onFocusChanged { focus.inRow = it.hasFocus }
                .focusProperties {
                    onEnter = { if (requestedFocusDirection in DirectionalMoves) focus.enter(entry) }
                    // Right past the last card stays on it, as a row ends (it never jumps to what lies beyond).
                    onExit = { if (requestedFocusDirection == forward) cancelFocusChange() }
                }
                .focusGroup(),
        ) {
            itemsIndexed(items, key = { _, item -> key(item) }) { index, item ->
                val scope = this
                val itemKey = key(item)
                Box(
                    Modifier.focusRequester(focus.requester(itemKey)).onFocusChanged {
                        if (!it.hasFocus) return@onFocusChanged
                        // Focus the user moved drops the card still to follow; focus handed to its place keeps it.
                        if (itemKey != focus.followed) focus.displaced = null
                        focus.followed = null
                        focus.key = itemKey
                    },
                ) {
                    scope.itemContent(index, item)
                }
            }
            if (end != null) item(key = END_KEY) { end() }
        }
    }
    focus.handOff?.let { pending ->
        LaunchedEffect(pending) {
            // The card composes in its new place with the row's next measure; one off view (Continue Watching's played
            // card moved to the front) is scrolled to first.
            for (frame in 0 until HAND_OFF_FRAMES) {
                withFrameNanos { }
                val index = focus.items.indexOfFirst { key(it) == pending.target }
                if (index >= 0 && state.layoutInfo.visibleItemsInfo.none { it.key == pending.target }) state.scrollToItem(index)
                if (focus.requester(pending.target).requestFocus()) break
            }
            focus.handOff = null
            appFocus?.handOffs?.remove(focus)
        }
    }
    DisposableEffect(appFocus) { onDispose { appFocus?.handOffs?.remove(focus) } }
    if (onNearEnd != null) {
        val nearEnd by rememberUpdatedState(onNearEnd)
        LaunchedEffect(state, items.size) {
            snapshotFlow { (state.layoutInfo.visibleItemsInfo.lastOrNull()?.index ?: -1) >= items.size - SHELF_LOAD_AHEAD }
                .distinctUntilChanged()
                .collect { if (it) nearEnd() }
        }
    }
}

/**
 * [ShelfRow]'s focus: the items it last composed, whether focus is in the row, the card that had it last, the card lost
 * without a replacement still to follow ([displaced], [followFocus]) and the card focus was last handed to ([followed]).
 */
private class ShelfFocus<T> {
    var items: List<T> = emptyList()
    var inRow = false
    var key: Any? = null
    var displaced: T? = null
    var followed: Any? = null

    /**
     * Focus to the card that had it last, else to [first]'s; false when neither is composed or [first] is null (Compose
     * then picks, as for a row scrolled away from both).
     */
    fun enter(first: Any?): Boolean {
        val last = key?.takeIf { it in requesters }
        return (last != null && requester(last).requestFocus()) || (first != null && requester(first).requestFocus())
    }

    /** The card to give focus to, the focused one having left the row. */
    var handOff by mutableStateOf<HandOff?>(null)

    private val requesters = HashMap<Any, FocusRequester>()

    fun requester(key: Any): FocusRequester = requesters.getOrPut(key) { FocusRequester() }

    /** Drops the requesters of cards no longer among the row's items ([keys]): they can't compose again. */
    fun keep(keys: Set<Any>) {
        requesters.keys.retainAll(keys)
    }
}

/** One hand-off of [ShelfRow]'s focus, to the card keyed [target]: each one runs anew, to the same card too. */
private class HandOff(val target: Any)

/** How many frames [ShelfRow] waits for the card taking a focused card's place to take focus: about half a second. */
private const val HAND_OFF_FRAMES = 30

/** The lazy key of [ShelfRow]'s `end`, apart from any item's. */
private const val END_KEY = "shelf\u0000end"

/** A shelf's or a group's heading: [LocalPlezyDimens]' `sectionTitleSize`, semibold, one line. */
@Composable
fun SectionTitle(text: String, modifier: Modifier = Modifier) {
    Text(
        text,
        style = sectionTitleStyle(),
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier,
    )
}

/** A heading row's height (a shelf's, a group's), where its line fits. */
val HeaderHeight = 32.dp

/**
 * A heading's trailing action ("See all"): a quiet text button that fits the 32 dp heading, [trailingIcon] after its
 * [text]; focus fills it (TV) as every control. On a touch screen it takes taps in a square of at least 48 dp
 * ([PlezySurface]'s `hitTarget`), over the heading's room.
 */
@Composable
fun ShelfHeadingAction(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, trailingIcon: ImageVector? = null) {
    PlezySurface(
        onClick = onClick,
        modifier = modifier.height(HeaderHeight),
        shape = CircleShape,
        color = Color.Transparent,
        contentColor = PlezyColors.TextMuted,
        contentAlignment = Alignment.Center,
        hitTarget = true,
    ) {
        Row(
            Modifier.padding(start = 12.dp, end = if (trailingIcon != null) 8.dp else 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(2.dp),
        ) {
            Text(text, style = MaterialTheme.typography.labelLarge, maxLines = 1)
            if (trailingIcon != null) Icon(trailingIcon, contentDescription = null, Modifier.size(18.dp))
        }
    }
}

/** The style of a [SectionTitle]: semibold at `sectionTitleSize`. */
@Composable
fun sectionTitleStyle(): TextStyle {
    val size = LocalPlezyDimens.current.sectionTitleSize
    return MaterialTheme.typography.titleLarge.copy(fontSize = size, lineHeight = size * 1.3f, fontWeight = FontWeight.SemiBold)
}

/** The room under a shelf's cards for a focused card's growth (TV); nothing elsewhere. */
val PlezyDimens.shelfBottom get() = if (focusGrows) focusReach else 0.dp

/** The gap to leave between shelves in a list: `sectionSpacing`, less the room each shelf already keeps under its cards. */
val PlezyDimens.shelfSpacing get() = sectionSpacing - shelfBottom

/** The room above a grid's first row for a focused poster's growth (TV); a hair elsewhere. */
val PlezyDimens.gridTop get() = if (focusGrows) focusReach else 4.dp

/** How many cards from a row's end its [ShelfRow] `onNearEnd` fires. */
const val SHELF_LOAD_AHEAD: Int = 8

/**
 * A shelf whose items are on their way: [title], the loading indicator and a row of blank cards the size of real ones
 * ([BlankCard]), so the page doesn't jump when they arrive. Nothing in it takes focus.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun LoadingShelf(title: String, modifier: Modifier = Modifier, shape: CardShape = CardShape.POSTER) {
    ShelfRow(
        title = title,
        items = BLANK_CARDS,
        key = { it },
        modifier = modifier,
        action = { LoadingIndicator(Modifier.size(24.dp)) },
    ) { _, _ -> BlankCard(shape) }
}

private val BLANK_CARDS = List(8) { it }

/**
 * See all at the end of a row on TV: the size of the row's [shape]d artwork ([width] wide), in the blank cards' fill, a
 * chevron over "View All"; focus shows as on the cards (the ring and the growth). [onClick] opens the row's full list.
 */
@Composable
fun SeeAllCard(shape: CardShape, onClick: () -> Unit, modifier: Modifier = Modifier, width: Dp = LocalPlezyDimens.current.cardWidth(shape)) {
    val corner = MaterialTheme.shapes.medium
    Box(
        modifier
            .width(width)
            .aspectRatio(shape.aspectRatio)
            .focusRing(corner)
            .clip(corner)
            .background(PlezyColors.SurfaceHigh)
            .overlayOpener()
            .clickable(role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Icon(PlezyIcons.ChevronRight, contentDescription = null, Modifier.size(36.dp), tint = PlezyColors.Text)
            Text(T.common.viewAll, style = MaterialTheme.typography.titleSmall, color = PlezyColors.Text)
        }
    }
}

/** The room between the side navigation's edge and a row's first card: a focused card grows into it. */
private val NavigationCardGap = 16.dp
