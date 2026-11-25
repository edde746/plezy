package com.edde746.plezy.presentation.settings

import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.presentation.cast.CastDeviceKind
import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.app.AppPlatform
import com.edde746.plezy.app.DevicePlatform
import com.edde746.plezy.data.settings.DeviceSetting
import com.edde746.plezy.log.Log
import com.edde746.plezy.presentation.theme.AppTheme
import com.edde746.plezy.presentation.theme.Palette
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.profiles.profileUserScope
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.export.InvalidExportFileException
import com.edde746.plezy.settings.export.NoActiveProfileException
import com.edde746.plezy.settings.export.SettingsBackup
import com.edde746.plezy.strings.T
import com.edde746.plezy.updates.AppUpdates
import com.edde746.plezy.updates.ReleaseUpdate
import com.edde746.plezy.updates.Updater
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.launch

/**
 * The Settings hub: the pages, then Connections, Downloads, Controls, Advanced, Updates, Backup and About,
 * each row's id its focus key. Advanced edits the Watch Together relay in a dialog, resets every
 * setting and clears the image cache; Backup exports and imports the settings file; Updates, where [updates] is
 * available, checks for a newer release: the platform's updater
 * checks itself ([SettingsEvent.NativeUpdateCheck]), the GitHub check runs here. Services opens the trackers' screen,
 * its subtitle [servicesSummary].
 */
