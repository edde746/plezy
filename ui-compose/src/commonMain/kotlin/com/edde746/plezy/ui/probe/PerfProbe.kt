package com.edde746.plezy.ui.probe

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.drawscope.ContentDrawScope
import androidx.compose.ui.node.CompositionLocalConsumerModifierNode
import androidx.compose.ui.node.DrawModifierNode
import androidx.compose.ui.node.ModifierNodeElement
import androidx.compose.ui.node.ObserverModifierNode
import androidx.compose.ui.node.TraversableNode
import androidx.compose.ui.node.currentValueOf
import androidx.compose.ui.node.findNearestAncestor
import androidx.compose.ui.node.invalidateDraw
import androidx.compose.ui.node.observeReads

/**
 * Test hook: when a screen first draws its content and when a list of shelves comes to rest (`shelves.settled`,
 * rememberShelfNavigation), so a harness driving the real app (the Android perf runs) times what
 * the user waits for. Provided through [LocalPerfProbe] only in those runs; otherwise [perfMark] and [perfImage] cost
 * one null check per draw.
 */
fun interface PerfProbe {
    /** [name] drew with [detail]: `k=v` pairs separated by spaces, values without spaces; empty for none. */
    fun mark(name: String, detail: String)
}

val LocalPerfProbe = staticCompositionLocalOf<PerfProbe?> { null }

/** Home's mark: Home drawn with its content. Android's perf build reports the launch fully drawn at the first. */
const val HOME_CONTENT_MARK = "home.content"

/**
 * Marks [name] with [detail] to the [LocalPerfProbe], if any, at this element's first draw while [ready], after its
 * content has drawn: once per [detail] for as long as the element lives (a lazy list reusing it starts over). A screen
 * puts it on its root; the screen's images take the screen from its mark ([perfImage]).
 */
fun Modifier.perfMark(name: String, detail: String, ready: Boolean): Modifier = this then PerfMarkElement(name, detail, ready)

/**
 * Marks `image` to the [LocalPerfProbe], if any, at this image's first draw once it has [loaded] (read as it draws),
 * once for as long as the element lives (a lazy list reusing it starts over), with the screen it is on, by the nearest
 * [perfMark] around it: `screen=home` ([HOME_CONTENT_MARK]), else `screen=other`.
 */
fun Modifier.perfImage(loaded: () -> Boolean): Modifier = this then PerfImageElement(loaded)

private data class PerfMarkElement(val name: String, val detail: String, val ready: Boolean) : ModifierNodeElement<PerfMarkNode>() {
    override fun create() = PerfMarkNode(name, detail, ready)

    override fun update(node: PerfMarkNode) = node.update(name, detail, ready)
}

private class PerfMarkNode(var name: String, private var detail: String, private var ready: Boolean) :
    Modifier.Node(),
    DrawModifierNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode,
    TraversableNode {
    private var probe: PerfProbe? = null

    /** The detail marked last under [name]; null before the first mark. */
    private var marked: String? = null

    override val traverseKey: Any get() = PerfMarkKey

    // Without a probe an update redraws nothing; with one, [update] asks for the draw that marks.
    override val shouldAutoInvalidate: Boolean get() = false

    fun update(name: String, detail: String, ready: Boolean) {
        if (name != this.name) {
            this.name = name
            marked = null
        }
        this.detail = detail
        this.ready = ready
        if (probe != null && ready && detail != marked) invalidateDraw()
    }

    override fun onAttach() = onObservedReadsChanged()

    override fun onObservedReadsChanged() = observeReads { probe = currentValueOf(LocalPerfProbe) }

    override fun onDetach() {
        probe = null
    }

    override fun onReset() {
        marked = null
    }

    override fun ContentDrawScope.draw() {
        drawContent()
        val probe = probe ?: return
        if (ready && detail != marked) {
            marked = detail
            probe.mark(name, detail)
        }
    }
}

/** The [TraversableNode.traverseKey] of [PerfMarkNode], for [PerfImageNode] to find the screen it is on. */
private object PerfMarkKey

private data class PerfImageElement(val loaded: () -> Boolean) : ModifierNodeElement<PerfImageNode>() {
    override fun create() = PerfImageNode(loaded)

    override fun update(node: PerfImageNode) {
        node.loaded = loaded
    }
}

private class PerfImageNode(var loaded: () -> Boolean) :
    Modifier.Node(),
    DrawModifierNode,
    CompositionLocalConsumerModifierNode,
    ObserverModifierNode {
    private var probe: PerfProbe? = null
    private var marked = false

    // As PerfMarkNode's; with a probe, the draw reads [loaded] until it marks, so a load redraws it.
    override val shouldAutoInvalidate: Boolean get() = false

    override fun onAttach() = onObservedReadsChanged()

    override fun onObservedReadsChanged() = observeReads { probe = currentValueOf(LocalPerfProbe) }

    override fun onDetach() {
        probe = null
    }

    override fun onReset() {
        marked = false
    }

    override fun ContentDrawScope.draw() {
        drawContent()
        val probe = probe ?: return
        if (!marked && loaded()) {
            marked = true
            val screen = when ((findNearestAncestor(PerfMarkKey) as PerfMarkNode?)?.name) {
                HOME_CONTENT_MARK -> "home"
                else -> "other"
            }
            probe.mark("image", "screen=$screen")
        }
    }
}
