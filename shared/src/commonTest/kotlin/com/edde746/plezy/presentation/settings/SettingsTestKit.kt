package com.edde746.plezy.presentation.settings

import com.edde746.plezy.app.AppGraph
import com.edde746.plezy.cast.CastPeerInfo
import com.edde746.plezy.app.AppPlatform
import com.edde746.plezy.app.DeviceIdentity
import com.edde746.plezy.app.FakeAppPlatform
import com.edde746.plezy.app.testGraph
import com.edde746.plezy.model.FormFactor
import com.edde746.plezy.playback.players.ExternalLaunchStatus
import com.edde746.plezy.playback.players.ExternalPlaybackResult
import com.edde746.plezy.playback.players.ExternalPlayerLaunch
import com.edde746.plezy.playback.players.ExternalPlayerLauncher
import com.edde746.plezy.playback.players.ExternalPlayerPlatform
import com.edde746.plezy.playback.players.FakeProbe
import com.edde746.plezy.playback.players.PlayerInstallProbe
import com.edde746.plezy.profiles.Profile
import com.edde746.plezy.settings.AccountPreferencesController
import com.edde746.plezy.settings.PreferencesAccount
import com.edde746.plezy.updates.AppUpdates
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runCurrent
import app.cash.sqldelight.db.QueryResult
import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.TestClock
import com.edde746.plezy.data.inMemoryDatabase
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlin.coroutines.CoroutineContext

/** A device for the settings pages: [os] as [DeviceIdentity.platform] names it ("Windows", "Android", …). */
internal class SettingsPlatform(
    os: String = "Windows",
    isTv: Boolean = false,
    deviceModel: String = "Model",
    override val formFactor: FormFactor = FormFactor.DESKTOP,
    override val appleTv: Boolean = false,
    override val hasFileDialogs: Boolean = true,
    override val externalPlayers: ExternalPlayerLauncher? = null,
    private val features: DeviceFeatures = DeviceFeatures(hardwareDecoding = true, hdr = false, matchFrameRate = false, audioPassthrough = false),
    private val base: FakeAppPlatform = FakeAppPlatform(),
) : AppPlatform by base {
    override val device = DeviceIdentity(platform = os, platformVersion = "1", deviceModel = deviceModel, deviceName = "box", isTv = isTv)

    /** How many times the settings asked for the device's features. */
    var featureReads = 0
        private set

    override fun deviceFeatures() = features.also { featureReads++ }

    val clipboard: List<String> get() = base.clipboard
}

/** The session's side of the settings pages, set by hand. */
internal class FakeSettingsSession : SettingsSession {
    override val perks = MutableStateFlow(ThemePerks(available = true, unlocked = true))
    override val hasLibraries = MutableStateFlow(false)
    override val hasCatalog = MutableStateFlow(false)
    override val profiles = MutableStateFlow<List<Profile>>(emptyList())
    override val activeProfile = MutableStateFlow<Profile?>(null)
    override val profileBinding = MutableStateFlow(false)
    override val castSenders = MutableStateFlow<List<CastPeerInfo>>(emptyList())

    override suspend fun forgetCastSender(id: String) {
        castSenders.value = castSenders.value.filter { it.id != id }
    }

    var accounts: List<AccountPreferenceAccount> = emptyList()

    /** The account playback answers to: [accountPreferences]' active one. */
    var playbackAccount: PreferencesAccount? = null
    override val accountPreferences = AccountPreferencesController { playbackAccount }
    var reloads = 0
    var locationResets = 0

    /** Runs at each download location reset, before it counts; a throw fails the reset. */
    var onLocationReset: suspend () -> Unit = {}

    /** Holds the account listing until completed, where set. */
    var accountsGate: kotlinx.coroutines.CompletableDeferred<Unit>? = null

    override suspend fun accountPreferenceAccounts(): List<AccountPreferenceAccount> {
        accountsGate?.await()
        return accounts
    }

    override suspend fun reloadLibraries() {
        reloads++
    }

    override suspend fun resetDownloadLocation() {
        onLocationReset()
        locationResets++
    }
}

/** External players on [platform]; detection answers from [probe]; launches succeed. */
internal class FakePlayerApps(
    override val platform: ExternalPlayerPlatform = ExternalPlayerPlatform.LINUX,
    override val probe: PlayerInstallProbe = FakeProbe(everything = true),
) : ExternalPlayerLauncher {
    override suspend fun launch(launch: ExternalPlayerLaunch, ended: (ExternalPlaybackResult) -> Unit) = ExternalLaunchStatus.LAUNCHED
}

/**
 * A dispatcher that runs on [inner] until [held]: then it keeps what is dispatched to it and runs it, in order, once
 * released. The settings' database runs on one, so a test holds a write in flight.
 */
internal class HoldableDispatcher(private val inner: CoroutineDispatcher) : CoroutineDispatcher() {
    private val queued = ArrayDeque<Pair<CoroutineContext, Runnable>>()

