package com.edde746.plezy.downloads.android

import com.edde746.plezy.downloads.BackgroundSettingsTarget
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class BackgroundWorkClassifierTest {
    private fun verdictFor(signals: BackgroundWorkSignals) = BackgroundWorkClassifier.verdict(signals)

    @Test
    fun unknownSignalsAreTreatedAsHealthy() {
        val signals = BackgroundWorkSignals()

        assertEquals(emptyList(), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
    }

    @Test
    fun anUnrestrictedDeviceIsHealthy() {
        val signals = BackgroundWorkSignals(
            backgroundRestricted = false,
            standbyBucket = 10,
            notificationsEnabled = true,
            downloadChannelBlocked = false,
            dataSaverRestricted = false,
            ignoringBatteryOptimizations = false,
        )

        assertEquals(emptyList(), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
    }

    @Test
    fun aMissingBatteryWhitelistAloneNeverWarns() {
        val signals = BackgroundWorkSignals(backgroundRestricted = false, standbyBucket = 20, notificationsEnabled = true, ignoringBatteryOptimizations = false)

        assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(signals))
    }

    @Test
    fun theRareBucketIsNotRestricted() {
        for (bucket in listOf(10, 20, 30, 40)) assertFalse(BackgroundWorkClassifier.isRestrictedBucket(bucket))

        assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(BackgroundWorkSignals(standbyBucket = 40, notificationsEnabled = true)))
    }

    @Test
    fun theRestrictedAndNeverBucketsBlock() {
        for (bucket in listOf(BackgroundWorkClassifier.BUCKET_RESTRICTED, BackgroundWorkClassifier.BUCKET_NEVER)) {
            assertTrue(BackgroundWorkClassifier.isRestrictedBucket(bucket))
            val signals = BackgroundWorkSignals(standbyBucket = bucket, notificationsEnabled = true)
            assertEquals(listOf(BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED), BackgroundWorkClassifier.reasons(signals))
            assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
        }
    }

    @Test
    fun aBackgroundRestrictionBlocksAndLeadsTheReasons() {
        val signals = BackgroundWorkSignals(
            backgroundRestricted = true,
            standbyBucket = BackgroundWorkClassifier.BUCKET_RESTRICTED,
            notificationsEnabled = true,
            downloadChannelBlocked = false,
        )

        assertEquals(
            listOf(BackgroundWorkClassifier.REASON_BACKGROUND_RESTRICTED, BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED),
            BackgroundWorkClassifier.reasons(signals),
        )
        assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
    }

    @Test
    fun disabledNotificationsBlockOnAndroid13AndNewer() {
        val signals = BackgroundWorkSignals(sdkInt = 33, backgroundRestricted = false, notificationsEnabled = false)

        assertEquals(listOf(BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
    }

    @Test
    fun disabledNotificationsOnlyDegradeBeforeAndroid13() {
        assertEquals(
            BackgroundWorkClassifier.VERDICT_DEGRADED,
            verdictFor(BackgroundWorkSignals(sdkInt = 32, backgroundRestricted = false, notificationsEnabled = false)),
        )
    }

    @Test
    fun aMutedDownloadChannelIsDegraded() {
        val signals = BackgroundWorkSignals(notificationsEnabled = true, downloadChannelBlocked = true)

        assertEquals(listOf(BackgroundWorkClassifier.REASON_DOWNLOAD_CHANNEL_BLOCKED), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_DEGRADED, verdictFor(signals))
    }

    @Test
    fun appWideNotificationDenialSupersedesTheChannelReason() {
        val signals = BackgroundWorkSignals(sdkInt = 33, notificationsEnabled = false, downloadChannelBlocked = true)

        assertEquals(listOf(BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(signals))
    }

    @Test
    fun anAbsentChannelIsNotAFault() {
        assertEquals(BackgroundWorkClassifier.VERDICT_OK, verdictFor(BackgroundWorkSignals(notificationsEnabled = true, downloadChannelBlocked = null)))
    }

    @Test
    fun dataSaverOnlyDegrades() {
        val signals = BackgroundWorkSignals(backgroundRestricted = false, standbyBucket = 20, notificationsEnabled = true, dataSaverRestricted = true)

        assertEquals(listOf(BackgroundWorkClassifier.REASON_DATA_SAVER), BackgroundWorkClassifier.reasons(signals))
        assertEquals(BackgroundWorkClassifier.VERDICT_DEGRADED, verdictFor(signals))
    }

    @Test
    fun aBlockingReasonOutranksDataSaver() {
        assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, verdictFor(BackgroundWorkSignals(backgroundRestricted = true, dataSaverRestricted = true)))
    }

    @Test
    fun theMapCarriesVerdictReasonsAndRawSignals() {
        val map = BackgroundWorkClassifier.toMap(
            BackgroundWorkSignals(
                sdkInt = 33,
                backgroundRestricted = true,
                standbyBucket = BackgroundWorkClassifier.BUCKET_RESTRICTED,
                notificationsEnabled = false,
                downloadChannelBlocked = true,
                dataSaverRestricted = false,
                ignoringBatteryOptimizations = false,
            ),
        )

        assertEquals(BackgroundWorkClassifier.VERDICT_BLOCKED, map["verdict"])
        assertEquals(
            listOf(
                BackgroundWorkClassifier.REASON_BACKGROUND_RESTRICTED,
                BackgroundWorkClassifier.REASON_STANDBY_RESTRICTED,
                BackgroundWorkClassifier.REASON_NOTIFICATIONS_DISABLED,
            ),
            map["reasons"],
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
        assertNull(map["standbyBucket"])
        assertNull(map["backgroundRestricted"])
    }

    @Test
    fun everyTargetFallsBackToTheAppDetailsPage() {
        for (target in BackgroundSettingsTarget.entries) {
            val last = BackgroundSettingsIntents.specsFor(target, "com.edde746.plezy", 35).last()
            assertEquals("android.settings.APPLICATION_DETAILS_SETTINGS", last.action)
            assertEquals("package:com.edde746.plezy", last.data)
        }
    }

    @Test
    fun theNotificationChannelTargetAddressesTheDownloadsChannel() {
        val first = BackgroundSettingsIntents.specsFor(BackgroundSettingsTarget.NOTIFICATION_CHANNEL, "com.edde746.plezy", 35).first()

        assertEquals("android.settings.CHANNEL_NOTIFICATION_SETTINGS", first.action)
        assertEquals("com.edde746.plezy", first.stringExtras["android.provider.extra.APP_PACKAGE"])
        assertEquals(DownloadNotifications.CHANNEL, first.stringExtras["android.provider.extra.CHANNEL_ID"])
    }

    @Test
    fun theAppNotificationTargetNeedsNoExistingChannel() {
        val first = BackgroundSettingsIntents.specsFor(BackgroundSettingsTarget.APP_NOTIFICATIONS, "com.edde746.plezy", 35).first()

        assertEquals("android.settings.APP_NOTIFICATION_SETTINGS", first.action)
        assertEquals("com.edde746.plezy", first.stringExtras["android.provider.extra.APP_PACKAGE"])
        assertNull(first.stringExtras["android.provider.extra.CHANNEL_ID"])
    }

    @Test
    fun preOreoNotificationRemediesFallBackToAppDetails() {
        for (target in listOf(BackgroundSettingsTarget.APP_NOTIFICATIONS, BackgroundSettingsTarget.NOTIFICATION_CHANNEL)) {
            val first = BackgroundSettingsIntents.specsFor(target, "com.edde746.plezy", 25).first()
            assertEquals("android.settings.APPLICATION_DETAILS_SETTINGS", first.action)
            assertEquals("package:com.edde746.plezy", first.data)
        }
    }
}
