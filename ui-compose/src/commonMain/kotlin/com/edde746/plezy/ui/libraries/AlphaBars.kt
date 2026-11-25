package com.edde746.plezy.ui.libraries

import androidx.compose.foundation.background
import androidx.compose.foundation.focusable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.onPreviewKeyEvent
import androidx.compose.ui.input.key.type
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.isTraversalGroup
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.edde746.plezy.presentation.libraries.alphaLetterDown
import com.edde746.plezy.strings.T
import com.edde746.plezy.ui.probe.layoutProbe
import com.edde746.plezy.ui.theme.PlezyColors
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/** The alphabet bar's width: a column of letters, each a round mark. */
internal val ALPHA_BAR_WIDTH = 24.dp

/** How long the bar's highlight rests on a letter under Up and Down before the grid jumps to it. */
internal const val ALPHA_KEY_DEBOUNCE_MS = 150L

/**
 * The alphabet bar: a pill of letters down the grid's end, each row at least a line of its text tall, so none overlaps
 * another at any text size: a row per letter where they fit, else the rows [rows] gives for the rows there are
 * ([AlphaJump.rows], which a pick never moves): some letters alone, each run of letters between them one row drawn as a
 * dot. [current] (the grid's letter, or the letter filtering it) sits on a round tint of the primary colour, in place
 * of its run's dot where it is in one.
 *
 * A touch picks the letter under it and a drag along the bar picks each letter it crosses ([onJump]), a run's row
 * sharing its height among its letters ([alphaLetterDown]), so every letter is reachable whatever the bar's height; a
 * touch on a run's row that shows [current] picks that letter while it stays in the row, so a tap clears a filter
 * there too. While the finger is down, the letter under it shows in a round bubble beside the bar and in its run's
 * row. Under a keyboard or remote the bar is one focus stop: focused, its highlight (a round primary fill) starts on
 * [current] and Up and Down move it through every letter, those of a run shown in its row, jumping once it has rested
 * [ALPHA_KEY_DEBOUNCE_MS] ([onSettle]); Select or Enter jumps at once ([onJump]); Left and Back leave it for the grid
 * ([onExit]). A screen reader hears an "alphabet navigation" group of buttons: a letter, the current one selected, or a
 * run named by its ends (or the current letter in it), with an action per letter.
 */
