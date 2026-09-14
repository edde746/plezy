package com.edde746.plezy

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class BackgroundWorkDiagnosticsTest {

  @Test
  fun unknownSignalsAreTreatedAsHealthy() {
    val signals = BackgroundWorkSignals()

    assertEquals(emptyList<String>(), BackgroundWorkClassifier.reasons(signals))
    assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
  }

  @Test
  fun unrestrictedDeviceIsHealthy() {
    val signals = BackgroundWorkSignals(
      backgroundRestricted = false,
      standbyBucket = 10,
      notificationsEnabled = true,
      downloadChannelBlocked = false,
      dataSaverRestricted = false,
      ignoringBatteryOptimizations = false
    )

    assertEquals(emptyList<String>(), BackgroundWorkClassifier.reasons(signals))
    assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
  }

  @Test
  fun missingBatteryWhitelistAloneNeverWarns() {
    // The overwhelming majority of healthy installs are not whitelisted; a
    // warning keyed off this would fire on essentially every device.
    val signals = BackgroundWorkSignals(
      backgroundRestricted = false,
      standbyBucket = 20,
      notificationsEnabled = true,
      ignoringBatteryOptimizations = false
    )

    assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
  }

  @Test
  fun rareBucketIsNotRestricted() {
    // RARE is reached by ordinary disuse and is not a user-imposed limit.
    assertFalse(BackgroundWorkClassifier.isRestrictedBucket(10))
    assertFalse(BackgroundWorkClassifier.isRestrictedBucket(20))
    assertFalse(BackgroundWorkClassifier.isRestrictedBucket(30))
    assertFalse(BackgroundWorkClassifier.isRestrictedBucket(40))

    val signals = BackgroundWorkSignals(standbyBucket = 40, notificationsEnabled = true)
    assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
  }

  @Test
  fun restrictedAndNeverBucketsBlock() {
    assertTrue(BackgroundWorkClassifier.isRestrictedBucket(BackgroundWorkClassifier.BUCKET_RESTRICTED))
    assertTrue(BackgroundWorkClassifier.isRestrictedBucket(BackgroundWorkClassifier.BUCKET_NEVER))

    for (bucket in listOf(BackgroundWorkClassifier.BUCKET_RESTRICTED, BackgroundWorkClassifier.BUCKET_NEVER)) {
      val signals = BackgroundWorkSignals(standbyBucket = bucket, notificationsEnabled = true)
      assertEquals(
        listOf(BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED),
        BackgroundWorkClassifier.reasons(signals)
      )
      assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
    }
  }

  @Test
  fun backgroundRestrictionBlocksAndLeadsTheReasons() {
    // The Samsung "Background usage limits" case that motivated this: both the
    // AOSP restriction flag and the standby bucket flip together.
    val signals = BackgroundWorkSignals(
      backgroundRestricted = true,
      standbyBucket = BackgroundWorkClassifier.BUCKET_RESTRICTED,
      notificationsEnabled = true,
      downloadChannelBlocked = false
    )

    assertEquals(
      listOf(
        BackgroundWorkClassifier.REASON_BACKGROUND_RESTRICTED,
        BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED
      ),
      BackgroundWorkClassifier.reasons(signals)
    )
    assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
  }

  @Test
  fun disabledNotificationsBlockOnAndroid13AndNewer() {
    val signals = BackgroundWorkSignals(
      sdkInt = 33,
      backgroundRestricted = false,
      notificationsEnabled = false
    )

    assertEquals(
      listOf(BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED),
      BackgroundWorkClassifier.reasons(signals)
    )
    assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
  }

  @Test
  fun disabledNotificationsOnlyDegradeBeforeAndroid13() {
    val signals = BackgroundWorkSignals(
      sdkInt = 32,
      backgroundRestricted = false,
      notificationsEnabled = false
    )

    assertEquals(BackgroundWorkClassifier.VERDICT_DEGRADED, verdictFor(signals))
  }

  @Test
  fun mutedDownloadChannelIsDegraded() {
    val signals = BackgroundWorkSignals(notificationsEnabled = true, downloadChannelBlocked = true)

    assertEquals(
      listOf(BackgroundWorkClassifier.REASON_DOWNLOAD_CHANNEL_BLOCKED),
      BackgroundWorkClassifier.reasons(signals)
    )
    assertEquals(BackgroundWorkClassifier.VERDICT_DEGRADED, verdictFor(signals))
  }

  @Test
  fun appWideNotificationDenialSupersedesTheChannelReason() {
    val signals = BackgroundWorkSignals(sdkInt = 33, notificationsEnabled = false, downloadChannelBlocked = true)

    assertEquals(
      listOf(BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED),
      BackgroundWorkClassifier.reasons(signals)
    )
    assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
  }

  @Test
  fun absentChannelIsNotAFault() {
    // The plugin creates its channel on first download; before then there is
    // nothing to warn about.
    val signals = BackgroundWorkSignals(notificationsEnabled = true, downloadChannelBlocked = null)

    assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
  }

  @Test
  fun dataSaverOnlyDegrades() {
    val signals = BackgroundWorkSignals(
      backgroundRestricted = false,
      standbyBucket = 20,
      notificationsEnabled = true,
      dataSaverRestricted = true
    )

    assertEquals(listOf(BackgroundWorkClassifier.REASON_DATA_SAVER), BackgroundWorkClassifier.reasons(signals))
    assertEquals(BackgroundWorkClassifier.VERDICT_DEGRADED, verdictFor(signals))
  }

  @Test
  fun blockingReasonOutranksDataSaver() {
    val signals = BackgroundWorkSignals(backgroundRestricted = true, dataSaverRestricted = true)

    assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
  }

  @Test
  fun mapCarriesVerdictReasonsAndRawSignals() {
    val signals = BackgroundWorkSignals(
      sdkInt = 33,
      backgroundRestricted = true,
      standbyBucket = BackgroundWorkClassifier.BUCKET_RESTRICTED,
      notificationsEnabled = false,
      downloadChannelBlocked = true,
      dataSaverRestricted = false,
      ignoringBatteryOptimizations = false
    )

    val map = BackgroundWorkClassifier.toMap(signals)

    assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, map["verdict"])
    assertEquals(
      listOf(
        BackgroundWorkClassifier.REASON_BACKGROUND_RESTRICTED,
        BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED,
        BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED
      ),
      map["reasons"]
    )
    assertEquals(33, map["sdkInt"])
    assertEquals(true, map["backgroundRestricted"])
    assertEquals(BackgroundWorkClassifier.BUCKET_RESTRICTED, map["standbyBucket"])
    assertEquals(false, map["notificationsEnabled"])
    assertEquals(true, map["downloadChannelBlocked"])
    assertEquals(false, map["dataSaverRestricted"])
    assertEquals(false, map["ignoringBatteryOptimizations"])
  }

  @Test
  fun unknownSignalsSurviveAsNullsInTheMap() {
    val map = BackgroundWorkClassifier.toMap(BackgroundWorkSignals())

    assertEquals(BackgroundWorkClassifier.VERDICT_OK, map["verdict"])
    assertTrue(map.containsKey("standbyBucket"))
    assertEquals(null, map["standbyBucket"])
    assertEquals(null, map["backgroundRestricted"])
  }

  @Test
  fun settingsTargetsParseFromTheirWireIds() {
    assertEquals(BackgroundSettingsTarget.APP_DETAILS, BackgroundSettingsTarget.fromId("app_details"))
    assertEquals(
      BackgroundSettingsTarget.APP_NOTIFICATIONS,
      BackgroundSettingsTarget.fromId("app_notifications")
    )
    assertEquals(
      BackgroundSettingsTarget.NOTIFICATION_CHANNEL,
      BackgroundSettingsTarget.fromId("notification_channel")
    )
    assertEquals(null, BackgroundSettingsTarget.fromId("nonsense"))
    assertEquals(null, BackgroundSettingsTarget.fromId(null))
  }

  @Test
  fun everyTargetFallsBackToTheAppDetailsPage() {
    for (target in BackgroundSettingsTarget.entries) {
      val specs = BackgroundSettingsIntents.specsFor(target, "com.edde746.plezy", 35)
      assertTrue(specs.isNotEmpty())
      val last = specs.last()
      assertEquals("android.settings.APPLICATION_DETAILS_SETTINGS", last.action)
      assertEquals("package:com.edde746.plezy", last.data)
    }
  }

  @Test
  fun notificationChannelTargetAddressesTheDownloaderChannel() {
    val first = BackgroundSettingsIntents.specsFor(
      BackgroundSettingsTarget.NOTIFICATION_CHANNEL,
      "com.edde746.plezy",
      35
    ).first()

    assertEquals("android.settings.CHANNEL_NOTIFICATION_SETTINGS", first.action)
    assertEquals("com.edde746.plezy", first.stringExtras["android.provider.extra.APP_PACKAGE"])
    assertEquals(
      BackgroundWorkDiagnostics.DOWNLOAD_NOTIFICATION_CHANNEL_ID,
      first.stringExtras["android.provider.extra.CHANNEL_ID"]
    )
  }

  @Test
  fun appNotificationTargetDoesNotRequireAnExistingChannel() {
    val first = BackgroundSettingsIntents.specsFor(
      BackgroundSettingsTarget.APP_NOTIFICATIONS,
      "com.edde746.plezy",
      35
    ).first()

    assertEquals("android.settings.APP_NOTIFICATION_SETTINGS", first.action)
    assertEquals("com.edde746.plezy", first.stringExtras["android.provider.extra.APP_PACKAGE"])
    assertEquals(null, first.stringExtras["android.provider.extra.CHANNEL_ID"])
  }

  @Test
  fun preOreoNotificationRemediesFallBackToAppDetails() {
    for (target in listOf(BackgroundSettingsTarget.APP_NOTIFICATIONS, BackgroundSettingsTarget.NOTIFICATION_CHANNEL)) {
      val first = BackgroundSettingsIntents.specsFor(target, "com.edde746.plezy", 25).first()
      assertEquals("android.settings.APPLICATION_DETAILS_SETTINGS", first.action)
      assertEquals("package:com.edde746.plezy", first.data)
    }
  }

  private fun verdictFor(signals: BackgroundWorkSignals): String = BackgroundWorkClassifier.verdict(signals)
}
