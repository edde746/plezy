package com.edde746.plezy.importer

import com.edde746.plezy.crypto.cryptoProvider
import com.edde746.plezy.importer.EarlierReleasePrefValue.BoolValue
import com.edde746.plezy.importer.EarlierReleasePrefValue.StringValue
import dev.whyoleg.cryptography.algorithms.SHA256
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals

class TvosRecoveryImageTest {
    private val connection =
        """{"id":"server-1","kind":"jellyfin","displayName":"Server server-1","configJson":"{\"accessToken\":\"enc:v1:{}\"}","createdAt":1000,"lastAuthenticatedAt":null}"""
    private val profile =
        """{"id":"local-1","kind":"local","displayName":"Profile local-1","avatarThumbUrl":null,"configJson":"{\"pinHash\":\"abc\"}","sortOrder":0,"createdAt":2000,"lastUsedAt":null}"""
    private val binding =
        """{"profileId":"local-1","connectionId":"server-1","userToken":"legacy-plaintext-profile-token","userIdentifier":"user-1","isDefault":true,"tokenAcquiredAt":null,"lastUsedAt":7}"""
    private val watchAction =
        """{"id":3,"profileId":"local-1","serverId":"server-1","clientScopeId":"server-1/user-1","ratingKey":"progress","globalKey":"server-1:progress","actionType":"progress","viewOffset":1234,"duration":9999,"shouldMarkWatched":false,"createdAt":3000,"updatedAt":4000,"syncAttempts":2,"lastError":"retry"}"""

    private fun identity(connections: String = connection, profiles: String = profile) =
        """{"version":1,"rows":{"connections":[$connections],"profiles":[$profiles],"profileConnections":[$binding]}}"""

    private val pending = """{"version":1,"rows":{"offlineWatchProgress":[$watchAction]}}"""

    private val expectedRows = TvosRecoveryRows(
        connections = listOf(EarlierReleaseConnectionRow("server-1", "jellyfin", "Server server-1", "{\"accessToken\":\"enc:v1:{}\"}", 1000, null)),
        profiles = listOf(EarlierReleaseProfileRow("local-1", "local", "Profile local-1", null, "{\"pinHash\":\"abc\"}", 0, 2000, null)),
        profileConnections = listOf(EarlierReleaseProfileConnectionRow("local-1", "server-1", "legacy-plaintext-profile-token", "user-1", true, null, 7)),
        offlineWatchProgress = listOf(
            EarlierReleaseOfflineWatchProgressRow(
                3, "local-1", "server-1", "server-1/user-1", "progress", "server-1:progress", "progress", 1234, 9999, false, 3000, 4000, 2, "retry",
            ),
        ),
    )

    private suspend fun sha256(value: String) =
        cryptoProvider.get(SHA256).hasher().hash(value.encodeToByteArray()).joinToString("") { (it.toInt() and 0xFF).toString(16).padStart(2, '0') }

    /** A committed image of [identity] and [pending] as the earlier releases wrote it, plus [extra] preferences. */
    private suspend fun image(
        identity: String = identity(),
        pending: String = this.pending,
        manifest: String? = null,
        extra: Map<String, EarlierReleasePrefValue> = emptyMap(),
    ): EarlierReleasePrefs = EarlierReleasePrefs(
        mapOf(
            TVOS_RECOVERY_MANIFEST_KEY to StringValue(
                manifest ?: """{"version":1,"state":"committed","identityDigest":"${sha256(identity)}","pendingDigest":"${sha256(pending)}"}""",
            ),
            TVOS_RECOVERY_IDENTITY_KEY to StringValue(identity),
            TVOS_RECOVERY_PENDING_KEY to StringValue(pending),
        ) + extra,
    )

    private suspend fun missingDatabase(prefs: EarlierReleasePrefs) = classifyTvosStartup(prefs, databaseExists = false)

    @Test
    fun restoresTheFourCriticalGroupsFromACommittedImage() = runTest {
        assertEquals(TvosRecoveryDecision.Restore(expectedRows), missingDatabase(image()))
    }

    @Test
    fun restoresALegacyImageIgnoringTheRetiredConnectionColumn() = runTest {
        val legacyConnection = connection.replace("\"createdAt\"", "\"isDefault\":true,\"createdAt\"")

        assertEquals(TvosRecoveryDecision.Restore(expectedRows), missingDatabase(image(identity(connections = legacyConnection))))
    }

    @Test
    fun missingDatabaseWithoutMarkerOrEvidenceIsFresh() = runTest {
        assertEquals(TvosRecoveryDecision.Fresh, missingDatabase(EarlierReleasePrefs(mapOf("view_mode" to StringValue("grid")))))
    }

    @Test
    fun aWrongTypedRecoveryMarkerBehavesLikeAMissingOne() = runTest {
        assertEquals(TvosRecoveryDecision.Fresh, missingDatabase(EarlierReleasePrefs(mapOf(TVOS_RECOVERY_REQUIRED_KEY to StringValue("yes")))))
    }