@Composable
internal fun AlphaJumpBar(
    letters: List<String>,
    current: String?,
    rows: (Int) -> List<List<String>>,
    modifier: Modifier,
    onJump: (String) -> Unit,
    onSettle: (String) -> Unit,
    onExit: () -> Unit,
) {
    val primary = MaterialTheme.colorScheme.primary
    val scope = rememberCoroutineScope()
    val jump by rememberUpdatedState(onJump)
    val settle by rememberUpdatedState(onSettle)
    val marked by rememberUpdatedState(current)
    BoxWithConstraints(modifier.width(ALPHA_BAR_WIDTH).fillMaxSize().padding(vertical = 8.dp)) {
        val letterMin = with(LocalDensity.current) { MaterialTheme.typography.labelSmall.lineHeight.toDp() }
        val fits = (maxHeight / letterMin).toInt().coerceAtLeast(1)
        val shown = if (letters.size <= fits) letters.map(::listOf) else rows(fits)
        val slot = (maxHeight.value / shown.size.coerceAtLeast(1)).coerceAtMost(28f)
        val drawn by rememberUpdatedState(shown)
        var focused by remember { mutableStateOf(false) }
        var highlight by remember { mutableStateOf<String?>(null) }
        var pending by remember { mutableStateOf<Job?>(null) }
        /** The letter under the finger while it is down. */
        var touched by remember { mutableStateOf<String?>(null) }
        Column(
            Modifier
                .align(Alignment.Center)
                .background(PlezyColors.SurfaceHigh, CircleShape)
                .semantics {
                    contentDescription = T.accessibility.alphabetNavigation
                    isTraversalGroup = true
                }
                .onFocusChanged { state ->
                    focused = state.isFocused
                    if (state.isFocused) highlight = current?.takeIf { it in letters } ?: letters.firstOrNull() else pending?.cancel()
                }
                .onPreviewKeyEvent { event ->
                    if (event.type != KeyEventType.KeyDown) return@onPreviewKeyEvent false
                    when (event.key) {
                        Key.DirectionUp, Key.DirectionDown -> {
                            val index = letters.indexOf(highlight).coerceAtLeast(0) + if (event.key == Key.DirectionUp) -1 else 1
                            val letter = letters.getOrNull(index.coerceIn(0, letters.lastIndex)) ?: return@onPreviewKeyEvent true
                            if (letter != highlight) {
                                highlight = letter
                                pending?.cancel()
                                pending = scope.launch {
                                    delay(ALPHA_KEY_DEBOUNCE_MS)
                                    settle(letter)
                                }
                            }
                            true
                        }
                        Key.Enter, Key.NumPadEnter, Key.DirectionCenter -> {
                            pending?.cancel()
                            highlight?.let(jump)
                            true
                        }
                        Key.DirectionLeft, Key.Back, Key.Escape -> {
                            pending?.cancel()
                            onExit()
                            true
                        }
                        else -> false
                    }
                }
                .focusable()
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val down = awaitFirstDown()
                        val steady = drawn
                        fun rowAt(y: Float) = (y / size.height * steady.size).toInt().coerceIn(0, steady.lastIndex)
                        // The run's row the finger came down on, where it shows the current letter: that letter.
                        val downRow = rowAt(down.position.y)
                        val pinned = marked?.takeIf { steady[downRow].size > 1 && it in steady[downRow] }
                        fun at(y: Float) = pinned?.takeIf { rowAt(y) == downRow } ?: alphaLetterDown(steady, (y / size.height).toDouble())
                        try {
                            touched = at(down.position.y).also(jump)
                            while (true) {
                                val event = awaitPointerEvent()
                                val change = event.changes.firstOrNull { it.id == down.id } ?: break
                                if (!change.pressed) break
                                change.consume()
                                val letter = at(change.position.y)
                                if (letter != touched) {
                                    touched = letter
                                    jump(letter)
                                }
                            }
                        } finally {
                            touched = null
                        }
                    }
                }
                .layoutProbe("libraries.alpha", reportsFocus = false),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            for (row in shown) {
                // A run's row shows the letter touched, highlighted or current in it, else its dot.
                val letter = row.singleOrNull()
                    ?: touched?.takeIf { it in row }
                    ?: highlight?.takeIf { focused && it in row }
                    ?: current?.takeIf { it in row }
                val isCurrent = letter != null && letter == current
                val isHighlight = focused && letter != null && letter == highlight
                Box(
                    Modifier.size(ALPHA_BAR_WIDTH, slot.dp)
                        // One node per row, named by its letter or its run's ends, as a screen reader and UI automation
                        // read it; a run's letters each its own action.
                        .semantics(mergeDescendants = true) {
                            role = Role.Button
                            selected = isCurrent
                            if (row.size > 1) {
                                contentDescription = "${row.first()}–${row.last()}"
                                customActions = row.map { CustomAccessibilityAction(it) { jump(it); true } }
                            }
                            onClick { jump(letter ?: row.first()); true }
                        }
                        .layoutProbe("libraries.alpha.${if (row.size > 1) "${row.first()}-${row.last()}" else row.first()}", reportsFocus = false),
                    contentAlignment = Alignment.Center,
                ) {
                    val markSize = (slot - 2).coerceIn(14f, 22f).dp
                    when {
                        isHighlight -> Box(Modifier.size(markSize).background(primary, CircleShape))
                        isCurrent -> Box(Modifier.size(markSize).background(primary.copy(alpha = CURRENT_TINT), CircleShape))
                    }
                    Text(
                        letter ?: RUN_DOT,
                        style = MaterialTheme.typography.labelSmall,
                        color = when {
                            isHighlight -> PlezyColors.OnPrimary
                            isCurrent -> primary
                            else -> PlezyColors.Text
                        },
                        fontWeight = if (isHighlight || isCurrent) FontWeight.Bold else FontWeight.Normal,
                    )
                    if (letter != null && letter == touched) {
                        // Beside the bar, clear of the finger on it.
                        Box(
                            Modifier.offset(x = -(ALPHA_BAR_WIDTH / 2 + BUBBLE_GAP + BUBBLE_SIZE / 2))
                                .requiredSize(BUBBLE_SIZE)
                                .background(primary, CircleShape)
                                .clearAndSetSemantics {},
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(letter, style = MaterialTheme.typography.headlineSmall, color = PlezyColors.OnPrimary, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}

/** The tint under the current letter: light enough to tell from the focused letter's full fill. */
private const val CURRENT_TINT = 0.24f

/** What a run of letters the bar has no room to draw shows. */
private const val RUN_DOT = "•"

private val BUBBLE_SIZE = 48.dp
private val BUBBLE_GAP = 12.dp
