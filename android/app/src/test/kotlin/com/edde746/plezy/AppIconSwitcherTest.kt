package com.edde746.plezy

import android.content.ComponentName
import android.content.pm.ActivityInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class AppIconSwitcherTest {
  private companion object {
    const val PACKAGE = "com.edde746.plezy"
  }

  private lateinit var packageManager: PackageManager

  private val launcher = ComponentName(PACKAGE, "$PACKAGE.MainActivity")
  private val midnight = ComponentName(PACKAGE, "$PACKAGE.appicon.midnight")
  private val ember = ComponentName(PACKAGE, "$PACKAGE.appicon.ember")

  @Before
  fun installManifest() {
    packageManager = RuntimeEnvironment.getApplication().packageManager
    val application = ApplicationInfo().apply {
      packageName = PACKAGE
      enabled = true
    }
    fun activity(name: String, enabled: Boolean, target: String?) = ActivityInfo().apply {
      packageName = PACKAGE
      this.name = name
      this.enabled = enabled
      targetActivity = target
      applicationInfo = application
    }
    // Mirrors AndroidManifest.xml: the real activity, the default launcher alias, and alternates
    // that ship disabled.
    shadowOf(packageManager).installPackage(
      PackageInfo().apply {
        packageName = PACKAGE
        applicationInfo = application
        activities = arrayOf(
          activity("$PACKAGE.PlezyActivity", enabled = true, target = null),
          activity("$PACKAGE.MainActivity", enabled = true, target = "$PACKAGE.PlezyActivity"),
          activity("$PACKAGE.appicon.midnight", enabled = false, target = "$PACKAGE.PlezyActivity"),
          activity("$PACKAGE.appicon.ember", enabled = false, target = "$PACKAGE.PlezyActivity")
        )
      }
    )
  }

  private fun switcher() = AppIconSwitcher(packageManager, PACKAGE)

  private fun state(component: ComponentName) = packageManager.getComponentEnabledSetting(component)

  @Test
  fun aFreshInstallShowsTheDefaultIconThroughTheExistingLauncherComponent() {
    val switcher = switcher()

    assertTrue(switcher.isSupported())
    assertEquals(AppIconSwitcher.DEFAULT_ICON, switcher.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(launcher))
  }

  @Test
  fun choosingAnAlternateLeavesItAsTheOnlyLauncherEntry() {
    val switcher = switcher()

    assertTrue(switcher.set("midnight"))

    assertEquals("midnight", switcher.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED, state(launcher))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_ENABLED, state(midnight))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(ember))
  }

  @Test
  fun switchingBetweenAlternatesDisablesThePreviousOne() {
    val switcher = switcher()
    switcher.set("midnight")

    switcher.set("ember")

    assertEquals("ember", switcher.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(midnight))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_ENABLED, state(ember))
  }

  @Test
  fun returningToTheDefaultRestoresTheManifestState() {
    val switcher = switcher()
    switcher.set("ember")

    switcher.set(AppIconSwitcher.DEFAULT_ICON)

    assertEquals(AppIconSwitcher.DEFAULT_ICON, switcher.current())
    for (component in listOf(launcher, midnight, ember)) {
      assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(component))
    }
  }

  @Test
  @Config(sdk = [32])
  fun beforeAndroid13TheSwitchIsAppliedComponentByComponent() {
    val switcher = switcher()

    switcher.set("ember")

    assertEquals("ember", switcher.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED, state(launcher))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_ENABLED, state(ember))
  }

  @Test
  fun anUnknownIconChangesNothing() {
    val switcher = switcher()
    switcher.set("midnight")

    assertFalse(switcher.set("retired"))

    assertEquals("midnight", switcher.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED, state(launcher))
  }

  @Test
  fun aSwitchInterruptedAfterEnablingReportsTheNewIcon() {
    // The process died between enabling ember and disabling the default on API < 33.
    packageManager.setComponentEnabledSetting(
      ember,
      PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
      PackageManager.DONT_KILL_APP
    )
    val switcher = switcher()

    assertEquals("ember", switcher.current())

    switcher.set("ember")
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED, state(launcher))
  }

  @Test
  fun fireTvAndCarLaunchersAreNotOffered() {
    shadowOf(packageManager).setSystemFeature("amazon.hardware.fire_tv", true)
    assertFalse(switcher().isSupported())

    shadowOf(packageManager).setSystemFeature("amazon.hardware.fire_tv", false)
    shadowOf(packageManager).setSystemFeature(PackageManager.FEATURE_AUTOMOTIVE, true)
    assertFalse(switcher().isSupported())
  }

  @Test
  fun androidTvLaunchersAreOffered() {
    shadowOf(packageManager).setSystemFeature(PackageManager.FEATURE_LEANBACK, true)

    assertTrue(switcher().isSupported())
  }

  @Test
  fun aPickWaitsForTheUserToLeaveButReadsAsCurrentAtOnce() {
    val selection = AppIconSelection(switcher())

    assertTrue(selection.choose("ember"))

    // The launcher alias that started the task stays enabled while the user is still in the app.
    assertEquals("ember", selection.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(launcher))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(ember))

    selection.applyPending()

    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED, state(launcher))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_ENABLED, state(ember))
    assertEquals("ember", selection.current())
  }

  @Test
  fun pickingTheShownIconAgainCancelsAWaitingPick() {
    val selection = AppIconSelection(switcher())
    selection.choose("ember")

    selection.choose(AppIconSwitcher.DEFAULT_ICON)
    selection.applyPending()

    assertEquals(AppIconSwitcher.DEFAULT_ICON, selection.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(launcher))
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(ember))
  }

  @Test
  fun anUnknownPickIsRefusedAndNothingWaits() {
    val selection = AppIconSelection(switcher())

    assertFalse(selection.choose("bogus"))
    selection.applyPending()

    assertEquals(AppIconSwitcher.DEFAULT_ICON, selection.current())
    assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DEFAULT, state(launcher))
  }
}