internal class HubPage(
    private val graph: AppGraph,
    private val platform: AppPlatform,
    private val session: SettingsSession,
    private val facts: StateFlow<SettingsFacts>,
    private val updates: AppUpdates?,
    parentScope: kotlinx.coroutines.CoroutineScope,
    servicesSummary: Flow<String> = flowOf(T.settings.servicesDescription),
) : RowPageStore(graph.data.deviceSettings, parentScope, { T.settings.title }) {
    // Seeded from the session as it is now, so the page's first rows are its rows (nothing moves under the pointer).
    private var hasLibraries = session.hasLibraries.value
    private var profiles: List<Profile> = session.profiles.value
    private var active: Profile? = session.activeProfile.value
    private var unlocked = false
    private var accounts: List<AccountPreferenceAccount> = emptyList()

    /** The accounts were listed once: the page shows from then on, Account preferences in its place. */
    private var accountsListed = false
    private var services = T.settings.servicesDescription
    private var checkingUpdates = false
    private var update: ReleaseUpdate? = null
    private var accountsRead: Job? = null
    private var castSenders: List<CastPeerInfo> = emptyList()

    init {
        follow(facts) {}
        follow(session.hasLibraries) { hasLibraries = it }
        follow(session.profiles) { profiles = it }
        follow(session.perks) { unlocked = it.unlocked }
        follow(session.activeProfile) {
            active = it
            readAccounts()
        }
        // The accounts follow the profile's connections, which its bind settles.
        follow(session.profileBinding) { if (!it) readAccounts() }
        follow(servicesSummary) { services = it }
        follow(session.castSenders) { castSenders = it }
        start(
            listOf(
                AppSettings.themeMode, AppSettings.customThemePalette, AppSettings.libraryDensity, AppSettings.downloadOnWifiOnly,
                AppSettings.autoRemoveWatchedDownloads, AppSettings.videoPlayerNavigationEnabled, AppSettings.allowCasting,
                AppSettings.watchPartyRelayUrl, AppSettings.crashReporting, AppSettings.enableDebugLogging, AppSettings.showPlaybackInfo,
                AppSettings.autoHidePlaybackInfo,
                AppSettings.autoCheckUpdatesOnStartup,
            ),
        )
    }

    override fun resumed() = readAccounts()

    override val loading: Boolean get() = !accountsListed

    override fun build(rows: Rows): List<SettingsGroup> {
        val facts = facts.value
        return listOfNotNull(
            SettingsGroup("main", null, mainRows(rows)),
            SettingsGroup("connections", T.connections.sectionTitle, connectionRows(rows)),
            // Log out on its own after them, while a profile is active; it asks first (the profile menu's confirmation).
            active?.let {
                SettingsGroup("logout", null, listOf(rows.link(LOGOUT, T.common.logout, null, SettingIcon.LOGOUT, LinkTrailing.NONE, destructive = true) { emit(SettingsEvent.OpenExternal(ExternalTarget.LOGOUT)) }))
            },
            if (facts.appleTv) null else SettingsGroup("downloads", T.settings.downloads, downloadRows(rows, facts)),
            SettingsGroup("controls", T.settings.controls, controlRows(rows, facts)),
            SettingsGroup("casting", T.cast.settings.group, castingRows(rows, facts)),
            SettingsGroup("advanced", T.settings.advanced, advancedRows(rows)),
            updates?.takeIf { it.available }?.let { SettingsGroup("updates", T.settings.updates, updateRows(rows, it)) },
            if (facts.hasFileDialogs) SettingsGroup("backup", T.settings.backup, backupRows(rows)) else null,
            SettingsGroup("about", null, listOf(rows.page(ABOUT, T.settings.about, T.settings.aboutDescription, SettingIcon.INFO, SettingsPageId.ABOUT))),
        )
    }

    private fun mainRows(rows: Rows): List<SettingRow> = listOfNotNull(
        rows.slot(SUPPORTER, SettingSlot.SUPPORTER),
        rows.page(GENERAL, T.settings.general, T.settings.generalDescription, SettingIcon.TUNE, SettingsPageId.GENERAL),
        rows.page(APPEARANCE, T.settings.appearance, appearanceSubtitle(), SettingIcon.PALETTE, SettingsPageId.APPEARANCE),
        rows.page(PLAYBACK, T.settings.videoPlayback, T.settings.videoPlaybackDescription, SettingIcon.PLAY_CIRCLE, SettingsPageId.VIDEO_PLAYBACK),
        if (hasLibraries) {
            rows.page(MANAGE_LIBRARIES, T.libraries.manageLibraries, T.settings.manageLibrariesDescription, SettingIcon.VIDEO_LIBRARY, SettingsPageId.MANAGE_LIBRARIES)
        } else {
            null
        },
        rows.link(SERVICES, T.settings.services, services, SettingIcon.SYNC) { emit(SettingsEvent.OpenExternal(ExternalTarget.SERVICES)) },
    )

    /** "{theme on screen} · Library Density {n}/{most}": the density as a place on its slider, not a bare number. */
    private fun appearanceSubtitle(): String {
        val custom = value(AppSettings.customThemePalette)?.let(Palette::of)
        val mode = AppTheme.resolve(value(AppSettings.themeMode), custom, unlocked, facts.value.tv).mode
        return "${themeLabel(mode)} · ${T.settings.libraryDensity} ${value(AppSettings.libraryDensity)}/${AppSettings.LIBRARY_DENSITY_RANGE.last}"
    }

    private fun connectionRows(rows: Rows): List<SettingRow> {
        val active = active
        val addSubtitle = if (active == null) T.connections.addConnectionSubtitleNoProfile else T.connections.addConnectionSubtitleScoped(active.displayName)
        val profilesSubtitle = when {
            profiles.size <= 1 -> T.profiles.summarySingle
            active != null -> T.profiles.summaryMultipleWithActive(profiles.size.toString(), active.displayName)
            else -> T.profiles.summaryMultiple(profiles.size.toString())
        }
        return listOfNotNull(
            rows.link(ADD_CONNECTION, T.connections.addConnection, addSubtitle, SettingIcon.ADD_LINK) { emit(SettingsEvent.OpenExternal(ExternalTarget.ADD_CONNECTION)) },
            rows.link(PROFILES, T.profiles.manageProfiles, profilesSubtitle, SettingIcon.GROUP) { emit(SettingsEvent.OpenExternal(ExternalTarget.PROFILES)) },
            accounts.takeIf { it.isNotEmpty() }?.let { list ->
                val subtitle = list.singleOrNull()?.let { T.accountPreferences.hubSubtitleSingle(it.target.label) }
                    ?: T.accountPreferences.hubSubtitleMultiple(list.size.toString())
                rows.page(ACCOUNT_PREFERENCES, T.accountPreferences.sectionTitle, subtitle, SettingIcon.MANAGE_ACCOUNTS, SettingsPageId.ACCOUNT_PREFERENCES)
            },
        )
    }

    private fun downloadRows(rows: Rows, facts: SettingsFacts): List<SettingRow> = listOfNotNull(
        if (facts.ios) null else rows.slot(DOWNLOAD_LOCATION, SettingSlot.DOWNLOAD_LOCATION),
        rows.toggle(DOWNLOAD_ON_WIFI_ONLY, AppSettings.downloadOnWifiOnly, T.settings.downloadOnWifiOnly, T.settings.downloadOnWifiOnlyDescription, SettingIcon.WIFI),
        rows.toggle(
            AUTO_REMOVE_WATCHED,
            AppSettings.autoRemoveWatchedDownloads,
            T.settings.autoRemoveWatchedDownloads,
            T.settings.autoRemoveWatchedDownloadsDescription,
            SettingIcon.DELETE_SWEEP,
        ),
        if (facts.android && facts.handheld) rows.slot(BACKGROUND_DOWNLOADS, SettingSlot.BACKGROUND_DOWNLOADS) else null,
    )

    /** Keyboard shortcuts and arrow-key navigation on desktop systems. */
    private fun controlRows(rows: Rows, facts: SettingsFacts): List<SettingRow> = buildList {
        if (facts.keyboardShortcutsSupported) {
            add(rows.page(VIDEO_PLAYER_CONTROLS, T.settings.videoPlayerControls, T.settings.keyboardShortcutsDescription, SettingIcon.KEYBOARD, SettingsPageId.KEYBOARD_SHORTCUTS))
            val navigation = AppSettings.videoPlayerNavigationOn(value(AppSettings.videoPlayerNavigationEnabled), facts.tv)
            add(
                rows.toggle(VIDEO_PLAYER_NAVIGATION, navigation, T.settings.videoPlayerNavigation, T.settings.videoPlayerNavigationDescription, SettingIcon.GAMEPAD) {
                    write(AppSettings.videoPlayerNavigationEnabled, it)
                },
            )
        }
    }

    /**
     * "Allow casting to this device" (on for a TV or a desktop until set) and the senders that cast here without
     * asking, each removed after a confirmation.
     */
    private fun castingRows(rows: Rows, facts: SettingsFacts): List<SettingRow> = buildList {
        val allowed = AppSettings.castingAllowed(value(AppSettings.allowCasting), facts.formFactor)
        add(rows.toggle(CAST_ALLOW, allowed, T.cast.settings.allow, T.cast.settings.allowDescription, SettingIcon.TV) { write(AppSettings.allowCasting, it) })
        for (sender in castSenders) {
            val id = CAST_SENDER + sender.id
            val icon = when (sender.kind) {
                CastDeviceKind.TV -> SettingIcon.TV
                CastDeviceKind.DESKTOP -> SettingIcon.DISPLAY
                CastDeviceKind.HANDHELD -> SettingIcon.PHONE_ANDROID
            }
            add(
                rows.link(id, sender.name, T.cast.settings.rememberedDescription, icon, trailing = LinkTrailing.NONE) {
                    confirmFirst(id, T.cast.settings.removeTitle(sender.name), T.cast.settings.removeMessage, T.cast.settings.remove, destructive = true) {
                        scope.launch { session.forgetCastSender(sender.id) }
                    }
                },
            )
        }
    }

    private fun advancedRows(rows: Rows): List<SettingRow> {
        // Built with the page, so the dialog's intents reach this build's handlers.
        val relay = relayRow(rows)
        return listOf(
            rows.link(
                WATCH_TOGETHER_RELAY, T.settings.watchTogetherRelay, null, SettingIcon.DNS,
                valueLabel = value(AppSettings.watchPartyRelayUrl) ?: T.settings.watchTogetherRelayPublic,
            ) {
                emit(SettingsEvent.EditText(relay))
            },
            rows.toggle(CRASH_REPORTING, AppSettings.crashReporting, T.settings.crashReporting, T.settings.crashReportingDescription, SettingIcon.BUG_REPORT),
            rows.toggle(DEBUG_LOGGING, AppSettings.enableDebugLogging, T.settings.debugLogging, T.settings.debugLoggingDescription, SettingIcon.CODE),
            rows.toggle(SHOW_PLAYBACK_INFO, AppSettings.showPlaybackInfo, T.player.info.show, T.settings.showPlaybackInfoDescription, SettingIcon.SHOW_CHART),
            rows.toggle(AUTO_HIDE_PLAYBACK_INFO, AppSettings.autoHidePlaybackInfo, T.settings.autoHidePlaybackInfo, T.settings.autoHidePlaybackInfoDescription, SettingIcon.VISIBILITY_OFF),
            rows.page(VIEW_LOGS, T.settings.viewLogs, T.settings.viewLogsDescription, SettingIcon.ARTICLE, SettingsPageId.LOGS),
            rows.link(CLEAR_IMAGE_CACHE, T.settings.clearImageCache, T.settings.clearImageCacheDescription, SettingIcon.IMAGE, subtitleLines = 2) {
                confirmFirst(CLEAR_IMAGE_CACHE, T.settings.clearImageCache, T.settings.clearImageCacheDescription, T.common.clear, destructive = false) {
                    emit(SettingsEvent.ClearImageCache)
                    message(T.settings.clearImageCacheSuccess)
                }
            },
            rows.link(RESET_SETTINGS, T.settings.resetSettings, T.settings.resetSettingsDescription, SettingIcon.RESTORE) {
                confirmFirst(RESET_SETTINGS, T.settings.resetSettings, T.settings.resetSettingsDescription, T.common.reset, destructive = true) { resetAll() }
            },
        )
    }

    /**
     * The relay dialog's field: blank stores nothing (the public relays), a base URL is stored canonical, any
     * other text is refused. Reset to Default removes the stored relay at once and closes the dialog.
     */
    private fun relayRow(rows: Rows): SettingTextRow = rows.text(
        WATCH_TOGETHER_RELAY,
        T.settings.watchTogetherRelay,
        null,
        value(AppSettings.watchPartyRelayUrl).orEmpty(),
        T.common.url,
        T.settings.watchTogetherRelayHint,
        T.settings.resetToDefault,
        SettingIcon.DNS,
        reset = {
            scope.launch { guarded("removing the relay") { settings.reset(AppSettings.watchPartyRelayUrl) } }
            null
        },
    ) { typed ->
        if (typed.isBlank()) {
            scope.launch { guarded("removing the relay") { settings.reset(AppSettings.watchPartyRelayUrl) } }
            null
        } else {
            val canonical = AppSettings.watchPartyRelayUrl.normalize(typed.trim())
            if (canonical == null) {
                T.settings.watchTogetherRelayInvalid
            } else {
                write(AppSettings.watchPartyRelayUrl, canonical)
                null
            }
        }
    }

    /** Reset Settings: the downloads location first, then every resettable setting. */
    private fun resetAll() {
        scope.launch {
            val reset = guarded("resetting the settings") {
                session.resetDownloadLocation()
                graph.data.settingsBackup.resetAll()
            }
            if (reset) message(T.settings.resetSettingsSuccess)
        }
    }

    private fun updateRows(rows: Rows, updates: AppUpdates): List<SettingRow> {
        val found = update
        val check = if (found != null) {
            rows.link(CHECK_FOR_UPDATES, T.settings.updateAvailable, T.update.versionAvailable(found.latestVersion), SettingIcon.SYSTEM_UPDATE, accent = true) {
                emit(found.event())
            }
        } else {
            val icon = if (updates.updater == Updater.NATIVE) SettingIcon.SYSTEM_UPDATE else SettingIcon.CHECK_CIRCLE
            rows.link(CHECK_FOR_UPDATES, T.settings.checkForUpdates, null, icon, busy = checkingUpdates) { checkForUpdates(updates) }
        }
        return listOf(
            check,
            rows.toggle(
                AUTO_CHECK_UPDATES,
                AppSettings.autoCheckUpdatesOnStartup,
                T.settings.autoCheckUpdatesOnStartup,
                T.settings.autoCheckUpdatesOnStartupDescription,
                SettingIcon.SYSTEM_UPDATE,
            ),
        )
    }

    private fun checkForUpdates(updates: AppUpdates) {
        if (updates.updater == Updater.NATIVE) {
            emit(SettingsEvent.NativeUpdateCheck)
            return
        }
        if (checkingUpdates) return
        checkingUpdates = true
        publish()
        scope.launch {
            val found = try {
                updates.checkNow()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "checking for updates failed" }
                checkingUpdates = false
                publish()
                message(T.update.checkFailed, error = true)
                return@launch
            }
            checkingUpdates = false
            update = found
            publish()
            if (found == null) message(T.update.latestVersion) else emit(found.event())
        }
    }

    private fun ReleaseUpdate.event() = SettingsEvent.UpdateAvailable(latestVersion, releaseNotes.ifBlank { null }, releaseUrl)

    private fun backupRows(rows: Rows): List<SettingRow> = listOf(
        rows.link(EXPORT_SETTINGS, T.settings.exportSettings, T.settings.exportSettingsDescription, SettingIcon.UPLOAD) { export() },
        rows.link(IMPORT_SETTINGS, T.settings.importSettings, T.settings.importSettingsDescription, SettingIcon.DOWNLOAD) {
            confirmFirst(IMPORT_SETTINGS, T.settings.importSettings, T.settings.importSettingsConfirm, T.settings.importSettings, destructive = false) {
                emit(SettingsEvent.OpenFile)
            }
        },
    )

    /** Export: the settings file for the user to save as `plezy-settings-YYYYMMDD.json`. */
    private fun export() {
        scope.launch {
            val now = graph.clock.now()
            var bytes: ByteArray? = null
            val built = guarded("exporting the settings") {
                bytes = graph.data.settingsBackup.export(active?.id?.let(::profileUserScope), graph.appVersion, exportPlatform(), now)
            }
            val file = bytes
            if (!built || file == null) return@launch
            val (year, month, day) = localDate(now.toEpochMilliseconds())
            emit(SettingsEvent.SaveFile(SettingsBackup.defaultFileName(year, month, day), file))
        }
    }

    override fun exported(saved: Boolean, error: String?) {
        when {
            saved -> message(T.settings.exportSettingsSuccess)
            error != null -> {
                Log.e(TAG) { "saving the settings file failed: $error" }
                message(T.settings.saveFailed, error = true)
            }
        }
    }

    /** Import: the picked file replaces the settings it carries; the libraries are read again after. */
    override fun imported(bytes: ByteArray?) {
        if (bytes == null) return
        scope.launch {
            val profile = active?.id?.let(::profileUserScope)
            val failure = try {
                graph.data.settingsBackup.import(bytes, profile)
                null
            } catch (e: CancellationException) {
                throw e
            } catch (e: NoActiveProfileException) {
                T.settings.importSettingsNoUser
            } catch (e: InvalidExportFileException) {
                Log.w(TAG, e) { "the picked file isn't a settings export" }
                T.settings.importSettingsInvalidFile
            } catch (e: Exception) {
                Log.e(TAG, e) { "importing the settings failed" }
                T.settings.saveFailed
            }
            if (failure != null) {
                message(failure, error = true)
                return@launch
            }
            guarded("reloading the libraries") { session.reloadLibraries() }
            message(T.settings.importSettingsSuccess)
        }
    }

    private fun readAccounts() {
        accountsRead?.cancel()
        // A read while the profile binds may miss its connections: the page waits for the read after.
        val settled = !session.profileBinding.value
        accountsRead = scope.launch {
            accounts = try {
                session.accountPreferenceAccounts()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, e) { "listing the accounts with preferences failed" }
                emptyList()
            }
            if (settled) accountsListed = true
            publish()
        }
    }

    /** The settings file's `platform`, as Plezy's earlier releases named the OS. */
    private fun exportPlatform(): String = when (val os = facts.value.os) {
        DevicePlatform.ANDROID_TV -> DevicePlatform.ANDROID
        DevicePlatform.IPADOS, DevicePlatform.TVOS -> DevicePlatform.IOS
        else -> os
    }

    companion object {
        const val SUPPORTER = "supporter"
        const val GENERAL = "general"
        const val APPEARANCE = "appearance"
        const val PLAYBACK = "playback"
        const val MANAGE_LIBRARIES = "manage_libraries"
        const val SERVICES = "services"
        const val ADD_CONNECTION = "add_connection"
        const val PROFILES = "profiles"
        const val ACCOUNT_PREFERENCES = "account_preferences"
        const val LOGOUT = "logout"
        const val DOWNLOAD_LOCATION = "download_location"
        const val DOWNLOAD_ON_WIFI_ONLY = "download_on_wifi_only"
        const val AUTO_REMOVE_WATCHED = "auto_remove_watched_downloads"
        const val BACKGROUND_DOWNLOADS = "background_downloads"
        const val VIDEO_PLAYER_CONTROLS = "video_player_controls"
        const val VIDEO_PLAYER_NAVIGATION = "video_player_navigation"
        const val CAST_ALLOW = "cast_allow"
        const val CAST_SENDER = "cast_sender_"
        const val WATCH_TOGETHER_RELAY = "watch_together_relay"
        const val CRASH_REPORTING = "crash_reporting"
        const val DEBUG_LOGGING = "debug_logging"
        const val SHOW_PLAYBACK_INFO = "show_playback_info"
        const val AUTO_HIDE_PLAYBACK_INFO = "auto_hide_playback_info"
        const val VIEW_LOGS = "view_logs"
        const val CLEAR_IMAGE_CACHE = "clear_image_cache"
        const val RESET_SETTINGS = "reset_settings"
        const val CHECK_FOR_UPDATES = "check_for_updates"
        const val AUTO_CHECK_UPDATES = "auto_check_updates_on_startup"
        const val EXPORT_SETTINGS = "export_settings"
        const val IMPORT_SETTINGS = "import_settings"
        const val ABOUT = "about"
    }
}
