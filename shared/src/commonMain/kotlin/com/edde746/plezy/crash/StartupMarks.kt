package com.edde746.plezy.crash

import com.edde746.plezy.log.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.updateAndGet
import kotlin.concurrent.Volatile
import kotlin.time.TimeSource

/**
 * The fixed marks of the process's start, in the order they come; their ids are stable: the next start's report of how
 * this process ended names the last one reached. [NATIVE_ON_CREATE] is the process's start (Android's application
 * `onCreate`), [APP_START] the product's start, [CREDENTIALS_LOADED] the saved server connections read,
 * [BINDING_STARTED] the active profile's servers starting to connect (the main screen doesn't wait for them to settle),
 * [MAIN_SCREEN] the first screen after the splash.
 */
enum class StartupMark(val id: String) {
    NATIVE_ON_CREATE("native_on_create"),
    APP_START("app_start"),
    FIRST_FRAME("first_frame"),
    DATABASE_OPEN_STARTED("database_open_started"),
    DATABASE_READY("database_ready"),
    CREDENTIALS_LOADED("credentials_loaded"),
    BINDING_STARTED("binding_started"),
    MAIN_SCREEN("main_screen"),
    ;

    /** The UI state a process on this mark is in. */
    val uiState: RuntimeUiState get() = when (this) {
        CREDENTIALS_LOADED, BINDING_STARTED -> RuntimeUiState.AUTHENTICATION
        MAIN_SCREEN -> RuntimeUiState.MAIN_SCREEN
        else -> RuntimeUiState.STARTUP
    }

    companion object {
        fun fromId(id: String?): StartupMark? = entries.firstOrNull { it.id == id }
    }
}

/** What the app shows, as the next start's report of how this process ended names it. Ids are stable. */
enum class RuntimeUiState(val id: String) {
    STARTUP("startup"),
    AUTHENTICATION("authentication"),
    MAIN_SCREEN("main_screen"),
    PLAYER("player"),
    ;

    companion object {
        fun fromId(id: String?): RuntimeUiState? = entries.firstOrNull { it.id == id }
    }
}

/**
 * Records the process's [StartupMark]s and its [RuntimeUiState]: each mark is logged (`Startup phase: phase=…
 * elapsedMs=…`, milliseconds since the first mark, never decreasing) and becomes a `startup.phase` breadcrumb, held
 * until the crash reporter runs ([CrashCapture.breadcrumb]). The platform that reports how the previous process ended
 * (Android) installs [persist] and keeps the last mark and UI state for the next start. Any thread.
 */
object StartupMarks {
    /** Keeps the mark and the UI state for the next start; null where nothing keeps them. */
    interface Persist {
        fun mark(mark: StartupMark)
        fun uiState(state: RuntimeUiState)
    }

    @Volatile
    var persist: Persist? = null

    // The object starts with the process's first mark.
    private val started = TimeSource.Monotonic.markNow()
    private val lastElapsedMs = MutableStateFlow(0L)

    fun mark(mark: StartupMark) {
        val elapsedMs = elapsedMs()
        Log.i(TAG) { "Startup phase: phase=${mark.id} elapsedMs=$elapsedMs" }
        CrashCapture.breadcrumb(Breadcrumb(CATEGORY, "Startup phase ${mark.id}", mapOf("phase" to mark.id, "elapsedMs" to elapsedMs)))
        persist?.let {
            it.mark(mark)
            it.uiState(mark.uiState)
        }
    }

    /** The app now shows [state]. */
    fun uiState(state: RuntimeUiState) {
        persist?.uiState(state)
    }

    private fun elapsedMs(): Long = lastElapsedMs.updateAndGet { maxOf(it, started.elapsedNow().inWholeMilliseconds) }

    const val CATEGORY = "startup.phase"
    private const val TAG = "startup"
}
