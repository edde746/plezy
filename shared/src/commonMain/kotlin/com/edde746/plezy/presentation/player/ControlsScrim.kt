package com.edde746.plezy.presentation.player

import kotlin.math.max
import kotlin.math.pow

/**
 * What the player's controls draw behind themselves over the video (their scrim, the black in a glass), one rule for
 * every UI.
 *
 * The scrim is one gradient over the whole player, down from its top edge and up from its bottom edge, smooth and
 * full width, with no edge of its own: [EASE]'s black at each edge thinning on an eased curve to clear at the edge's
 * reach. Each edge reaches [REACH] of the player's height in, or further where the title lines sit at that edge
 * ([reach]): far enough that their far side is [TEXT_DEPTH] of the way in, where the scrim is still 57 % black or
 * more, so the title and the episode line in the title's white read at 4.5:1 or more over a white frame. Every UI
 * draws it from [stops]. Other blacks (a glass's, a message's pill) are each UI's own alphas for an SDR picture; while
 * [PlayerUiState.hdrPicture] each goes through [alpha].
 *
 * The controls are SDR: their white is the display's SDR white (Windows' SDR content brightness, the EDR reference
 * white on Apple, Android's SDR level), while an HDR picture behind them reaches the display's peak: 5.8 times that
 * white on a Windows HDR display (465 cd/m² over 80), up to 16 times on an XDR screen. Over an HDR picture each alpha
 * lets through the sixth power of what it lets through over SDR: where half of the video or less gets through over
 * SDR, a thirty-second of that or less. The scrim keeps its clear middle, so no edge shows where it starts. On that
 * Windows display's composed desktop the time left measured twice what its stops let through at the fifth power (5 %
 * of a 460 cd/m² peak, 2.9:1), hence the sixth.
 */
object ControlsScrim {
    /** Each edge's curve: black alpha by the fraction of the edge's reach in from it, eased out to clear. */
    private val EASE = listOf(0f to 0.72f, 0.25f to 0.62f, 0.47f to 0.42f, 0.72f to 0.18f, 0.89f to 0.05f, 1f to 0f)
    /** How far in from each edge the scrim reaches at least, as a fraction of the player's height. */
    private const val REACH = 0.2f
    /** Where the far side of the title lines sits in their edge's reach (57.5 % black there). */
    private const val TEXT_DEPTH = 0.3f
    private const val HDR_POWER = 6

    /** [alpha] of black over the video, as an SDR picture takes it, for the picture at hand. */
    fun alpha(alpha: Float, hdr: Boolean): Float = if (hdr) 1f - (1f - alpha).pow(HDR_POWER) else alpha

    /**
     * How far an edge's scrim reaches, as a fraction of the player's [height]: [REACH], or further where text lines
     * sit at that edge and their far side is [text] from it (the same unit as [height]; 0 for none), up to the whole
     * height.
     */
    fun reach(text: Float, height: Float): Float =
        if (height <= 0f) REACH else max(REACH, text / height / TEXT_DEPTH).coerceAtMost(1f)

    /**
     * The scrim's gradient stops down the player (positions 0 at its top edge, 1 at its bottom), for the picture at
     * hand: from the top edge in to [top] and from the bottom edge in to [bottom] (fractions of the height, as [reach]
     * gives them; 0 for no scrim at that edge). Where the two reaches overlap (a short player with a tall title) their
     * blacks compound, as two layers would, in one gradient.
     */
    fun stops(hdr: Boolean, top: Float = REACH, bottom: Float = REACH): List<ScrimStop> {
        val positions = (listOf(0f, 1f) + EASE.flatMap { (t, _) -> listOf(top * t, 1f - bottom * t) }).filter { it in 0f..1f }.distinct().sorted()
        return positions.map { p ->
            val through = (1f - edge(p, top)) * (1f - edge(1f - p, bottom))
            ScrimStop(p, alpha(1f - through, hdr))
        }
    }

    /** An edge's black [from] its edge (a fraction of the height) with the edge reaching [reach]: [EASE], straight between. */
    private fun edge(from: Float, reach: Float): Float {
        if (reach <= 0f || from >= reach) return 0f
        val t = from / reach
        val after = EASE.indexOfFirst { it.first >= t }
        if (after <= 0) return EASE.first().second
        val (a, b) = EASE[after - 1] to EASE[after]
        return a.second + (b.second - a.second) * (t - a.first) / (b.first - a.first)
    }

    /**
     * Whether the controls' muted text over the video (why the controls are off, the time left) stays muted. Over
     * an HDR picture it draws at the full text colour: muted text lets the video through it, and a highlight there left
     * the time left, when muted, at 2.1:1 under the darker scrim (a Windows HDR display, 465 cd/m² behind it).
     */
    fun textMuted(hdr: Boolean): Boolean = !hdr
}

/** A stop of the scrim's gradient: its [alpha] of black at [position] (0 at the player's top edge, 1 at its bottom). */
data class ScrimStop(val position: Float, val alpha: Float)
