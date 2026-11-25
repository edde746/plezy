package com.edde746.plezy.presentation.settings

import com.edde746.plezy.model.AccountPreferenceKey
import com.edde746.plezy.model.AccountPreferenceTarget
import com.edde746.plezy.model.AccountPreferences
import com.edde746.plezy.model.AccountPreferencesCapabilities
import com.edde746.plezy.model.AccountPreferencesPatch
import com.edde746.plezy.model.AccountPreferencesSource
import com.edde746.plezy.model.AccountRef
import com.edde746.plezy.model.BackendKind
import com.edde746.plezy.plex.PlexHomeUser
import com.edde746.plezy.plex.tv.PlexAccountConnection
import com.edde746.plezy.profiles.LocalProfile
import com.edde746.plezy.profiles.PlexHomeProfile
import com.edde746.plezy.profiles.ProfileConnection
import com.edde746.plezy.profiles.jellyfin
import com.edde746.plezy.settings.PreferencesAccount
import com.edde746.plezy.strings.T
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Account preferences: which accounts the active profile edits and through which token, the
 * one playback answers to, and the page: the picker in order, one account inline, none, unreachable, and writes shown
 * at once and reverted when the server refuses them.
 */
class AccountPreferencesPageTest {
    private val home = PlexHomeProfile(id = "home", displayName = "Home user", parentConnectionId = "parent", plexHomeUserUuid = "home-user", createdAt = 1)
    private val parent = PlexAccountConnection(id = "parent", accountToken = "owner-token", clientIdentifier = "client", accountLabel = "Plex parent", createdAt = 1)
    private val borrowed = jellyfin()
    private val borrowedRow = ProfileConnection(profileId = home.id, connectionId = borrowed.id, userIdentifier = borrowed.userId, isDefault = true)
    private val parentRow = ProfileConnection(profileId = home.id, connectionId = parent.id, userIdentifier = "home-user", userToken = "switched-token")
    private val local = LocalProfile("local", "Local", createdAt = 1)

    // ---- Which accounts ----

    @Test
    fun aBorrowedDefaultStaysEditableButAHomeProfileAnswersToItsParent() {
        val resolution = resolveAccountPreferenceAccounts(home, listOf(borrowedRow, parentRow), listOf(borrowed, parent))
        assertEquals(borrowed.id, resolution.accounts.first().target.ref.connectionId)
        assertEquals(AccountRef.plex("parent", "home-user"), resolution.playbackRef)
        assertEquals("switched-token", resolution.accounts.last().plexToken)
        assertEquals("Home user", resolution.accounts.last().target.subtitle)
    }

    @Test
    fun aHomeProfileWithoutItsParentRowPrincipalOrTokenGetsNeitherTheBorrowedDefaultNorTheOwner() {
        for ((profile, rows, connections) in listOf(
            Triple(home, listOf(borrowedRow, parentRow), listOf(borrowed)),
            Triple(home, listOf(borrowedRow), listOf(borrowed, parent)),
            Triple(home, listOf(borrowedRow, parentRow.copy(userToken = null)), listOf(borrowed, parent)),
            Triple(home, listOf(borrowedRow, parentRow.copy(userToken = "")), listOf(borrowed, parent)),
            Triple(home, listOf(borrowedRow, parentRow.copy(userIdentifier = "someone-else")), listOf(borrowed, parent)),
            Triple(home.copy(plexHomeUserUuid = null), listOf(borrowedRow, parentRow), listOf(borrowed, parent)),
            Triple(home.copy(parentConnectionId = null), listOf(borrowedRow, parentRow), listOf(borrowed, parent)),
        )) {
            val resolution = resolveAccountPreferenceAccounts(profile, rows, connections)
            assertNull(resolution.playbackRef)
            assertEquals(listOf(borrowed.id), resolution.accounts.map { it.target.ref.connectionId })
        }
    }

    @Test
    fun aLocalProfileSignsInAsItsRowsHomeUserNotTheAccountsActiveOne() {
        val account = parent.copy(activeProfile = PlexHomeUser(id = 2, uuid = "account-wide-user", title = "Other user"))
        val resolution = resolveAccountPreferenceAccounts(local, listOf(parentRow.copy(profileId = local.id, isDefault = true)), listOf(account))
        assertEquals(AccountRef.plex("parent", "home-user"), resolution.playbackRef)
        assertEquals("switched-token", resolution.accounts.single().plexToken)
    }

