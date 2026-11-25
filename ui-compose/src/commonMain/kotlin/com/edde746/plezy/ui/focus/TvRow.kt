package com.edde746.plezy.ui.focus

import androidx.compose.foundation.focusGroup
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusDirection
import androidx.compose.ui.focus.FocusEnterExitScope
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection

/**
 * One of the page's rows (the actions, the player app's answers, the seasons, the ranges, the episodes, Cast & crew,
 * and More and the user's rating alone), where Left and Right stay: past the row's end focus stays on its last element;
 * past its start it goes on to what lies beside the page's start edge, where the rows start, the side navigation. More
 * and the user's rating ([toNavigation] false), each at the end of its line, stay too: Left from More went down to Play.
 * Up and Down lead out of the row, to where [up] and [down] move focus (they may keep it with
 * [FocusEnterExitScope.cancelFocusChange]), else to the nearest element that way. A D-pad's move into the row lands
 * where [enter] puts it, else on its element nearest the move.
 */
@Composable
internal fun Modifier.tvRow(
    toNavigation: Boolean = true,
    up: (FocusEnterExitScope.() -> Unit)? = null,
    down: (FocusEnterExitScope.() -> Unit)? = null,
    enter: (FocusEnterExitScope.() -> Unit)? = null,
): Modifier {
    val end = if (LocalLayoutDirection.current == LayoutDirection.Ltr) FocusDirection.Right else FocusDirection.Left
    return focusProperties {
        if (enter != null) onEnter = { if (requestedFocusDirection in DirectionalMoves) enter() }
        onExit = {
            val sideways = requestedFocusDirection == FocusDirection.Left || requestedFocusDirection == FocusDirection.Right
            when {
                requestedFocusDirection == FocusDirection.Up && up != null -> up()
                requestedFocusDirection == FocusDirection.Down && down != null -> down()
                sideways && (requestedFocusDirection == end || !toNavigation) -> cancelFocusChange()
            }
        }
    }.focusGroup()
}
