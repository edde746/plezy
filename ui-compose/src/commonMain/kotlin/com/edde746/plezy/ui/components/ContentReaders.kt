package com.edde746.plezy.ui.components

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import com.edde746.plezy.ui.theme.LocalAppearance
import androidx.compose.ui.semantics.clearAndSetSemantics

/**
 * Whether an accessibility service that reads the screen's content is on ([readsContent]), live: it changes as
 * services come and go. True wherever the platform can't tell.
 */
@Composable
internal expect fun contentReaderOn(): Boolean

/**
 * An enabled accessibility service as [readsContent] weighs it: whether it gives spoken, braille or audible feedback
 * ([speaks]), whether it subscribes to scrolling or content changes ([followsContent]).
 */
internal class EnabledService(val speaks: Boolean, val followsContent: Boolean)

/**
 * Whether the enabled accessibility services read the screen's content: accessibility is [enabled], and touch
 * exploration is on, or a service speaks or follows the content, or none is listed (one the list leaves out, as a UI
 * test's automation, which reads everything). A service that only reacts to focus, as a TV launcher's haptic feedback,
 * doesn't.
 */
internal fun readsContent(enabled: Boolean, touchExploration: Boolean, services: List<EnabledService>): Boolean =
    enabled && (touchExploration || services.isEmpty() || services.any { it.speaks || it.followsContent })

/**
 * The semantics of long lists stay whatever services are on ([semanticsForReaders]): test builds provide true, as
 * their UI automation isn't among the services the platform lists.
 */
val LocalKeepsSemantics = staticCompositionLocalOf { false }

/**
 * This list's contents left out of the semantics tree on TV while no service reads the content ([contentReaderOn],
 * [LocalKeepsSemantics]): Compose recomputes the tree on each frame a list scrolls whenever any service is enabled,
 * and a box's launcher may keep one on that only reacts to focus.
 */
@Composable
internal fun Modifier.semanticsForReaders(): Modifier =
    if (!LocalAppearance.current.tv || LocalKeepsSemantics.current || contentReaderOn()) this else clearAndSetSemantics {}
