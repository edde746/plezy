package com.edde746.plezy.input

/**
 * The screens with top tabs (Libraries, Live TV, Downloads) that a controller's shoulder buttons (L1 and R1, LB and RB)
 * move through. Each screen registers while it is shown; several can be at once (one under another on a back stack),
 * and a press goes to the first that [TabScreen.isActive] (on view, its route current, no dialog or sheet over it).
 */
class TabNavigation {
    private val screens = mutableListOf<TabScreen<*>>()

    fun register(screen: TabScreen<*>) {
        if (screen !in screens) screens += screen
    }

    fun unregister(screen: TabScreen<*>) {
        screens -= screen
    }

    /**
     * A shoulder press: the active screen's previous or [next] tab. True when a screen was active (the press is taken
     * even at the last or first tab, where nothing changes); false when none is.
     */
    fun dispatch(next: Boolean): Boolean {
        val screen = screens.firstOrNull { it.isActive() } ?: return false
        screen.step(next)
        return true
    }
}

/**
 * A screen's tabs: [tabs] and the [selected] one, read at each press (the set can change: a Jellyfin library has fewer
 * tabs than a Plex one), and [select], which shows a tab.
 */
class TabScreen<T>(
    private val tabs: () -> List<T>,
    private val selected: () -> T,
    private val select: (T) -> Unit,
    val isActive: () -> Boolean,
) {
    /** Shows the tab before or after ([next]) the selected one; nothing past the first or the last. */
    fun step(next: Boolean) {
        val list = tabs()
        val index = list.indexOf(selected())
        if (index < 0) return
        list.getOrNull(if (next) index + 1 else index - 1)?.let(select)
    }
}
