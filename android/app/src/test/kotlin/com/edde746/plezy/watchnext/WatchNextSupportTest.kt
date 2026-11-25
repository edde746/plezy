package com.edde746.plezy.watchnext

import android.content.pm.PackageManager
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** Watch Next is Android TV's: a leanback launcher has the row, a phone and Fire TV have none. */
@RunWith(RobolectricTestRunner::class)
class WatchNextSupportTest {
    private val context = RuntimeEnvironment.getApplication()

    @Test
    fun onlyALeanbackDeviceThatIsntAFireTvHasTheRow() {
        assertNull(WatchNext.create(context), "a phone has no Watch Next row")

        shadowOf(context.packageManager).setSystemFeature(PackageManager.FEATURE_LEANBACK, true)
        assertNotNull(WatchNext.create(context))

        shadowOf(context.packageManager).setSystemFeature("amazon.hardware.fire_tv", true)
        assertNull(WatchNext.create(context), "Fire TV's launcher shows no Watch Next row")
    }
}