    @Test
    fun aLocalProfilesRowWithoutATokenUsesTheOwnersAndTheAccountsActiveUser() {
        val account = parent.copy(activeProfile = PlexHomeUser(id = 1, uuid = "owner-user", title = "Owner"))
        val row = ProfileConnection(profileId = local.id, connectionId = parent.id, userIdentifier = "owner-user")
        val resolved = resolveAccountPreferenceAccounts(local, listOf(row), listOf(account)).accounts.single()
        assertEquals("owner-token", resolved.plexToken)
        assertEquals(AccountRef.plex("parent", "owner-user"), resolved.target.ref)
    }

    @Test
    fun aMissingDesignatedAccountPromotesNoOther() {
        val resolution = resolveAccountPreferenceAccounts(
            local,
            listOf(parentRow.copy(profileId = local.id, isDefault = true), borrowedRow.copy(profileId = local.id, isDefault = false)),
            listOf(borrowed),
        )
        assertNull(resolution.playbackRef)
        assertEquals(borrowed.id, resolution.accounts.single().target.ref.connectionId)
    }

    @Test
    fun twoUsersOfOneServerStaySeparateAccounts() {
        val other = jellyfin(userId = "other-user")
        val resolution = resolveAccountPreferenceAccounts(
            local,
            listOf(
                borrowedRow.copy(profileId = local.id, isDefault = false),
                ProfileConnection(profileId = local.id, connectionId = other.id, userIdentifier = other.userId, isDefault = true),
            ),
            listOf(borrowed, other),
        )
        assertEquals(other.id, resolution.playbackRef?.connectionId)
        assertEquals(listOf(other.id, borrowed.id), resolution.accounts.map { it.target.ref.connectionId }, "the default first")
    }

    @Test
    fun theDefaultAccountComesFirstAndTheRestByLabelIgnoringCase() {
        val servers = listOf("zed" to true, "beta" to false, "Alpha" to false, "gamma" to false)
            .map { (name, isDefault) -> jellyfin(userId = name).copy(serverName = name) to isDefault }
        val rows = servers.map { (connection, isDefault) ->
            ProfileConnection(profileId = local.id, connectionId = connection.id, userIdentifier = connection.userId, isDefault = isDefault)
        }

        val accounts = resolveAccountPreferenceAccounts(local, rows, servers.map { it.first }).accounts

        assertEquals(listOf("zed", "Alpha", "beta", "gamma"), accounts.map { it.target.label })
    }

    @Test
    fun anotherProfilesRowsAndNoProfileGiveNothing() {
        assertEquals(emptyList(), resolveAccountPreferenceAccounts(local, listOf(borrowedRow), listOf(borrowed)).accounts)
        assertEquals(emptyList(), resolveAccountPreferenceAccounts(null, listOf(borrowedRow), listOf(borrowed)).accounts)
    }

    // ---- The page ----

    private class FakeSource(
        override val capabilities: AccountPreferencesCapabilities = AccountPreferencesCapabilities.JELLYFIN,
        var values: AccountPreferences = AccountPreferences(),
    ) : AccountPreferencesSource {
        var gate: CompletableDeferred<Unit>? = null
        var refuse = false
        val writes = mutableListOf<AccountPreferencesPatch>()

        override suspend fun read() = values

        override suspend fun write(patch: AccountPreferencesPatch, checkCurrent: (() -> Unit)?): AccountPreferences {
            writes += patch
            gate?.await()
            checkCurrent?.invoke()
            if (refuse) error("refused")
            values = values.copy(hidePlayedInLatest = patch.boolAt(AccountPreferenceKey.HIDE_PLAYED_IN_LATEST) ?: values.hidePlayedInLatest)
            return values
        }
    }

    private fun account(id: String, label: String, source: AccountPreferencesSource?, backend: BackendKind = BackendKind.JELLYFIN) = AccountPreferenceAccount(
        AccountPreferenceTarget(if (backend == BackendKind.PLEX) AccountRef.plex(id) else AccountRef.mediaBrowser(backend, id), label),
        source,
    )

    private fun TestScope.page(
        vararg accounts: AccountPreferenceAccount,
        arg: String? = null,
        session: FakeSettingsSession = FakeSettingsSession(),
    ): SettingsFixture.Page {
        session.accounts = accounts.toList()
        val page = settingsFixture(session = session).page(SettingsPageId.ACCOUNT_PREFERENCES, arg)
        runCurrent()
        return page
    }

    private val hidePlayed = AccountPreferenceKey.HIDE_PLAYED_IN_LATEST.name