    var held = false
        set(value) {
            field = value
            if (!value) {
                while (queued.isNotEmpty()) {
                    val (context, block) = queued.removeFirst()
                    inner.dispatch(context, block)
                }
            }
        }

    override fun dispatch(context: CoroutineContext, block: Runnable) {
        if (held) queued.addLast(context to block) else inner.dispatch(context, block)
    }
}

/**
 * The settings stores of a test: [graph] over an in-memory database whose work runs on [io], [platform], [session]. A
 * store's coroutine that fails is recorded in [failures] (and fails the test at its next [checkFailures]).
 */
internal class SettingsFixture(val scope: TestScope, val platform: SettingsPlatform, val session: FakeSettingsSession, updates: (AppGraph) -> AppUpdates?) {
    val io = HoldableDispatcher(StandardTestDispatcher(scope.testScheduler))
    val graph: AppGraph = scope.testGraph(data = LocalData(inMemoryDatabase(), { TestClock().now }, io))
    val data get() = graph.data
    val failures = mutableListOf<Throwable>()
    private val storesScope = CoroutineScope(graph.scope.coroutineContext + CoroutineExceptionHandler { _, e -> failures += e })
    val stores = SettingsStores(graph, platform, session, storesScope, updates(graph))

    init {
        scope.runCurrent()
    }

    fun checkFailures() {
        failures.firstOrNull()?.let { throw AssertionError("A settings store's coroutine failed", it) }
    }

    /** Every value [flow] sends from now on, as it sends it. */
    fun <T> collect(flow: Flow<T>): List<T> {
        val values = mutableListOf<T>()
        scope.backgroundScope.launch(UnconfinedTestDispatcher(scope.testScheduler)) { flow.toList(values) }
        return values
    }

    /** Makes every write and removal of the device setting [key] fail, until [allowWrites]. */
    fun failWrites(key: String) {
        sql("CREATE TEMP TRIGGER IF NOT EXISTS fail_insert_$key BEFORE INSERT ON device_setting WHEN NEW.setting_key = '$key' BEGIN SELECT RAISE(ABORT, 'write failed'); END")
        sql("CREATE TEMP TRIGGER IF NOT EXISTS fail_delete_$key BEFORE DELETE ON device_setting WHEN OLD.setting_key = '$key' BEGIN SELECT RAISE(ABORT, 'write failed'); END")
    }

    fun allowWrites(key: String) {
        sql("DROP TRIGGER IF EXISTS fail_insert_$key")
        sql("DROP TRIGGER IF EXISTS fail_delete_$key")
    }

    /** Records every value written to the device setting [key] from now on, as stored (JSON), for [writes]. */
    fun recordWrites(key: String) {
        sql("CREATE TEMP TABLE IF NOT EXISTS recorded_writes (setting_key TEXT NOT NULL, value_json TEXT NOT NULL)")
        sql(
            "CREATE TEMP TRIGGER IF NOT EXISTS record_$key AFTER INSERT ON device_setting WHEN NEW.setting_key = '$key' " +
                "BEGIN INSERT INTO recorded_writes VALUES (NEW.setting_key, NEW.value_json); END",
        )
    }

    /** The values written to [key] since [recordWrites], oldest first, as stored (JSON). */
    fun writes(key: String): List<String> = data.driver.executeQuery(
        null,
        "SELECT value_json FROM recorded_writes WHERE setting_key = '$key' ORDER BY rowid",
        { cursor ->
            val values = mutableListOf<String>()
            while (cursor.next().value) values += cursor.getString(0)!!
            QueryResult.Value(values)
        },
        0,
    ).value

    private fun sql(statement: String) {
        data.driver.execute(null, statement, 0)
    }

    /** The row page [id]'s store, with every event it sends in [events]. */
    fun page(id: SettingsPageId, arg: String? = null): Page {
        val store = stores.page(id, arg)
        val page = Page(store)
        scope.backgroundScope.launch(UnconfinedTestDispatcher(scope.testScheduler)) { store.events.toList(page.events) }
        scope.runCurrent()
        return page
    }

    class Page(val store: SettingsPageStore) {
        val events = mutableListOf<SettingsEvent>()
        val state get() = store.state.value
        val ids: List<String> get() = state.groups.flatMap { g -> g.rows.map { it.id } }
        val messages: List<SettingsEvent.Message> get() = events.filterIsInstance<SettingsEvent.Message>()

        fun row(id: String): SettingRow = state.groups.flatMap { it.rows }.firstOrNull { it.id == id } ?: error("No row $id in $ids")

        inline fun <reified R : SettingRow> rowOf(id: String): R = row(id) as R

        fun has(id: String) = id in ids
    }
}

internal fun TestScope.settingsFixture(
    platform: SettingsPlatform = SettingsPlatform(),
    session: FakeSettingsSession = FakeSettingsSession(),
    updates: (AppGraph) -> AppUpdates? = { null },
) = SettingsFixture(this, platform, session, updates)