    @Test
    fun missingDatabaseWithPriorInstallEvidenceRequiresRecovery() = runTest {
        for (evidence in listOf(
            "active_app_profile_id" to StringValue("surviving-profile"),
            "profile_migration_v1_done" to BoolValue(true),
            EarlierReleasePrefs.VAULT_KEY to StringValue("a2V5"),
        )) {
            assertEquals(TvosRecoveryDecision.RecoveryRequired, missingDatabase(EarlierReleasePrefs(mapOf(evidence))), evidence.first)
        }
        assertEquals(TvosRecoveryDecision.Fresh, missingDatabase(EarlierReleasePrefs(mapOf("active_app_profile_id" to StringValue("")))))
    }

    @Test
    fun anExistingDatabaseIsAuthoritative() = runTest {
        assertEquals(TvosRecoveryDecision.UseDatabase, classifyTvosStartup(image(), databaseExists = true))
    }

    @Test
    fun theRecoveryRequiredMarkerRestoresAValidImageOverAnExistingDatabase() = runTest {
        val marked = image(extra = mapOf(TVOS_RECOVERY_REQUIRED_KEY to BoolValue(true)))

        assertEquals(TvosRecoveryDecision.Restore(expectedRows), classifyTvosStartup(marked, databaseExists = true))
    }

    @Test
    fun theRecoveryRequiredMarkerWithoutAValidImageRequiresRecovery() = runTest {
        val marked = EarlierReleasePrefs(mapOf(TVOS_RECOVERY_REQUIRED_KEY to BoolValue(true)))

        assertEquals(TvosRecoveryDecision.RecoveryRequired, classifyTvosStartup(marked, databaseExists = true))
    }

    @Test
    fun rejectsInvalidImages() = runTest {
        val identity = identity()
        val invalid = mapOf(
            "absent payload" to EarlierReleasePrefs(image().values - TVOS_RECOVERY_IDENTITY_KEY),
            "corrupt manifest" to image(manifest = "{"),
            "unsupported version" to image(manifest = """{"version":99,"state":"committed","identityDigest":"${sha256(identity)}","pendingDigest":"${sha256(pending)}"}"""),
            "invalidated manifest" to image(manifest = """{"version":1,"state":"invalidated","identityDigest":"${sha256(identity)}","pendingDigest":"${sha256(pending)}"}"""),
            "manifest with a generation" to image(
                manifest = """{"version":1,"state":"committed","identityDigest":"${sha256(identity)}","pendingDigest":"${sha256(pending)}","identityGeneration":7}""",
            ),
            "digest mismatch" to EarlierReleasePrefs(image().values + (TVOS_RECOVERY_IDENTITY_KEY to StringValue("$identity "))),
            "payload with a generation" to image(identity = identity.replaceFirst("{", "{\"generation\":7,")),
            "missing group" to image(identity = """{"version":1,"rows":{"connections":[$connection],"profileConnections":[$binding]}}"""),
            "row that is not a map" to image(identity = """{"version":1,"rows":{"connections":[1],"profiles":[],"profileConnections":[]}}"""),
            "row with an unknown column" to image(identity(profiles = profile.replace("\"sortOrder\"", "\"extra\":1,\"sortOrder\""))),
            "row missing a nullable column" to image(identity(profiles = profile.replace("\"avatarThumbUrl\":null,", ""))),
            "int column as a double" to image(identity(profiles = profile.replace("\"createdAt\":2000", "\"createdAt\":2000.0"))),
            "configuration that is not an object" to image(identity(connections = connection.replace("{\\\"accessToken\\\":\\\"enc:v1:{}\\\"}", "[]"))),
        )
        for ((case, prefs) in invalid) {
            assertEquals(TvosRecoveryDecision.RecoveryRequired, missingDatabase(prefs), case)
        }
    }

    @Test
    fun anImageOverTheByteCeilingIsRejected() = runTest {
        assertEquals(TvosRecoveryDecision.RecoveryRequired, classifyTvosStartup(image(), databaseExists = false, byteCeiling = 1))
    }

    @Test
    fun unrelatedPreferencesDoNotCountTowardsTheCeiling() = runTest {
        val prefs = image(extra = mapOf("unrelated_large_setting" to StringValue("x".repeat(500_000))))

        assertEquals(TvosRecoveryDecision.Restore(expectedRows), missingDatabase(prefs))
    }

    @Test
    fun theImageSizeIsTheUtf8OfTheSortedRecoveryKeys() {
        val prefs = EarlierReleasePrefs(
            mapOf(
                TVOS_RECOVERY_REQUIRED_KEY to BoolValue(true),
                TVOS_RECOVERY_MANIFEST_KEY to StringValue("é\"\n"),
                "view_mode" to StringValue("grid"),
            ),
        )

        // {"tvos_db_recovery_manifest_v1":"é\"\n","tvos_db_recovery_required_v1":true}
        assertEquals(1 + 30 + 1 + 8 + 1 + 30 + 1 + 4 + 1, recoveryImageSize(prefs))
    }
}