    @Test
    fun severalAccountsAreListedInTheirOrderEachOpeningItsOwnPage() = runTest {
        val page = page(account("jf/u", "Jellyfin", FakeSource()), account("plex", "Plex", FakeSource(AccountPreferencesCapabilities.PLEX), BackendKind.PLEX))
        assertEquals(T.accountPreferences.pickAccount, page.state.header)
        assertEquals(listOf("jf/u", "plex"), page.ids)

        page.store.activate("plex")
        assertEquals(listOf<SettingsEvent>(SettingsEvent.Open(SettingsPageId.ACCOUNT_PREFERENCES, "plex")), page.events.toList())
    }

    @Test
    fun anAccountsOwnPageShowsItsValuesUnderItsName() = runTest {
        val source = FakeSource(values = AccountPreferences(hidePlayedInLatest = true))
        val page = page(account("jf/u", "Jellyfin", source), account("plex", "Plex", FakeSource(AccountPreferencesCapabilities.PLEX), BackendKind.PLEX), arg = "jf/u")
        assertEquals("Jellyfin", page.state.title)
        assertEquals(T.accountPreferences.storedOnAccount, page.state.header)
        assertTrue(page.rowOf<SettingToggleRow>(hidePlayed).checked)
    }

    @Test
    fun oneAccountIsEditedInPlace() = runTest {
        val page = page(account("jf/u", "Jellyfin", FakeSource()))
        assertEquals(T.accountPreferences.sectionTitle, page.state.title)
        assertTrue(page.has(hidePlayed))
        // A Jellyfin account has the library rows and none of Plex's.
        assertTrue(page.has(AccountPreferenceKey.DISPLAY_MISSING_EPISODES.name))
        assertFalse(page.has(AccountPreferenceKey.WATCHED_INDICATOR.name))
    }

    @Test
    fun aPlexAccountHasThePlexRowsAndNoLibraryOnes() = runTest {
        val page = page(account("plex", "Plex", FakeSource(AccountPreferencesCapabilities.PLEX), BackendKind.PLEX))
        assertTrue(page.has(AccountPreferenceKey.WATCHED_INDICATOR.name))
        assertFalse(page.has(AccountPreferenceKey.DISPLAY_MISSING_EPISODES.name))
    }

    @Test
    fun noAccountsShowAnEmptyState() = runTest {
        val page = page()
        assertEquals(T.accountPreferences.noAccounts, page.state.empty?.title)
        assertTrue(page.state.groups.isEmpty())
    }

    @Test
    fun anUnreachableAccountOffersARetry() = runTest {
        val page = page(account("jf/u", "Jellyfin", null))
        assertEquals(T.accountPreferences.unavailable, page.state.empty?.title)
        assertEquals(T.common.retry, page.state.empty?.retryLabel)
    }

    @Test
    fun aRefusedWriteShowsTheNewValueThenRevertsAndSaysSo() = runTest {
        val source = FakeSource(values = AccountPreferences(hidePlayedInLatest = false)).apply {
            gate = CompletableDeferred()
            refuse = true
        }
        val page = page(account("jf/u", "Jellyfin", source))
        page.store.toggle(hidePlayed, true)
        runCurrent()
        assertTrue(page.rowOf<SettingToggleRow>(hidePlayed).checked, "shown at once")

        // A second change while the first is written is ignored.
        page.store.toggle(hidePlayed, false)
        runCurrent()
        assertEquals(1, source.writes.size)

        source.gate!!.complete(Unit)
        runCurrent()
        assertFalse(page.rowOf<SettingToggleRow>(hidePlayed).checked)
        assertEquals(listOf(SettingsEvent.Message(T.settings.saveFailed, error = true)), page.messages)
    }

    @Test
    fun anAcceptedWriteKeepsTheNewValue() = runTest {
        val source = FakeSource(values = AccountPreferences(hidePlayedInLatest = true))
        val page = page(account("jf/u", "Jellyfin", source))
        page.store.toggle(hidePlayed, false)
        runCurrent()
        assertFalse(page.rowOf<SettingToggleRow>(hidePlayed).checked)
        assertEquals(false, source.values.hidePlayedInLatest)
        assertEquals(emptyList(), page.messages)
    }

    @Test
    fun aWriteToThePlaybackAccountReachesPlaybackAtOnce() = runTest {
        val source = FakeSource(values = AccountPreferences(hidePlayedInLatest = true))
        val shown = account("jf/u", "Jellyfin", source)
        val session = FakeSettingsSession().apply { playbackAccount = PreferencesAccount(shown.target.ref, source) }
        session.accountPreferences.bind()
        val page = page(shown, session = session)
        assertEquals(true, session.accountPreferences.activePreferences.value?.hidePlayedInLatest)

        page.store.toggle(hidePlayed, false)
        runCurrent()
        assertEquals(false, session.accountPreferences.activePreferences.value?.hidePlayedInLatest)
    }
}
