package com.edde746.plezy.desktop.windows

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class WindowPlacementTest {
    private val placement = WindowPlacement(
        flags = 0,
        showCmd = 1,
        minX = -1,
        minY = -1,
        maxX = -1,
        maxY = -1,
        normal = PlacementRect(100, 50, 1380, 770),
    )

    /** A 1920x1080 monitor at the origin with a 48 px taskbar at its top, and a second one to its right. */
    private val primary = PlacementMonitor(PlacementRect(0, 0, 1920, 1080), PlacementRect(0, 48, 1920, 1080))
    private val second = PlacementMonitor(PlacementRect(1920, 0, 3840, 1080), PlacementRect(1920, 0, 3840, 1040))

    private fun nearest(monitors: List<PlacementMonitor>): (PlacementRect) -> PlacementMonitor? = { rect ->
        monitors.minByOrNull { m -> if (rect.left < m.bounds.right && rect.right > m.bounds.left) 0 else minOf(kotlin.math.abs(rect.left - m.bounds.right), kotlin.math.abs(rect.right - m.bounds.left)) }
    }

    private fun onScreen(monitors: List<PlacementMonitor>): (PlacementRect) -> Boolean = { rect ->
        monitors.any { m -> rect.left < m.bounds.right && rect.right > m.bounds.left && rect.top < m.bounds.bottom && rect.bottom > m.bounds.top }
    }

    @Test
    fun `a placement is stored as the 44 bytes of WINDOWPLACEMENT and read back`() {
        val bytes = placement.encode()
        assertEquals(44, bytes.size)
        assertEquals(listOf<Byte>(44, 0, 0, 0), bytes.take(4))
        assertEquals(listOf<Byte>(100, 0, 0, 0), bytes.slice(28 until 32))
        assertEquals(placement, WindowPlacement.decode(bytes))
    }

    @Test
    fun `a value of another size restores nothing`() {
        assertNull(WindowPlacement.decode(ByteArray(40)))
        assertNull(WindowPlacement.decode(placement.encode() + 0))
    }

    @Test
    fun `maximized and minimized from maximized restore maximized`() {
        assertTrue(placement.copy(showCmd = WindowPlacement.SW_SHOWMAXIMIZED).maximized)
        assertTrue(placement.copy(showCmd = 2, flags = WindowPlacement.WPF_RESTORETOMAXIMIZED).maximized)
        assertFalse(placement.copy(showCmd = 2).maximized)
        assertFalse(placement.maximized)
    }

    @Test
    fun `a snapped window saves its rect on screen in its monitors workspace coordinates`() {
        val snapped = WindowPlacement.arranged(placement, PlacementRect(0, 48, 960, 1080), primary)

        assertEquals(PlacementRect(0, 0, 960, 1032), snapped.normal)
        assertEquals(placement.showCmd, snapped.showCmd)
    }

    @Test
    fun `a placement on a monitor still there restores as saved`() {
        val saved = placement.copy(normal = PlacementRect(2000, 100, 3000, 700))
        val current = placement.copy(normal = PlacementRect(320, 180, 1600, 900))

        assertEquals(saved, WindowPlacement.restored(saved, current, nearest(listOf(primary, second)), onScreen(listOf(primary, second))))
    }

    @Test
    fun `a placement on a monitor gone keeps its size at the default position`() {
        val saved = placement.copy(normal = PlacementRect(2000, 100, 3000, 700), showCmd = WindowPlacement.SW_SHOWMAXIMIZED)
        val current = placement.copy(normal = PlacementRect(320, 180, 1600, 900))

        val restored = WindowPlacement.restored(saved, current, nearest(listOf(primary)), onScreen(listOf(primary)))

        assertEquals(PlacementRect(320, 180, 1320, 780), restored.normal)
        assertTrue(restored.maximized)
    }
}
