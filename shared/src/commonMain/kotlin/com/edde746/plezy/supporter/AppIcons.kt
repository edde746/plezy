package com.edde746.plezy.supporter

import com.edde746.plezy.log.Log
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * One home-screen icon the user can pick: the default or a Supporter alternate. [id] is permanent: the Android
 * launcher alias `.appicon.<id>` and the Apple alternate icon `AppIcon-<id>`; devices keep the chosen icon by it across
 * updates, so an id is never renamed or removed.
 */
data class AppIconOption(val id: String) {
    val isDefault: Boolean get() = id == AppIconCatalog.DEFAULT_ID

    /** The icon's name in the interface language. */
    val label: String get() = AppIconCatalog.label(id)
}

/** Every icon in the picker's order, default first. */
object AppIconCatalog {
    /** What the platforms call the icon the app ships with. */
    const val DEFAULT_ID = "default"

    val options: List<AppIconOption> = listOf(
        DEFAULT_ID, "midnight", "ember", "paper", "oled", "line", "ocean", "ultraviolet", "matcha", "sunset", "gold",
        "titanium", "glass", "crt", "vhs", "synthwave", "pixel", "neon", "sticker", "ticket", "pop", "strata", "facet",
        "tilde",
    ).map(::AppIconOption)

    /** The catalog entry for a platform id; null for an id this build doesn't know. */
    fun byId(id: String): AppIconOption? = options.firstOrNull { it.id == id }

    internal fun label(id: String): String {
        val names = T.appIcon.names
        return when (id) {
            DEFAULT_ID -> T.appIcon.defaultIcon
            "midnight" -> names.midnight
            "ember" -> names.ember
            "paper" -> names.paper
            "oled" -> names.oled
            "line" -> names.line
            "ocean" -> names.ocean
            "ultraviolet" -> names.ultraviolet
            "matcha" -> names.matcha
            "sunset" -> names.sunset
            "gold" -> names.gold
            "titanium" -> names.titanium
            "glass" -> names.glass
            "crt" -> names.crt
            "vhs" -> names.vhs
            "synthwave" -> names.synthwave
            "pixel" -> names.pixel
            "neon" -> names.neon
            "sticker" -> names.sticker
            "ticket" -> names.ticket
            "pop" -> names.pop
            "strata" -> names.strata
            "facet" -> names.facet
            "tilde" -> names.tilde
            else -> id
        }
    }
}

/** Why the platform refused an icon change. */
enum class AppIconError {
    /** This launcher doesn't switch app icons. */
    UNSUPPORTED,

    /** No app icon has that id. */
    UNKNOWN_ICON,
    FAILED,
}

/**
 * The OS side of the home-screen icon, implemented natively: Android's launcher aliases (applied once the user leaves
 * the app), the iPhone's, iPad's and Apple TV's alternate icons. Answers don't throw.
 */
interface AppIconSwitch {
    /** Whether this device's launcher can switch the icon. */
    suspend fun isSupported(): Boolean

    /** The id of the icon the home screen shows (Android: the one picked, if it waits for the user to leave). */
    suspend fun current(): String

    /** Shows [id] on the home screen; null when done, else why not. */
    suspend fun setIcon(id: String): AppIconError?
}

/** Whether the device can switch its icon ([supported]; false until [AppIcons.refresh] answers) and the icon it shows. */
data class AppIconState(val supported: Boolean = false, val currentId: String = AppIconCatalog.DEFAULT_ID)

/**
 * The home-screen icon, which belongs to the device like the Supporter entitlement it follows. The platform keeps the
 * choice; this mirrors it. A confirmed revocation of the entitlement ([Supporter.unlocked] turning false) puts the
 * default icon back, with Settings closed too.
 *
 * @param switch the platform's switcher; null where the build or the platform has no alternate icons (desktops, builds
 *   without the perks), which stay unsupported without asking.
 */
class AppIcons(private val switch: AppIconSwitch?, unlocked: StateFlow<Boolean>, private val scope: CoroutineScope) {
    private val mutableState = MutableStateFlow(AppIconState())
    private var loading: CompletableDeferred<Unit>? = null
    private val revocations: Job

    val state: StateFlow<AppIconState> = mutableState.asStateFlow()

    init {
        var wasUnlocked = unlocked.value
        revocations = scope.launch {
            unlocked.collect { now ->
                val revoked = wasUnlocked && !now
                wasUnlocked = now
                if (revoked) restoreDefaultIcon()
            }
        }
    }

    /** Reads support and the current icon from the platform; concurrent calls share one round trip. */
    suspend fun refresh() {
        loading?.let { return it.await() }
        val done = CompletableDeferred<Unit>()
        loading = done
        try {
            load()
        } finally {
            loading = null
            done.complete(Unit)
        }
    }

    /** Shows [id] on the home screen; null when done, else why not (the current icon unchanged). */
    suspend fun setIcon(id: String): AppIconError? {
        val switch = switch
        if (switch == null || !state.value.supported) return AppIconError.UNSUPPORTED
        switch.setIcon(id)?.let { return it }
        mutableState.value = state.value.copy(currentId = id)
        return null
    }

    fun close() {
        revocations.cancel()
    }

    private suspend fun load() {
        val switch = switch ?: return
        val loaded = try {
            val supported = switch.isSupported()
            AppIconState(supported, if (supported) switch.current() else AppIconCatalog.DEFAULT_ID)
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "the app icon's state is unavailable" }
            AppIconState()
        }
        mutableState.value = loaded
    }

    private suspend fun restoreDefaultIcon() {
        refresh()
        val current = state.value
        if (!current.supported || current.currentId == AppIconCatalog.DEFAULT_ID) return
        setIcon(AppIconCatalog.DEFAULT_ID)?.let { Log.w(TAG) { "couldn't restore the default app icon after a revocation: $it" } }
    }

    private companion object {
        const val TAG = "AppIcons"
    }
}
