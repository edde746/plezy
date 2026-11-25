package com.edde746.plezy.app

import com.edde746.plezy.model.DeviceRegion
import com.edde746.plezy.playback.SystemMediaAccessibility
import com.edde746.plezy.strings.InterfaceLocale
import kotlin.concurrent.Volatile

/**
 * The system's settings the shared code follows, which only the platform can read: its languages ([InterfaceLocale]),
 * its region ([DeviceRegion]) and its caption and audio-description settings ([SystemMediaAccessibility]). Each
 * platform reports them all at once ([report]) where its process starts, before anything reads them: Android's
 * Application (a process WorkManager starts for the download worker has no activity), the desktop's `main`, Apple's
 * app launch. Their later changes go to each one's own setter. Building the shared core ([AppBootstrap]) before the
 * report is an error: without it the interface would be in English, every stream's country list ignored and the
 * captions off, whatever the system says.
 */
object SystemInputs {
    /** Whether [report] ran in this process; internal for the tests, which start a case unreported. */
    @Volatile
    internal var reported = false

    /**
     * @param languages the system's preferred languages as BCP 47 tags, most preferred first (the app's own first where
     *   the system's per-app language setting is used).
     * @param region the system's region as ISO 3166-1 alpha-2 (`US`, any case); null when the system names none.
     * @param captions captions whenever there is speech; off where the system has no such setting.
     * @param audioDescriptions an audio description of the picture; off where the system has no such setting.
     */
    fun report(languages: List<String>, region: String?, captions: Boolean, audioDescriptions: Boolean) {
        InterfaceLocale.setSystemLanguages(languages)
        DeviceRegion.setSystemRegion(region)
        SystemMediaAccessibility.report(captions, audioDescriptions)
        reported = true
    }

    /** Throws unless the platform has reported: the shared core is about to read the settings. */
    internal fun requireReported() = check(reported) {
        "The platform builds the shared core before it reported the system's settings (SystemInputs.report): " +
            "it would show English, ignore streams' country lists and leave captions off whatever the system says"
    }
}
