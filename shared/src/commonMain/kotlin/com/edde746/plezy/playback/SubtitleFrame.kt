package com.edde746.plezy.playback

/**
 * The frame mpv places bottom subtitles in, on the player's surface; `sub-pos` moves them by a share of its height.
 * Plain-text subtitles sit in the whole surface where an engine leaves mpv's default (`sub-use-margins=yes`: [SCREEN])
 * and in the picture where it places them by the video (`sub-use-margins=no`): the surface less the bands mpv's
 * `osd-dimensions` reports above and below the picture ([picture]). The player's controls are measured on the surface
 * ([PlayerEngine.setSubtitleLift]); [lift] turns them into a lift in this frame, which [SubtitleStyle.position] makes
 * mpv's `sub-pos`.
 *
 * @param height the surface's height (`osd-dimensions/h`).
 * @param top the band above the frame (`osd-dimensions/mt`), in the unit of [height]; 0 for the whole surface.
 * @param bottom the band below the frame (`osd-dimensions/mb`); 0 for the whole surface. Negative bands (a picture
 *   zoomed past the surface's edges) put the frame's edges off the surface.
 */
data class SubtitleFrame(val height: Double, val top: Double, val bottom: Double) {
    /**
     * How far bottom subtitles move up, as a share of this frame's height, to clear controls that cover
     * [controlsLift] of the surface's height from its bottom edge: by the part of the controls over the frame. Controls
     * that stay in the band below the picture move nothing; 0 for unmeasured controls or a frame of no height.
     */
    fun lift(controlsLift: Double): Double {
        val frame = height - top - bottom
        if (!controlsLift.isFinite() || frame <= 0.0) return 0.0
        return (controlsLift * height - bottom).coerceAtLeast(0.0) / frame
    }

    companion object {
        /** The whole surface: subtitles move by the controls' share of it as it is. */
        val SCREEN = SubtitleFrame(1.0, 0.0, 0.0)

        /**
         * The picture as mpv's `osd-dimensions` place it: the surface's [height] (`h`) less the bands above ([top],
         * `mt`) and below it ([bottom], `mb`). [SCREEN] while mpv has no output size (`h` 0, before a video output).
         */
        fun picture(height: Double, top: Double, bottom: Double): SubtitleFrame =
            if (height > 0.0 && top.isFinite() && bottom.isFinite()) SubtitleFrame(height, top, bottom) else SCREEN
    }
}
