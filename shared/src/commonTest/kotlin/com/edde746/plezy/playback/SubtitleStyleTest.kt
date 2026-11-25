package com.edde746.plezy.playback

import com.edde746.plezy.data.settings.SubtitleAppearance
import com.edde746.plezy.settings.SubAssOverride
import kotlin.test.Test
import kotlin.test.assertEquals

class SubtitleStyleTest {
    private val default = SubtitleAppearance.DEFAULT

    private fun properties(appearance: SubtitleAppearance) = SubtitleStyle.of(appearance).properties()

    @Test
    fun theDefaultsAreThePlayersOwnStyleSettings() {
        assertEquals(
            mapOf(
                "sub-font-size" to "38",
                "sub-color" to "#FFFFFF",
                "sub-outline-size" to "3",
                "sub-outline-color" to "#000000",
                "sub-bold" to "no",
                "sub-italic" to "no",
                "sub-back-color" to "#00000000",
                "sub-border-style" to "outline-and-shadow",
                "sub-ass-override" to "no",
                "sub-ass-video-aspect-override" to "1",
            ),
            properties(default),
        )
        assertEquals(100.0, SubtitleStyle.DEFAULT.position(0.0, SubtitleFrame.SCREEN), "mpv's own place")
        assertEquals(true, SubtitleStyle.DEFAULT.useMargins)
    }

    @Test
    fun theStoredValuesGoToMpvAsTheyAre() {
        val style = properties(default.copy(fontSize = 55, borderSize = 0, bold = true, italic = true, assOverride = SubAssOverride.STRIP))
        assertEquals("55", style["sub-font-size"])
        assertEquals("0", style["sub-outline-size"])
        assertEquals("yes", style["sub-bold"])
        assertEquals("yes", style["sub-italic"])
        assertEquals("strip", style["sub-ass-override"])
        assertEquals(SubAssOverride.entries.map { it.name.lowercase() }, listOf("no", "yes", "scale", "force", "strip"))
    }

    @Test
    fun aColourMpvWouldRefuseDrawsInTheSettingsDefault() {
        assertEquals("#FFEE00", properties(default.copy(textColor = "#ffee00"))["sub-color"])
        assertEquals("#80FFEE00", properties(default.copy(textColor = "80ffee00"))["sub-color"], "eight digits and no hash")
        assertEquals("#FFFFFF", properties(default.copy(textColor = "yellow"))["sub-color"])
        assertEquals("#000000", properties(default.copy(borderColor = "#12345"))["sub-outline-color"])
        assertEquals("#7F000000", properties(default.copy(backgroundColor = "", backgroundOpacity = 50))["sub-back-color"])
    }

    @Test
    fun aBackgroundIsABoxOfItsColourAtItsOpacityAndNoneAtZero() {
        val box = properties(default.copy(backgroundColor = "#102030", backgroundOpacity = 50))
        assertEquals("#7F102030", box["sub-back-color"], "50 % of 255, rounded down")
        assertEquals("background-box", box["sub-border-style"])
        assertEquals("#FF102030", properties(default.copy(backgroundColor = "#102030", backgroundOpacity = 100))["sub-back-color"])
        val none = properties(default.copy(backgroundColor = "#102030", backgroundOpacity = 0))
        assertEquals("outline-and-shadow", none["sub-border-style"])
        assertEquals("#00102030", none["sub-back-color"])
    }

    @Test
    fun thePositionIsMpvsSubPosLiftedAboveTheControls() {
        val screen = SubtitleFrame.SCREEN
        val raised = SubtitleStyle.of(default.copy(position = 90))
        assertEquals(90.0, raised.position(0.0, screen))
        assertEquals(80.0, raised.position(0.2, screen), "controls above the line: above the controls")
        assertEquals(90.0, raised.position(0.05, screen), "controls under the raised line: it stays")
        assertEquals(90.0, raised.position(Double.NaN, screen), "no measured controls")
        assertEquals(0.0, raised.position(1.5, screen), "never above the top")
        val lowered = SubtitleStyle.of(default.copy(position = 130))
        assertEquals(130.0, lowered.position(0.0, screen), "below their own place without controls")
        assertEquals(75.0, lowered.position(0.25, screen), "above the controls while they show")
        assertEquals(150.0, SubtitleStyle.of(default.copy(position = 400)).subPos.toDouble(), "mpv's range")
        assertEquals(75.0, SubtitleStyle.DEFAULT.position(0.25, screen))
    }

    @Test
    fun placedByThePictureSubtitlesClearOnlyTheControlsOverIt() {
        // An iPad in landscape (2064 px tall) with a 16:9 picture between 258 px bands; an upright phone (2400 px)
        // with a 1080 px band in its middle.
        val ipad = SubtitleFrame.picture(2064.0, 258.0, 258.0)
        val phone = SubtitleFrame.picture(2400.0, 660.0, 660.0)
        assertEquals(100.0, SubtitleStyle.DEFAULT.position(0.12, ipad), "controls in the band below: no jump")
        assertEquals(100.0, SubtitleStyle.DEFAULT.position(0.25, phone), "controls in the band below: no jump")
        // Controls reaching 361.2 px up cover the picture's bottom 103.2 px: a fifteenth of its 1548 px.
        assertEquals(1.0 / 15, ipad.lift(0.175), 1e-9)
        assertEquals(100.0 * (1 - 1.0 / 15), SubtitleStyle.DEFAULT.position(0.175, ipad), 1e-9)
        // A picture filling the height (a phone in landscape): the controls' share as on the screen.
        val filled = SubtitleFrame.picture(1080.0, 0.0, 0.0)
        assertEquals(SubtitleStyle.DEFAULT.position(0.25, SubtitleFrame.SCREEN), SubtitleStyle.DEFAULT.position(0.25, filled))
        val raised = SubtitleStyle.of(default.copy(position = 90))
        assertEquals(90.0, raised.position(0.12, ipad), "controls in the band: the style's place")
        assertEquals(90.0, raised.position(0.175, ipad), "a fifteenth is less than the style's tenth")
        assertEquals(80.0, raised.position(0.2, filled), "controls over a fifth of the picture: above them")
    }

    @Test
    fun theFrameTakesItsBandsFromMpvsOsdDimensions() {
        // A band above the picture only (the picture at the surface's bottom): all the controls cover is over it, a
        // share of the shorter picture.
        val topOnly = SubtitleFrame.picture(2000.0, 500.0, 0.0)
        assertEquals(0.2 / 1.5, topOnly.lift(0.1), 1e-9)
        assertEquals(100.0 * (1 - 0.2 / 1.5), SubtitleStyle.DEFAULT.position(0.1, topOnly), 1e-9)
        // A picture zoomed past the surface's bottom edge (negative band): its bottom 100 px are off the surface.
        assertEquals(0.3, SubtitleFrame.picture(1000.0, -100.0, -100.0).lift(0.26), 1e-9)
        // No output size yet: the whole surface.
        assertEquals(SubtitleFrame.SCREEN, SubtitleFrame.picture(0.0, 0.0, 0.0))
        assertEquals(SubtitleFrame.SCREEN, SubtitleFrame.picture(Double.NaN, 0.0, 0.0))
        assertEquals(0.0, SubtitleFrame(100.0, 50.0, 50.0).lift(0.9), "a frame of no height")
        assertEquals(0.0, SubtitleFrame.SCREEN.lift(Double.NaN), "no measured controls")
    }
}
