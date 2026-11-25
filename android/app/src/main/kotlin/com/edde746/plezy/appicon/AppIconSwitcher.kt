package com.edde746.plezy.appicon

import android.content.ComponentName
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.os.Build
import com.edde746.plezy.log.Log
import com.edde746.plezy.supporter.AppIconError
import com.edde746.plezy.supporter.AppIconSwitch

/**
 * Switches the launcher icon and Android TV banner between the activity-aliases that target [com.edde746.plezy.PlezyActivity]:
 * `.MainActivity` is the default icon, `.appicon.<id>` are the Supporter alternates. Exactly one alias is enabled.
 *
 * `.MainActivity` keeps the component name the launcher activity always had, so home-screen shortcuts and TV favourites
 * still resolve, and every alias keeps its manifest state until the user picks another icon. Choosing the default again
 * puts every alias back to that state.
 */
internal class AppIconSwitcher(private val packageManager: PackageManager, private val packageName: String) {
    companion object {
        const val DEFAULT_ICON = "default"
        private const val DEFAULT_ALIAS_SUFFIX = ".MainActivity"
        private const val ALTERNATE_ALIAS_MARKER = ".appicon."
        private const val FEATURE_FIRE_TV = "amazon.hardware.fire_tv"
    }

    private class Change(val component: ComponentName, val state: Int, val enables: Boolean)

    /** Launcher aliases by icon id, read from the manifest, so the manifest's list is the only one. */
    private val aliases: Map<String, ActivityInfo> by lazy(LazyThreadSafetyMode.NONE) { loadAliases() }

    /**
     * Fire TV's launcher draws Appstore apps from their store listing art, and Android Automotive is no target for
     * alternate icons: neither offers the picker. Android TV launchers do.
     */
    fun isSupported(): Boolean = !packageManager.hasSystemFeature(FEATURE_FIRE_TV) &&
        !packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE) &&
        DEFAULT_ICON in aliases &&
        aliases.size > 1

    /**
     * The icon the launcher shows. A switch interrupted between its steps before Android 13 can leave the default and an
     * alternate both enabled; the alternate is the one the user picked last.
     */
    fun current(): String = aliases.entries.filter { (_, info) -> isEnabled(info) }.map { it.key }
        .firstOrNull { it != DEFAULT_ICON } ?: DEFAULT_ICON

    /** Whether [id] names one of the icons. */
    fun has(id: String): Boolean = id in aliases

    /** Enables [id]'s alias and disables the rest. False, changing nothing, when [id] is no icon. */
    fun set(id: String): Boolean {
        if (id !in aliases) return false
        val changes = aliases.mapNotNull { (alias, info) ->
            val enable = alias == id
            val state = when {
                enable == info.enabled -> PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
                enable -> PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else -> PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            val component = info.component()
            if (packageManager.getComponentEnabledSetting(component) == state) null else Change(component, state, enable)
        }
            // Enable before disabling: if the process dies part way through, the app keeps a launcher entry.
            .sortedByDescending { it.enables }
        if (changes.isEmpty()) return true
        // DONT_KILL_APP keeps the process; the activities started through a disabled alias still finish, which is why
        // AppIconSelection waits for the user to leave.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // One atomic update and one package-changed broadcast, so launchers refresh once.
            packageManager.setComponentEnabledSettings(
                changes.map { PackageManager.ComponentEnabledSetting(it.component, it.state, PackageManager.DONT_KILL_APP) },
            )
        } else {
            for (change in changes) {
                packageManager.setComponentEnabledSetting(change.component, change.state, PackageManager.DONT_KILL_APP)
            }
        }
        return true
    }

    @Suppress("DEPRECATION")
    private fun loadAliases(): Map<String, ActivityInfo> {
        val activities = packageManager.getPackageInfo(
            packageName,
            PackageManager.GET_ACTIVITIES or PackageManager.MATCH_DISABLED_COMPONENTS,
        ).activities ?: return emptyMap()
        return activities.mapNotNull { info -> iconId(info)?.let { it to info } }.toMap()
    }

    private fun iconId(info: ActivityInfo): String? {
        if (info.targetActivity == null) return null
        if (info.name.endsWith(DEFAULT_ALIAS_SUFFIX)) return DEFAULT_ICON
        val marker = info.name.lastIndexOf(ALTERNATE_ALIAS_MARKER)
        return if (marker < 0) null else info.name.substring(marker + ALTERNATE_ALIAS_MARKER.length)
    }

    private fun isEnabled(info: ActivityInfo): Boolean = when (packageManager.getComponentEnabledSetting(info.component())) {
        PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
        PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> info.enabled
        else -> false
    }

    private fun ActivityInfo.component() = ComponentName(this.packageName, this.name)
}

/**
 * The icon the user picked, applied once they leave the app ([applyPending], from the activity's onStop).
 *
 * Android finishes every activity started through a component that gets disabled, and the running task was almost
 * always started through the launcher alias a switch disables: applied at once, the switch would close Plezy in the
 * user's face (DONT_KILL_APP keeps only the process). Deferred to the moment the user leaves, the task closes behind
 * the launcher, which already shows the new icon when it comes up.
 *
 * One per process ([com.edde746.plezy.AndroidPlatform]), so a recreated activity keeps the pick. A process killed
 * before the user leaves loses it, and the picker then shows the icon the launcher still has.
 */
internal class AppIconSelection(private val switcher: AppIconSwitcher) : AppIconSwitch {
    private var pendingIcon: String? = null

    override suspend fun isSupported(): Boolean = switcher.isSupported()

    /** The picked icon, or the one the launcher shows when nothing waits. */
    override suspend fun current(): String = currentIcon()

    override suspend fun setIcon(id: String): AppIconError? = when {
        !switcher.isSupported() -> AppIconError.UNSUPPORTED
        !choose(id) -> AppIconError.UNKNOWN_ICON
        else -> null
    }

    fun currentIcon(): String = pendingIcon ?: switcher.current()

    /** Picks [id] for the next [applyPending]; picking the icon shown cancels a waiting pick. False for no icon. */
    fun choose(id: String): Boolean {
        if (!switcher.has(id)) return false
        pendingIcon = if (id == switcher.current()) null else id
        return true
    }

    /** Shows the picked icon on the launcher. */
    fun applyPending() {
        val id = pendingIcon ?: return
        pendingIcon = null
        try {
            switcher.set(id)
        } catch (e: Exception) {
            Log.w(TAG, e) { "couldn't switch the app icon to $id" }
        }
    }

    private companion object {
        const val TAG = "AppIconSelection"
    }
}
