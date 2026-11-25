package com.edde746.plezy.presentation.browse

/**
 * Where a row's focus goes after its items were replaced: [index] the new place of the item it followed (-1: neither
 * is there, the caller keeps its positional clamp), [displaced] the item still to follow on the next replacement.
 */
data class FocusFollow<out T>(val index: Int, val displaced: T?)

/**
 * Where focus goes after a row's [items] were replaced under it, given the card it was on ([focused]) and the one it
 * lost earlier without a replacement ([displaced]). The exact card wins; an episode that left the row follows its
 * series' replacement (a finished episode becomes the next one), so a Continue Watching refresh that moves the played
 * item to the front keeps focus on it.
 *
 * A refresh can come in steps: the finished episode leaves at once and the next one arrives a refresh later. In
 * between nothing replaces the focused card, so focus keeps its place on whatever slid into it, and the lost card comes
 * back as [FocusFollow.displaced]; the caller hands it in on the next replacement, so focus still reaches its
 * replacement, and drops it once the user moves or acts.
 */
fun followFocus(items: List<MediaCardUi>, focused: MediaCardUi?, displaced: MediaCardUi?): FocusFollow<MediaCardUi> {
    if (displaced != null) {
        val index = followIndex(items, displaced)
        if (index != -1) return FocusFollow(index, null)
    }
    val index = if (focused == null) -1 else followIndex(items, focused)
    return FocusFollow(index, if (index == -1) displaced ?: focused else displaced)
}

private fun followIndex(items: List<MediaCardUi>, previous: MediaCardUi): Int {
    val exact = items.indexOfFirst { it.id == previous.id }
    if (exact != -1) return exact
    val series = previous.seriesKey ?: return -1
    return items.indexOfFirst { it.seriesKey == series }
}
