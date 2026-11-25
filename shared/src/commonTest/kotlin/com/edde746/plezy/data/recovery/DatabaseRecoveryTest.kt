package com.edde746.plezy.data.recovery

import com.edde746.plezy.data.LocalData
import com.edde746.plezy.data.db.Profiles
import com.edde746.plezy.data.inMemoryDatabase
import com.edde746.plezy.data.testData
import com.edde746.plezy.importer.EMPTY_EARLIER_RELEASE_SNAPSHOT
import com.edde746.plezy.importer.EarlierRelease
import com.edde746.plezy.importer.EarlierReleaseImport
import com.edde746.plezy.importer.EarlierReleaseOutcome
import com.edde746.plezy.importer.EarlierReleaseConnectionRow
import com.edde746.plezy.importer.EarlierReleasePrefValue
import com.edde746.plezy.importer.EarlierReleasePrefs
import com.edde746.plezy.model.ServerId
import com.edde746.plezy.profiles.ProfileIdentity
import com.edde746.plezy.profiles.homeUser
import com.edde746.plezy.profiles.mergeLocalWithPlexHome
import com.edde746.plezy.profiles.plexHomeProfileId
import com.edde746.plezy.profiles.resolveActiveProfile
import com.edde746.plezy.secrets.MemorySecretStore
import com.edde746.plezy.servers.OfflineWatchActionType
import com.edde746.plezy.settings.AppSettings
import com.edde746.plezy.settings.ProfileSettings
import com.edde746.plezy.settings.ServerSettings
import com.edde746.plezy.settings.StartupSection
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DatabaseRecoveryTest {
    private val device = Device()
    private val store get() = device.store
    private var data: LocalData? = null

    @AfterTest
    fun close() {
        data?.close()
    }

    private fun open(ceiling: Int = RECOVERY_BYTE_CEILING, recovery: Boolean = true): LocalData {
        data?.close()
        return device.open(ceiling, recovery).also { data = it }
    }

    private fun closeAndPurge() {
        data?.close()
        data = null
        device.purge()
    }

    private fun manifest(): JsonObject = Json.parseToJsonElement(store.string(RecoveryKeys.MANIFEST)!!).jsonObject

    private fun setManifest(change: (MutableMap<String, JsonElement>) -> Unit) {
        val fields = manifest().toMutableMap()
        change(fields)
        store.values[RecoveryKeys.MANIFEST] = JsonObject(fields).toString()
    }

    /** Loses the database and opens again: the last write's image must bring every critical row back. */
    private suspend fun recoverCriticalRows(): LocalData {
        val expected = data!!.criticalRows()
        closeAndPurge()
        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(expected, restored.criticalRows())
        return restored
    }

    private suspend fun importOutcome(data: LocalData) = EarlierReleaseImport(data, com.edde746.plezy.secrets.MemorySecretStore()).outcome()

    @Test
    fun restoresTheCriticalGroupsExactlyAndNotTheReconstructibleTables() = runTest {
        val first = open()
        assertEquals(DatabaseRecovery.FRESH, first.recovery)
        first.seedCriticalRows()
        first.apiCache.put("server-1", "/library", JsonObject(emptyMap()))
        first.driver.execute(null, "INSERT INTO download_owners(profile_id, global_key, created_at) VALUES ('local-1', 'server-1:1', 0)", 0)
        val expected = first.criticalRows()
        assertEquals(2, expected.first.connections.size)
        assertEquals(2, expected.first.profiles.size)
        assertEquals(3, expected.second.offlineWatchProgress.size)
        closeAndPurge()

        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(expected, restored.criticalRows())
        assertNull(restored.apiCache.get("server-1", "/library"))
        assertEquals(0L, countRows(restored, "download_owners"))
        assertNull(store.values[RecoveryKeys.REQUIRED])
    }

    private fun countRows(data: LocalData, table: String): Long = data.driver.executeQuery(
        null, "SELECT COUNT(*) FROM $table", { cursor -> cursor.next(); app.cash.sqldelight.db.QueryResult.Value(cursor.getLong(0)!!) }, 0,
    ).value

    @Test
    fun anImageKeepsNoSecretAndUsesItsOwnKeys() = runTest {
        open().seedCriticalRows()
        assertEquals(RecoveryKeys.ALL.toSet() - RecoveryKeys.REQUIRED + RecoveryKeys.INSTALL, store.values.keys)
        assertTrue(store.values.keys.none { it.startsWith("tvos_db_recovery_") })
        val identity = store.string(RecoveryKeys.IDENTITY)!!
        assertFalse("userToken" in identity || "accessToken" in identity)
    }

    @Test
    fun theSettingsAndProfileBookkeepingOfAnUpgradedInstallSurviveAPurge() = runTest {
        val first = open()
        val prefs = EarlierReleasePrefs(mapOf("enable_debug_logging" to EarlierReleasePrefValue.BoolValue(true)))
        val account = EarlierReleaseConnectionRow(
            "plex.account", "plex", "Owner",
            """{"accountToken":"owner-token","clientIdentifier":"client-owner","accountLabel":"Owner","activeProfile":null,"servers":[]}""",
            createdAt = 1, lastAuthenticatedAt = null,
        )
        val upgrade = EarlierReleaseImport(first, MemorySecretStore())
        upgrade.importFound(EarlierRelease(prefs, EMPTY_EARLIER_RELEASE_SNAPSHOT.copy(connections = listOf(account)), EarlierReleaseOutcome.IMPORTED))

        val identity = ProfileIdentity(first)
        val owner = homeUser("aaaaaaaaaaaaaaaa", title = "Owner")
        val kid = homeUser("bbbbbbbbbbbbbbbb", title = "Kid")
        val kidProfile = plexHomeProfileId("plex.account", kid.uuid)
        val clientId = identity.getOrCreateClientIdentifier()
        identity.savePlexHomeUsers("plex.account", listOf(owner, kid))
        identity.setActiveProfileId(kidProfile)
        identity.markProfileUsed(kidProfile, 7_000)
        first.deviceSettings.set(AppSettings.startupSection, StartupSection.LIBRARIES)
        first.libraryPrefs.setSelectedLibraryKey("server-1:7")
        first.serverSettings.set("server-1", ServerSettings.watchedThreshold, 75)
        closeAndPurge()

        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        val after = ProfileIdentity(restored)
        assertEquals(clientId, after.getOrCreateClientIdentifier())
        assertEquals(kidProfile, after.activeProfileId())
        assertEquals(7_000L, after.profileLastUsed(kidProfile))
        assertEquals(StartupSection.LIBRARIES, restored.deviceSettings.value(AppSettings.startupSection))
        assertTrue(restored.deviceSettings.value(AppSettings.enableDebugLogging))
        assertEquals("server-1:7", restored.libraryPrefs.selectedLibraryKey())
        assertEquals(75, restored.serverSettings.value("server-1", ServerSettings.watchedThreshold))
        // Offline, the Plex account's Home users are profiles again, the one that was active among them.
        val profiles = mergeLocalWithPlexHome(
            locals = restored.profiles.list(),
            plexHomeByConnectionId = mapOf("plex.account" to after.plexHomeUsers("plex.account").orEmpty()),
            connectionIds = restored.criticalRows().first.connections.map { it.id }.toSet(),
            storedLastUsed = after.profilesLastUsed(listOf(kidProfile)),
        )
        assertEquals(listOf(kidProfile, plexHomeProfileId("plex.account", owner.uuid)), profiles.map { it.id })
        assertEquals(kidProfile, resolveActiveProfile(profiles, after.activeProfileId())?.id)
        // The upgrade ran before the purge: the earlier release's preferences aren't imported over these settings.
        assertEquals(EarlierReleaseOutcome.IMPORTED, importOutcome(restored))
        assertNull(EarlierReleaseImport(restored, MemorySecretStore()).run(locations = null))
    }

    @Test
    fun aRestoreLeavesAnImportThatNeverRanToRun() = runTest {
        open().seedCriticalRows()
        assertNull(importOutcome(data!!))
        val restored = recoverCriticalRows()
        assertNull(importOutcome(restored))
    }

    @Test
    fun anEmptyRestoredImageLetsTheEarlierReleaseImportRunAgain() = runTest {
        open()
        closeAndPurge()
        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertNull(importOutcome(restored))
    }

    // Startup classification.

    @Test
    fun offPurgeableStorageItIsNotApplicableAndKeepsNoImage() = runTest {
        val plain = testData(factory = inMemoryDatabase())
        try {
            assertEquals(DatabaseRecovery.NOT_APPLICABLE, plain.recovery)
            assertNull(plain.recoveryImage)
            plain.addProfile("p1")
        } finally {
            plain.close()
        }
        val unrecovered = open(recovery = false)
        assertEquals(DatabaseRecovery.NOT_APPLICABLE, unrecovered.recovery)
        unrecovered.addProfile("p1")
        assertTrue(store.values.isEmpty())
    }

    @Test
    fun aMissingDatabaseWithoutImageOrEvidenceIsFresh() = runTest {
        assertEquals(DatabaseRecovery.FRESH, open().recovery)
        assertEquals("committed", (manifest()["state"] as JsonPrimitive).content)
        assertNull(importOutcome(data!!))
    }

    @Test
    fun theEarlierReleasesKeysAreNotThisImage() = runTest {
        store.values["tvos_db_recovery_manifest_v1"] = """{"version":1,"state":"committed","identityDigest":"a","pendingDigest":"b"}"""
        store.values["tvos_db_recovery_required_v1"] = true
        assertEquals(DatabaseRecovery.FRESH, open().recovery)
        assertEquals(true, store.values["tvos_db_recovery_required_v1"])
    }

    @Test
    fun aWrongTypedMarkerCountsAsMissingAndGoes() = runTest {
        store.values[RecoveryKeys.REQUIRED] = "yes"
        assertEquals(DatabaseRecovery.FRESH, open().recovery)
        assertFalse(RecoveryKeys.REQUIRED in store.values)
        assertEquals("committed", (manifest()["state"] as JsonPrimitive).content)
    }

    @Test
    fun aMissingDatabaseWithPriorInstallEvidenceRequiresRecovery() = runTest {
        device.priorInstall = true
        val result = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, result.recovery)
        assertTrue(result.criticalRows().isEmpty())
        assertEquals(true, store.values[RecoveryKeys.REQUIRED])
        // What the earlier releases left was dealt with on an earlier start: it isn't imported over the new sign-in.
        assertEquals(EarlierReleaseOutcome.RECOVERY_REQUIRED, importOutcome(result))
    }

    @Test
    fun anInstallThatHeldAProfileRequiresRecoveryOnceDatabaseAndImageAreGone() = runTest {
        open().addProfile("local-only")
        assertEquals(true, store.values[RecoveryKeys.INSTALL])
        closeAndPurge()
        RecoveryKeys.ALL.forEach { store.values.remove(it) }

        val result = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, result.recovery)
        assertTrue(result.criticalRows().isEmpty())
        assertEquals(EarlierReleaseOutcome.RECOVERY_REQUIRED, importOutcome(result))
    }

    @Test
    fun anInstallThatNeverHeldAnAccountOrProfileStaysFresh() = runTest {
        open().apiCache.put("s", "/x", JsonObject(emptyMap()))
        assertNull(store.values[RecoveryKeys.INSTALL])
        closeAndPurge()
        RecoveryKeys.ALL.forEach { store.values.remove(it) }

        assertEquals(DatabaseRecovery.FRESH, open().recovery)
        assertNull(store.values[RecoveryKeys.INSTALL])
    }

    @Test
    fun theRecoveryRequiredMarkerGatesTheDatabaseUntilAcknowledged() = runTest {
        device.priorInstall = true
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, open().recovery)

        val restarted = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, restarted.recovery)
        assertEquals(true, store.values[RecoveryKeys.REQUIRED])
        assertFailsWith<DatabaseDurabilityException> { restarted.addProfile("blocked-after-restart") }
        assertFailsWith<DatabaseDurabilityException> {
            restarted.offlineWatch.insertMark("p", ServerId("s"), null, "1", OfflineWatchActionType.WATCHED)
        }
        assertTrue(restarted.criticalRows().isEmpty())
        // Other tables aren't gated, nor are settings.
        restarted.apiCache.put("s", "/x", JsonObject(emptyMap()))
        restarted.deviceSettings.set(AppSettings.startupSection, StartupSection.LIBRARIES)

        restarted.acknowledgeRecoveryRequired()
        assertNull(store.values[RecoveryKeys.REQUIRED])
        restarted.addProfile("acknowledged")
        closeAndPurge()

        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(setOf("acknowledged"), restored.profileIds())
        assertEquals(StartupSection.LIBRARIES, restored.deviceSettings.value(AppSettings.startupSection))
    }

    @Test
    fun aSuccessfulRestoreClearsTheGateOnADatabaseCreatedMeanwhile() = runTest {
        open().addProfile("restored-after-restart")
        val identity = store.string(RecoveryKeys.IDENTITY)!!
        store.values[RecoveryKeys.IDENTITY] = "$identity-corrupt"
        closeAndPurge()

        val missing = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, missing.recovery)
        assertEquals(emptySet(), missing.profileIds())

        store.values[RecoveryKeys.IDENTITY] = identity
        val restarted = open()
        assertEquals(DatabaseRecovery.RESTORED, restarted.recovery)
        assertNull(store.values[RecoveryKeys.REQUIRED])
        assertEquals(setOf("restored-after-restart"), restarted.profileIds())
    }

    @Test
    fun aFailedMarkerRemovalReplaysTheRestoreOnTheNextStart() = runTest {
        open().seedCriticalRows()
        val expected = data!!.criticalRows()
        val identity = store.string(RecoveryKeys.IDENTITY)!!
        store.values[RecoveryKeys.IDENTITY] = "$identity-corrupt"
        closeAndPurge()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, open().recovery)

        store.values[RecoveryKeys.IDENTITY] = identity
        store.failing = { it == RecoveryKeys.REQUIRED }
        val unmarked = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, unmarked.recovery)
        assertEquals(expected, unmarked.criticalRows())
        assertEquals(true, store.values[RecoveryKeys.REQUIRED])

        store.failing = { false }
        val replayed = open()
        assertEquals(DatabaseRecovery.RESTORED, replayed.recovery)
        assertEquals(expected, replayed.criticalRows())
        assertNull(store.values[RecoveryKeys.REQUIRED])

        val converged = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, converged.recovery)
        assertEquals(expected, converged.criticalRows())
    }

    @Test
    fun anExistingDatabaseIsAdoptedAndRepublished() = runTest {
        open(recovery = false).addProfile("before-recovery")
        val adopted = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, adopted.recovery)
        assertEquals("committed", (manifest()["state"] as JsonPrimitive).content)
        closeAndPurge()
        assertEquals(setOf("before-recovery"), open().profileIds())
    }

    @Test
    fun anExistingDatabaseStaysAuthoritativeWhenTheImageCantBeWritten() = runTest {
        open(recovery = false)
        store.failing = { true }
        val result = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, result.recovery)
        result.addProfile("database-remains-authoritative")
        assertEquals(setOf("database-remains-authoritative"), result.profileIds())
    }

    @Test
    fun anExistingDatabaseStaysAuthoritativeWhenTheImageIsOverItsBudget() = runTest {
        open(recovery = false)
        val result = open(ceiling = 1)
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, result.recovery)
        result.addProfile("database-survives-recovery-budget")
        assertEquals(setOf("database-survives-recovery-budget"), result.profileIds())
    }

    @Test
    fun aStartWhoseInvalidationFailsRefusesWritesUntilARetrySucceeds() = runTest {
        open().addProfile("stale-image")
        val staleManifest = store.string(RecoveryKeys.MANIFEST)
        var failManifest = true
        store.failing = { failManifest && it == RecoveryKeys.MANIFEST }

        val existing = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, existing.recovery)
        assertEquals(staleManifest, store.string(RecoveryKeys.MANIFEST))
        assertFailsWith<DatabaseDurabilityException> { existing.addProfile("blocked-by-stale-image") }
        assertEquals(setOf("stale-image"), existing.profileIds())
        assertEquals(staleManifest, store.string(RecoveryKeys.MANIFEST))

        // The image left still restores exactly what the database held.
        val probe = Device(MemoryRecoveryStore(store.values)).open()
        try {
            assertEquals(DatabaseRecovery.RESTORED, probe.recovery)
            assertEquals(setOf("stale-image"), probe.profileIds())
        } finally {
            probe.close()
        }

        failManifest = false
        val retried = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, retried.recovery)
        retried.addProfile("committed-after-retry")
        assertNotEquals(staleManifest, store.string(RecoveryKeys.MANIFEST))
        closeAndPurge()

        val recovered = open()
        assertEquals(DatabaseRecovery.RESTORED, recovered.recovery)
        assertEquals(setOf("stale-image", "committed-after-retry"), recovered.profileIds())
    }

    @Test
    fun anExistingDatabaseRepairsAnInterruptedManifest() = runTest {
        open().addProfile("authoritative")
        setManifest { it["state"] = JsonPrimitive("invalidated") }
        val repaired = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, repaired.recovery)
        assertEquals("committed", (manifest()["state"] as JsonPrimitive).content)
        closeAndPurge()
        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(setOf("authoritative"), restored.profileIds())
    }

    // Invalid images: none restores anything, and recovery is required.

    private suspend fun expectRejected(corrupt: () -> Unit) {
        open().addProfile("must-not-partially-restore")
        corrupt()
        closeAndPurge()
        val result = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, result.recovery)
        assertTrue(result.criticalRows().isEmpty())
    }

    @Test
    fun anAbsentPayloadIsRejected() = runTest { expectRejected { store.values.remove(RecoveryKeys.IDENTITY) } }

    @Test
    fun aCorruptManifestIsRejected() = runTest { expectRejected { store.values[RecoveryKeys.MANIFEST] = "{" } }

    @Test
    fun anInvalidatedManifestIsRejected() = runTest { expectRejected { setManifest { it["state"] = JsonPrimitive("invalidated") } } }

    @Test
    fun anUnsupportedVersionIsRejected() = runTest { expectRejected { setManifest { it["version"] = JsonPrimitive(99) } } }

    @Test
    fun aDigestMismatchIsRejected() = runTest {
        expectRejected { store.values[RecoveryKeys.IDENTITY] = store.string(RecoveryKeys.IDENTITY) + " " }
    }

    @Test
    fun aStructurallyInvalidPayloadWithAMatchingDigestIsRejected() = runTest {
        expectRejected {
            val payload = Json.parseToJsonElement(store.string(RecoveryKeys.IDENTITY)!!).jsonObject
            val rows = payload.getValue("rows").jsonObject - "profiles"
            val encoded = JsonObject(payload + ("rows" to JsonObject(rows))).toString()
            store.values[RecoveryKeys.IDENTITY] = encoded
            setManifest { it["identityDigest"] = JsonPrimitive(digest(encoded)) }
        }
    }

    @Test
    fun aPayloadWithUnknownFieldsIsRejected() = runTest {
        expectRejected {
            val payload = Json.parseToJsonElement(store.string(RecoveryKeys.IDENTITY)!!).jsonObject
            val encoded = JsonObject(payload + ("generation" to JsonPrimitive(7))).toString()
            store.values[RecoveryKeys.IDENTITY] = encoded
            setManifest { it["identityDigest"] = JsonPrimitive(digest(encoded)) }
        }
    }

    @Test
    fun anImageOverTheCeilingIsRejected() = runTest {
        open().addProfile("over-budget")
        closeAndPurge()
        val result = open(ceiling = 1)
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, result.recovery)
        assertTrue(result.criticalRows().isEmpty())
    }

    @Test
    fun unrelatedKeysDontCountAgainstTheCeiling() = runTest {
        open().addProfile("survives-large-settings")
        store.values["unrelated_large_setting"] = "x".repeat(500_000)
        closeAndPurge()
        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(setOf("survives-large-settings"), restored.profileIds())
    }

    @Test
    fun acknowledgingASignInReplacesInvalidEvidenceBeforeNewWrites() = runTest {
        open()
        store.values[RecoveryKeys.IDENTITY] = store.string(RecoveryKeys.IDENTITY) + "-digest-mismatch"
        closeAndPurge()

        var result = open()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, result.recovery)
        assertFailsWith<DatabaseDurabilityException> { result.addConnection("blocked-before-acknowledgement") }
        assertTrue(result.criticalRows().isEmpty())

        result.acknowledgeRecoveryRequired()
        result.addConnection("new-sign-in")
        val expected = result.criticalRows()
        closeAndPurge()

        result = open()
        assertEquals(DatabaseRecovery.RESTORED, result.recovery)
        assertEquals(expected, result.criticalRows())
    }

    // The two-phase protocol: the process stopping anywhere converges from the database, and never restores stale rows.

    @Test
    fun eachCrashPointConvergesFromTheAuthoritativeDatabase() = runTest {
        for (point in RecoveryCrashPoint.entries) {
            closeAndPurge()
            store.values.clear()
            var armed = false
            val first = open()
            device.crashAt(first, point) { armed }
            armed = true
            assertFailsWith<SimulatedCrash> { first.addProfile("crash-row") }
            armed = false
            val expected = first.criticalRows()
            assertEquals(point != RecoveryCrashPoint.AFTER_INVALIDATION, "crash-row" in first.profileIds(), "$point")

            val repaired = open()
            assertEquals(DatabaseRecovery.ADOPTED_EXISTING, repaired.recovery, "$point")
            assertEquals(expected, repaired.criticalRows(), "$point")
            closeAndPurge()

            val restored = open()
            assertEquals(DatabaseRecovery.RESTORED, restored.recovery, "$point")
            assertEquals(expected, restored.criticalRows(), "$point")
        }
    }

    @Test
    fun aCrashBeforeTheFinalManifestNeverRestoresStaleRows() = runTest {
        val points = listOf(RecoveryCrashPoint.AFTER_INVALIDATION, RecoveryCrashPoint.AFTER_DATABASE_MUTATION, RecoveryCrashPoint.AFTER_PAYLOAD_WRITE)
        for (point in points) {
            closeAndPurge()
            store.values.clear()
            var armed = false
            val first = open()
            first.addProfile("committed-before")
            device.crashAt(first, point) { armed }
            armed = true
            assertFailsWith<SimulatedCrash> { first.addProfile("uncommitted") }
            closeAndPurge()

            val missing = open()
            assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, missing.recovery, "$point")
            assertTrue(missing.criticalRows().isEmpty(), "$point")
        }
    }

    @Test
    fun aStoreFailureAfterTheCommitKeepsTheWriteAndConvergesNextStart() = runTest {
        val first = open()
        store.failing = { it == RecoveryKeys.IDENTITY }
        first.addConnection("write-failure")
        assertEquals("invalidated", (manifest()["state"] as JsonPrimitive).content)
        // Recovery is off for the process: later writes run against the authoritative database.
        first.addProfile("after-failure")
        assertEquals(1, first.criticalRows().first.connections.size)
        store.failing = { false }

        val repaired = open()
        assertEquals(DatabaseRecovery.ADOPTED_EXISTING, repaired.recovery)
        closeAndPurge()
        val restored = open()
        assertEquals(DatabaseRecovery.RESTORED, restored.recovery)
        assertEquals(listOf("write-failure"), restored.criticalRows().first.connections.map { it.id })
        assertEquals(setOf("after-failure"), restored.profileIds())
    }

    @Test
    fun aFailedWriteDoesntStopLaterOnes() = runTest {
        val first = open()
        assertFailsWith<IllegalStateException> {
            first.db.write {
                q.profileQueries.insertRow(com.edde746.plezy.data.db.Profiles("rolled-back", "local", "x", null, "{}", 0, 1, null))
                error("injected mutation failure")
            }
        }
        assertEquals("committed", (manifest()["state"] as JsonPrimitive).content)
        first.addProfile("after-failure")
        assertEquals(setOf("after-failure"), recoverCriticalRows().profileIds())
    }

    @Test
    fun writesOfOtherTablesLeaveTheImageAlone() = runTest {
        val first = open()
        val writes = store.writes
        first.apiCache.put("s", "/x", JsonObject(emptyMap()))
        assertEquals(writes, store.writes)
        first.addProfile("p1")
        assertTrue(store.writes > writes)
    }

    // Budgets.

    @Test
    fun anOversizedIdentityTurnsRecoveryOffWithoutRefusingWrites() = runTest {
        val first = open(ceiling = 1_200)
        first.addConnection("huge", """{"serverName":"${"PROTECTED-SIZE-CANARY".repeat(3_000)}"}""")
        first.addProfile("after-degradation")
        assertEquals(1, first.criticalRows().first.connections.size)
        assertEquals(setOf("after-degradation"), first.profileIds())
        assertFalse(store.values.values.any { "PROTECTED-SIZE-CANARY" in it.toString() })
        closeAndPurge()

        val missing = open(ceiling = 1_200)
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, missing.recovery)
        assertTrue(missing.criticalRows().isEmpty())
    }

    @Test
    fun overTheBudgetPendingActionsGoFirstThenTheSettingsButNeverTheProfileBookkeeping() = runTest {
        val ceiling = 20_000
        val first = open(ceiling)
        first.addConnection("retained")
        val identity = ProfileIdentity(first)
        identity.setActiveProfileId("local-kept")
        identity.savePlexHomeUsers("plex.account", listOf(homeUser("aaaaaaaaaaaaaaaa")))
        first.deviceSettings.set(AppSettings.startupSection, StartupSection.LIBRARIES)
        repeat(20) { index ->
            first.offlineWatch.insertMark("profile", ServerId("server"), null, "$index-${"pending".repeat(500)}", OfflineWatchActionType.WATCHED)
        }
        assertEquals(20, first.criticalRows().second.offlineWatchProgress.size)
        closeAndPurge()

        val withoutPending = open(ceiling)
        assertEquals(DatabaseRecovery.RESTORED, withoutPending.recovery)
        assertEquals(listOf("retained"), withoutPending.criticalRows().first.connections.map { it.id })
        assertTrue(withoutPending.criticalRows().second.offlineWatchProgress.isEmpty())
        assertEquals(StartupSection.LIBRARIES, withoutPending.deviceSettings.value(AppSettings.startupSection))

        withoutPending.profileSettings.set("local-kept", ProfileSettings.metadataRecentTags, JsonObject(mapOf("tags" to JsonPrimitive("t".repeat(30_000)))))
        closeAndPurge()

        val withoutSettings = open(ceiling)
        assertEquals(DatabaseRecovery.RESTORED, withoutSettings.recovery)
        assertEquals(listOf("retained"), withoutSettings.criticalRows().first.connections.map { it.id })
        assertNull(withoutSettings.profileSettings.value("local-kept", ProfileSettings.metadataRecentTags))
        assertEquals(StartupSection.DISCOVER, withoutSettings.deviceSettings.value(AppSettings.startupSection))
        val kept = ProfileIdentity(withoutSettings)
        assertEquals("local-kept", kept.activeProfileId())
        assertEquals(listOf(homeUser("aaaaaaaaaaaaaaaa")), kept.plexHomeUsers("plex.account"))
    }

    // Every write path is covered, whoever issues it.

    @Test
    fun everyPendingWriteCommitsItsImage() = runTest {
        open()
        data!!.offlineWatch.upsertProgress("p1", ServerId("s1"), null, "a", 10, 100, false)
        recoverCriticalRows()
        data!!.offlineWatch.insertMark(null, ServerId("s1"), null, "legacy", OfflineWatchActionType.WATCHED)
        data!!.offlineWatch.insertMark("p1", ServerId("s1"), null, "b", OfflineWatchActionType.WATCHED)
        data!!.offlineWatch.insertMark("p2", ServerId("s1"), null, "c", OfflineWatchActionType.UNWATCHED)
        recoverCriticalRows()
        data!!.offlineWatch.adoptLegacyActions("p1")
        assertEquals(3, data!!.offlineWatch.pendingActions("p1").size)
        recoverCriticalRows()
        val action = data!!.offlineWatch.pendingActions("p1").first()
        assertTrue(data!!.offlineWatch.recordFailedAttemptIfUnchanged(action.rowId, action.updatedAt, "retry"))
        recoverCriticalRows()
        val other = data!!.offlineWatch.pendingActions("p2").first()
        assertTrue(data!!.offlineWatch.deleteIfUnchanged(other.rowId, other.updatedAt))
        recoverCriticalRows()
        data!!.offlineWatch.deleteForProfile("p1")
        recoverCriticalRows()
        data!!.offlineWatch.clearAll()
        assertTrue(recoverCriticalRows().criticalRows().second.offlineWatchProgress.isEmpty())
    }

    @Test
    fun everyIdentityWriteCommitsItsImageCascadesIncluded() = runTest {
        open().seedCriticalRows()
        recoverCriticalRows()
        data!!.profiles.markUsed("local-1", 9_100)
        recoverCriticalRows()
        data!!.db.write { q.profileQueries.deleteProfile("plex-home-1") }
        recoverCriticalRows()
        // The trigger deletes the connection's bindings with it.
        data!!.db.write { q.connectionQueries.deleteById("server-1") }
        assertEquals(listOf("plex.account"), data!!.criticalRows().first.profileConnections.map { it.connectionId })
        recoverCriticalRows()
        data!!.profiles.remove("local-1")
        recoverCriticalRows()
        data!!.db.write { q.profileQueries.deleteAllBindings() }
        recoverCriticalRows()
        data!!.db.write { q.connectionQueries.deleteAll() }
        val (identity, pending) = recoverCriticalRows().criticalRows()
        assertEquals(IdentityRows(emptyList(), emptyList(), emptyList()), identity)
        assertEquals(3, pending.offlineWatchProgress.size)
    }

    @Test
    fun aStatementCountsForTheGroupsOfTheTablesItNames() = runTest {
        val tables = CriticalTables.of(open().driver)
        assertEquals(setOf(RecoveryGroup.IDENTITY), tables.groupsOf("UPDATE profile_connections SET is_default = 0 WHERE profile_id = ?"))
        assertEquals(setOf(RecoveryGroup.IDENTITY), tables.groupsOf("DELETE FROM connections WHERE id = ?"))
        assertEquals(setOf(RecoveryGroup.PENDING), tables.groupsOf("DELETE FROM offline_watch_progress WHERE id IN (?)"))
        assertEquals(setOf(RecoveryGroup.SETTINGS), tables.groupsOf("INSERT OR REPLACE INTO device_setting VALUES (?, ?)"))
        assertEquals(setOf(RecoveryGroup.SETTINGS), tables.groupsOf("DELETE FROM profile_setting WHERE profile_scope = ?"))
        assertEquals(emptySet(), tables.groupsOf("DELETE FROM live_tv_favorite WHERE connection_id = ?"))
        assertEquals(emptySet(), tables.groupsOf("DELETE FROM api_cache"))
    }

    @Test
    fun aDirectStatementOnACriticalTableOutsideAWriteTurnsRecoveryOff() = runTest {
        val first = open()
        first.driver.execute(null, "INSERT INTO connections VALUES ('raw', 'plex', '{}', 1, NULL, NULL)", 0)
        assertEquals("invalidated", (manifest()["state"] as JsonPrimitive).content)
        closeAndPurge()
        assertEquals(DatabaseRecovery.RECOVERY_REQUIRED, open().recovery)
    }
}
