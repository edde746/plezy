package com.edde746.plezy.presentation.seerr

import com.edde746.plezy.backend.net.MockServer
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.seerr.SeerrClient
import com.edde746.plezy.seerr.SeerrPermission
import com.edde746.plezy.seerr.bodyJson
import com.edde746.plezy.seerr.json
import com.edde746.plezy.seerr.jsonObject
import com.edde746.plezy.seerr.path
import com.edde746.plezy.seerr.seerrClient
import com.edde746.plezy.seerr.session
import com.edde746.plezy.seerr.user
import com.edde746.plezy.strings.T
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.JsonObject

class SeerrRequestStoreTest {
    /**
     * A sheet for one title on a client of [permissions] whose requests reach [handler]. [connected] and [mask] stand
     * in for the account: a test changes the client's live mask with [refresh], then lets the sheet look again.
     *
     * The HTTP client finishes part of each answer off the test scheduler, so the tests wait on the sheet's state
     * ([until]) rather than on virtual time.
     */
    private inner class Sheet(
        private val scope: TestScope,
        permissions: Int,
        kind: MediaKind,
        tmdbId: Int,
        handler: suspend MockRequestHandleScope.(HttpRequestData) -> HttpResponseData,
    ) {
        val server = MockServer(scope, handler)
        val client: SeerrClient = scope.seerrClient(server, session().copy(permissions = permissions))
        val connected = MutableStateFlow<SeerrClient?>(client)
        val mask = MutableStateFlow<Int?>(permissions)
        var submitted = 0
        val store = SeerrRequestStore(tmdbId, kind, "Title", client, connected, mask, scope.backgroundScope) { submitted++ }

        suspend fun until(predicate: (SeerrRequestUiState) -> Boolean): SeerrRequestUiState = store.state.first(predicate)

        suspend fun ready(): SeerrRequestUiState = until { it.body !is SeerrRequestBody.Loading }

        /** The form once nothing is loading (the advanced options included). */
        suspend fun settled(): SeerrRequestBody.Form = until { (it.body as? SeerrRequestBody.Form)?.advanced?.loading != true && it.body is SeerrRequestBody.Form }.form

        /** Re-reads the user (the client takes the new mask) and lets the sheet reconcile with it. */
        suspend fun refresh() {
            client.refreshUser()
            mask.value = client.session.permissions
            scope.runCurrent()
        }

        val requests: List<String> get() = server.requests.map { it.path }
    }

    private val SeerrRequestUiState.form: SeerrRequestBody.Form get() = body as SeerrRequestBody.Form

    private fun SeerrRequestBody.Form.picker(kind: SeerrPickerKind): SeerrPicker? = advanced?.pickers?.firstOrNull { it.kind == kind }

    /** Posts the request and waits for the sheet to close; the posted body is in [posted]. */
    private suspend fun Sheet.submitAndClose(): SeerrRequestClosed {
        store.submit()
        return until { it.closed != null }.closed!!
    }

    private fun settings(extra: String = "") =
        """{"initialized":true,"localLogin":true,"mediaServerLogin":true,"movie4kEnabled":false,"series4kEnabled":false,"partialRequestsEnabled":true$extra}"""

    private fun radarrServer(id: Int, name: String, profileId: Int = 6, folder: String = "/movies") =
        """{"id":$id,"name":"$name","is4k":false,"isDefault":${id == 0},"activeProfileId":$profileId,"activeDirectory":"$folder"}"""

    private fun radarrDetail(server: String, profileId: Int, profileName: String, folder: String) =
        """{"server":$server,"profiles":[{"id":$profileId,"name":"$profileName"}],"rootFolders":[{"id":1,"path":"$folder"}]}"""

    private val sonarrServer =
        """{"id":0,"name":"Sonarr Main","is4k":false,"isDefault":true,"activeProfileId":1,"activeDirectory":"/tv",
        "activeLanguageProfileId":1,"activeAnimeProfileId":2,"activeAnimeDirectory":"/anime","activeAnimeLanguageProfileId":2,
        "activeTags":[7],"activeAnimeTags":[5]}"""

    private val sonarrDetail =
        """{"server":$sonarrServer,"profiles":[{"id":1,"name":"TV"},{"id":2,"name":"Anime"}],
        "rootFolders":[{"id":1,"path":"/tv"},{"id":2,"path":"/anime"}],
        "languageProfiles":[{"id":1,"name":"English"},{"id":2,"name":"Japanese"}],
        "tags":[{"id":5,"label":"anime"},{"id":7,"label":"tv"},{"id":9,"label":"uhd"}]}"""

    private fun tvDetails(anime: Boolean) =
        """{"id":46260,"name":"Naruto","keywords":[{"id":9715,"name":"superhero"}${if (anime) """,{"id":210024,"name":"anime"}""" else ""}],
        "seasons":[{"seasonNumber":1,"episodeCount":57,"name":"Season 1"}],
        "mediaInfo":{"status":1,"status4k":1,"seasons":[],"requests":[]}}"""

    private val fightClub = """{"id":550,"title":"Fight Club"}"""

    private fun movieWith(mediaInfo: String) = """{"id":603,"title":"The Matrix","mediaInfo":$mediaInfo}"""

    /** Gated answers a test releases later, out of order with the sheet's choices. */
    private class Gates {
        val pending = MutableStateFlow<List<CompletableDeferred<String>>>(emptyList())

        suspend fun MockRequestHandleScope.answer(): HttpResponseData {
            val gate = CompletableDeferred<String>()
            pending.value += gate
            return json(gate.await())
        }

        suspend fun awaitCount(count: Int) = pending.first { it.size >= count }
    }

    @Test
    fun tvDisablesUnavailableSeasonsDropsSpecialsAndPostsTheSelectedSeasons() = runTest {
        var posted: JsonObject? = null
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.SHOW, 1396) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/tv/1396" -> json(
                    """{"id":1396,"name":"Breaking Bad","seasons":[
                    {"seasonNumber":0,"episodeCount":5,"name":"Specials"},
                    {"seasonNumber":1,"episodeCount":7,"name":"Season 1"},
                    {"seasonNumber":2,"episodeCount":13,"name":"Season 2"}],
                    "mediaInfo":{"status":4,"status4k":1,"seasons":[{"seasonNumber":1,"status":5,"status4k":1}],"requests":[]}}""",
                )
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":10,"status":1}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }

        val form = sheet.ready().form
        val rows = form.seasons!!.rows
        assertEquals(listOf("Season 1", "Season 2"), rows.map { it.title })
        // Season 1 is on the server: labelled in place of its box, not chosen, disabled.
        assertEquals(T.seerr.statusAvailable, rows[0].blockedLabel)
        assertFalse(rows[0].checked)
        assertFalse(rows[0].enabled)
        assertEquals(T.explore.episodeCount(13), rows[1].subtitle)
        // Nothing chosen yet: nothing to submit.
        assertFalse(form.canSubmit)

        sheet.store.setSeasonSelected(2, true)
        val chosen = sheet.store.state.value.form
        assertTrue(chosen.canSubmit)
        assertTrue(chosen.seasons!!.allSelected)
        // Down from the last requestable season jumps to the Request button.
        assertEquals(2, chosen.submitJumpSeason)

        assertEquals(0, sheet.submitted)
        val closed = sheet.submitAndClose()
        assertEquals(jsonObject("""{"mediaType":"tv","mediaId":1396,"seasons":[2],"is4k":false}"""), posted)
        assertEquals(SeerrRequestCloseReason.SUBMITTED, closed.reason)
        // The title's other screens are told to look at its state again.
        assertEquals(1, sheet.submitted)
        assertEquals(T.seerr.requestSubmitted, closed.message)
        sheet.store.release()
    }

    @Test
    fun aMovieThatIsAlreadyAvailableOffersNothingToRequest() = runTest {
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":5,"status4k":1}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals(SeerrRequestBody.NothingToRequest(T.seerr.statusAvailable), sheet.ready().body)
        sheet.store.release()
    }

    @Test
    fun failedAndCompletedRequestsDoNotBlockRequestingAMovieAgain() = runTest {
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":1,"requests":[{"id":1,"status":4,"is4k":false},{"id":2,"status":5,"is4k":false}]}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertTrue(sheet.ready().form.canSubmit)
        sheet.store.release()
    }

    @Test
    fun aRealHandlerDenialReconcilesRevokedAuthorityAndClosesTheSheet() = runTest {
        // Permission, quota and blocklist denials share one answer: the authority read, not the message, closes it.
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":1}"""))
                "/api/v1/request" -> json("""{"message":"You do not have permission to make this request."}""", 403)
                "/api/v1/auth/me" -> json(user(0))
                else -> fail("unexpected request ${request.path}")
            }
        }
        sheet.ready()

        val closed = sheet.submitAndClose()
        assertEquals(listOf("/api/v1/request", "/api/v1/auth/me"), sheet.requests.takeLast(2))
        assertEquals(1, sheet.requests.count { it == "/api/v1/request" })
        assertEquals(SeerrRequestCloseReason.PERMISSION_REVOKED, closed.reason)
        assertEquals(T.seerr.permissionRevoked, closed.message)
        assertTrue(closed.isError)
        assertEquals(0, sheet.client.session.permissions)
        sheet.store.release()
    }

    @Test
    fun aFailedRequestUnblocksAStaleProcessingStatusWhenNothingLiveBacksIt() = runTest {
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":3,"requests":[{"id":1,"status":4,"is4k":false}]}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertTrue(sheet.ready().form.canSubmit)
        sheet.store.release()
    }

    @Test
    fun aLiveApprovedRetryKeepsAFailedTitleBlockedAsProcessing() = runTest {
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":3,"requests":[{"id":1,"status":4,"is4k":false},{"id":2,"status":2,"is4k":false}]}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals(SeerrRequestBody.NothingToRequest(T.seerr.statusProcessing), sheet.ready().body)
        sheet.store.release()
    }

    @Test
    fun aJellyseerrBlocklistedMovieOffersNothingToRequest() = runTest {
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                // mediaServerType marks Jellyseerr, where status 6 is BLOCKLISTED.
                "/api/v1/settings/public" -> json(settings(""","mediaServerType":2"""))
                "/api/v1/movie/603" -> json(movieWith("""{"status":6}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals(SeerrRequestBody.NothingToRequest(T.seerr.statusBlocklisted), sheet.ready().body)
        sheet.store.release()
    }

    @Test
    fun theSettingsFetchUpgradesALegacySessionSoOverseerrCode7StaysRequestable() = runTest {
        // The session doesn't know its product, where 7 reads as blocklisted; the settings name Overseerr.
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 603) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/603" -> json(movieWith("""{"status":7}"""))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertTrue(sheet.ready().form.canSubmit)
        sheet.store.release()
    }

    @Test
    fun theAdvancedPermissionLoadsServersAndSendsDestinationOverrides() = runTest {
        var posted: JsonObject? = null
        val main = radarrServer(0, "Radarr Main")
        val sheet = Sheet(this, SeerrPermission.ADMIN, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/service/radarr" -> json("[$main]")
                "/api/v1/service/radarr/0" -> json(
                    """{"server":$main,"profiles":[{"id":6,"name":"1080p"},{"id":7,"name":"4K Remux"}],"rootFolders":[{"id":1,"path":"/movies"}]}""",
                )
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }

        val form = sheet.settled()
        // One server: no server picker; the profile and folder show the instance defaults as Seerr marks them.
        assertNull(form.picker(SeerrPickerKind.SERVER))
        assertEquals("1080p (Default)", form.picker(SeerrPickerKind.QUALITY_PROFILE)?.value)
        assertEquals(listOf("1080p (Default)", "4K Remux"), form.picker(SeerrPickerKind.QUALITY_PROFILE)?.options?.map { it.label })
        // No tags in the options: nothing to pick, nothing to override.
        assertNull(form.advanced?.tags)

        sheet.submitAndClose()
        assertEquals(
            jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":false,"serverId":0,"profileId":6,"rootFolder":"/movies"}"""),
            posted,
        )
        sheet.store.release()
    }

    @Test
    fun permissionChangesWhileOpenReshapeAndThenCloseTheSheet() = runTest {
        var permissions = SeerrPermission.REQUEST
        val main = radarrServer(0, "Radarr Main")
        val sheet = Sheet(this, permissions, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/auth/me" -> json(user(permissions))
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/service/radarr" -> json("[$main,${radarrServer(1, "Radarr Alt")}]")
                "/api/v1/service/radarr/0" -> json(radarrDetail(main, 6, "1080p", "/movies"))
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertNull(sheet.ready().form.advanced)
        assertFalse("/api/v1/service/radarr" in sheet.requests)

        // A grant loads the servers the first load skipped.
        permissions = SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED
        sheet.refresh()
        val granted = sheet.until { (it.body as? SeerrRequestBody.Form)?.picker(SeerrPickerKind.SERVER) != null }.form
        assertEquals("Radarr Main", granted.picker(SeerrPickerKind.SERVER)?.value)

        // Losing the request permission closes the sheet with the reason.
        permissions = 0
        sheet.refresh()
        assertEquals(SeerrRequestCloseReason.PERMISSION_REVOKED, sheet.until { it.closed != null }.closed?.reason)
        sheet.store.release()
    }

    @Test
    fun aQuotaDenialKeepsTheSheetUsableAndShowsTheOriginalError() = runTest {
        var posts = 0
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/auth/me" -> json(user(SeerrPermission.REQUEST))
                "/api/v1/request" -> {
                    posts++
                    json("""{"message":"Request quota exceeded"}""", 403)
                }
                else -> fail("no sign-in or replay expected: ${request.path}")
            }
        }
        sheet.ready()

        sheet.store.submit()
        val form = sheet.until { (it.body as? SeerrRequestBody.Form)?.error != null }
        assertEquals(1, posts)
        assertNull(form.closed)
        assertEquals("Request quota exceeded", form.form.error)
        assertTrue(form.form.canSubmit)
        sheet.store.release()
    }

    @Test
    fun aReplacedAccountSilentlyClosesItsOldSheetAndIgnoresTheLateSubmission() = runTest {
        val post = CompletableDeferred<Unit>()
        val sheet = Sheet(this, SeerrPermission.REQUEST, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/request" -> {
                    post.await()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected ${request.path}")
            }
        }
        sheet.ready()
        sheet.store.submit()
        sheet.until { (it.body as? SeerrRequestBody.Form)?.submitting == true }

        sheet.connected.value = seerrClient(sheet.server, session().copy(cookie = "new-account"))
        val closed = sheet.until { it.closed != null }.closed
        assertEquals(SeerrRequestClosed(SeerrRequestCloseReason.SILENT, null, isError = false), closed)

        post.complete(Unit)
        // A later round trip on the same client lands after the late answer.
        sheet.client.getMovie(550)
        assertEquals(closed, sheet.store.state.value.closed)
        sheet.store.release()
    }

    @Test
    fun aRevokeAndRegrantDiscardsTheOlderAdvancedServerList() = runTest {
        var permissions = SeerrPermission.REQUEST
        var posted: JsonObject? = null
        val lists = Gates()
        val fresh = radarrServer(1, "Current", profileId = 9, folder = "/current")
        val sheet = Sheet(this, permissions, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/auth/me" -> json(user(permissions))
                "/api/v1/service/radarr" -> with(lists) { answer() }
                "/api/v1/service/radarr/1" -> json(radarrDetail(fresh, 9, "Current", "/current"))
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("stale server must not be selected: ${request.path}")
            }
        }
        sheet.ready()
        permissions = permissions or SeerrPermission.REQUEST_ADVANCED
        sheet.refresh()
        lists.awaitCount(1)
        permissions = SeerrPermission.REQUEST
        sheet.refresh()
        permissions = permissions or SeerrPermission.REQUEST_ADVANCED
        sheet.refresh()
        lists.awaitCount(2)
        permissions = permissions or SeerrPermission.REQUEST_4K
        sheet.refresh()

        lists.pending.value[1].complete("[$fresh]")
        sheet.until { (it.body as? SeerrRequestBody.Form)?.picker(SeerrPickerKind.QUALITY_PROFILE)?.value == "Current (Default)" }
        lists.pending.value[0].complete("[${radarrServer(0, "Stale")}]")

        sheet.submitAndClose()
        assertEquals(
            jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":false,"serverId":1,"profileId":9,"rootFolder":"/current"}"""),
            posted,
        )
        assertEquals(2, lists.pending.value.size)
        sheet.store.release()
    }

    @Test
    fun aRevoked4kSwitchMovesFocusAndALaterGrantDoesNotRestoreItsChoice() = runTest {
        var permissions = SeerrPermission.REQUEST or SeerrPermission.REQUEST_4K
        var posted: JsonObject? = null
        val sheet = Sheet(this, permissions, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings().replace(""""movie4kEnabled":false""", """"movie4kEnabled":true"""))
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/auth/me" -> json(user(permissions))
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected ${request.path}")
            }
        }
        assertEquals(false, sheet.ready().form.request4k)
        sheet.store.set4k(true)
        assertEquals(true, sheet.store.state.value.form.request4k)

        permissions = SeerrPermission.REQUEST
        sheet.refresh()
        val revoked = sheet.store.state.value
        assertNull(revoked.form.request4k)
        assertEquals(SeerrRequestFocusTarget.SUBMIT, revoked.refocus?.target)

        permissions = permissions or SeerrPermission.REQUEST_4K
        sheet.refresh()
        assertEquals(false, sheet.store.state.value.form.request4k)

        sheet.submitAndClose()
        assertEquals(jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":false}"""), posted)
        sheet.store.release()
    }

    @Test
    fun anAnimeSeriesSeedsTheAdvancedPickersFromTheSonarrAnimeDefaults() = runTest {
        var posted: JsonObject? = null
        // The list route reports no usable tags (`activeTags: []`, no anime tags).
        val listed = sonarrServer.replace(""""activeTags":[7],"activeAnimeTags":[5]""", """"activeTags":[]""")
        val sheet = Sheet(this, SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED, MediaKind.SHOW, 46260) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/tv/46260" -> json(tvDetails(anime = true))
                "/api/v1/service/sonarr" -> json("[$listed]")
                "/api/v1/service/sonarr/0" -> json(sonarrDetail)
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":12,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }

        val form = sheet.settled()
        assertEquals("Anime (Default)", form.picker(SeerrPickerKind.QUALITY_PROFILE)?.value)
        assertEquals("/anime (Default)", form.picker(SeerrPickerKind.ROOT_FOLDER)?.value)
        assertEquals("Japanese (Default)", form.picker(SeerrPickerKind.LANGUAGE_PROFILE)?.value)
        assertEquals("anime", form.advanced?.tags?.summary)
        assertEquals(T.seerr.animeNote, form.advanced?.animeNote)
        // Visible advanced controls sit between the seasons and the button: no jump.
        sheet.store.setSeasonSelected(1, true)
        assertNull(sheet.store.state.value.form.submitJumpSeason)

        sheet.submitAndClose()
        assertEquals(
            jsonObject(
                """{"mediaType":"tv","mediaId":46260,"seasons":[1],"is4k":false,"serverId":0,"profileId":2,"rootFolder":"/anime",
                "languageProfileId":2,"tags":[5]}""",
            ),
            posted,
        )
        sheet.store.release()
    }

    @Test
    fun aNonAnimeSeriesKeepsTheStandardDefaultsAndLetsTheUserEditTags() = runTest {
        var posted: JsonObject? = null
        val sheet = Sheet(this, SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED, MediaKind.SHOW, 46260) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/tv/46260" -> json(tvDetails(anime = false))
                "/api/v1/service/sonarr" -> json("[$sonarrServer]")
                "/api/v1/service/sonarr/0" -> json(sonarrDetail)
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":12,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }

        val form = sheet.settled()
        assertEquals("TV (Default)", form.picker(SeerrPickerKind.QUALITY_PROFILE)?.value)
        assertEquals("/tv (Default)", form.picker(SeerrPickerKind.ROOT_FOLDER)?.value)
        assertNull(form.advanced?.animeNote)
        assertEquals("tv", form.advanced?.tags?.summary)
        assertFalse(form.advanced!!.tags!!.expanded)

        // A season chosen before the tag list opens survives it.
        sheet.store.setSeasonSelected(1, true)
        sheet.store.toggleTagsExpanded()
        assertTrue(sheet.store.state.value.form.advanced!!.tags!!.expanded)
        sheet.store.setTagSelected(9, true)
        assertEquals("tv, uhd", sheet.store.state.value.form.advanced?.tags?.summary)
        sheet.store.setTagSelected(7, false)
        assertEquals("uhd", sheet.store.state.value.form.advanced?.tags?.summary)
        sheet.store.toggleTagsExpanded()
        assertTrue(sheet.store.state.value.form.seasons!!.rows.single().checked)

        sheet.submitAndClose()
        assertEquals(
            jsonObject(
                """{"mediaType":"tv","mediaId":46260,"seasons":[1],"is4k":false,"serverId":0,"profileId":1,"rootFolder":"/tv",
                "languageProfileId":1,"tags":[9]}""",
            ),
            posted,
        )
        sheet.store.release()
    }

    @Test
    fun aSlowDetailLoadForAServerTheUserLeftNeverReplacesTheCurrentServer() = runTest {
        var posted: JsonObject? = null
        val alt = Gates()
        val main = radarrServer(0, "Radarr Main")
        val altServer = radarrServer(1, "Radarr Alt", profileId = 8, folder = "/alt")
        val sheet = Sheet(this, SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/service/radarr" -> json("[$main,$altServer]")
                "/api/v1/service/radarr/0" -> json(radarrDetail(main, 6, "1080p", "/movies"))
                "/api/v1/service/radarr/1" -> with(alt) { answer() }
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals("1080p (Default)", sheet.settled().picker(SeerrPickerKind.QUALITY_PROFILE)?.value)

        sheet.store.select(SeerrPickerKind.SERVER, 1)
        val leaving = sheet.store.state.value.form
        assertTrue(leaving.advanced!!.loading)
        assertNull(leaving.picker(SeerrPickerKind.QUALITY_PROFILE))
        alt.awaitCount(1)

        sheet.store.select(SeerrPickerKind.SERVER, 0)
        assertEquals("1080p (Default)", sheet.settled().picker(SeerrPickerKind.QUALITY_PROFILE)?.value)

        alt.pending.value.single().complete(radarrDetail(altServer, 8, "Alt 720p", "/alt"))
        sheet.submitAndClose()
        assertEquals(
            jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":false,"serverId":0,"profileId":6,"rootFolder":"/movies"}"""),
            posted,
        )
        sheet.store.release()
    }

    @Test
    fun reSelectingTheSameServerAppliesOnlyTheNewestDetailResponse() = runTest {
        var posted: JsonObject? = null
        val gated = Gates()
        var mainCalls = 0
        val main = radarrServer(0, "Radarr Main")
        val altServer = radarrServer(1, "Radarr Alt", profileId = 8, folder = "/alt")
        val sheet = Sheet(this, SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings())
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/service/radarr" -> json("[$main,$altServer]")
                // The first load answers at once; every later one waits.
                "/api/v1/service/radarr/0" -> if (mainCalls++ == 0) json(radarrDetail(main, 6, "Initial", "/movies")) else with(gated) { answer() }
                "/api/v1/service/radarr/1" -> json(radarrDetail(altServer, 8, "Alt 720p", "/alt"))
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals("Initial (Default)", sheet.settled().picker(SeerrPickerKind.QUALITY_PROFILE)?.value)

        // Main → Alt → Main → Alt → Main: two Main loads in flight.
        for (id in listOf(1, 0, 1, 0)) sheet.store.select(SeerrPickerKind.SERVER, id)
        gated.awaitCount(2)
        assertTrue(sheet.store.state.value.form.advanced!!.loading)

        // The abandoned load lands first: same server, but it neither ends the spinner nor installs its options.
        gated.pending.value[0].complete(radarrDetail(main, 6, "Stale", "/movies"))
        gated.pending.value[1].complete(radarrDetail(main, 6, "Fresh", "/movies"))
        val fresh = sheet.settled()
        assertEquals("Fresh (Default)", fresh.picker(SeerrPickerKind.QUALITY_PROFILE)?.value)

        sheet.submitAndClose()
        assertEquals(
            jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":false,"serverId":0,"profileId":6,"rootFolder":"/movies"}"""),
            posted,
        )
        sheet.store.release()
    }

    @Test
    fun switchingToAVariantWithoutServersDropsTheInFlightDetailLoad() = runTest {
        var posted: JsonObject? = null
        val gated = Gates()
        var mainCalls = 0
        val main = radarrServer(0, "Radarr Main")
        val permissions = SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED or SeerrPermission.REQUEST_4K or SeerrPermission.REQUEST_4K_MOVIE
        val sheet = Sheet(this, permissions, MediaKind.MOVIE, 550) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings().replace(""""movie4kEnabled":false""", """"movie4kEnabled":true"""))
                "/api/v1/movie/550" -> json(fightClub)
                "/api/v1/service/radarr" -> json("[$main]")
                "/api/v1/service/radarr/0" -> if (mainCalls++ == 0) json(radarrDetail(main, 6, "1080p", "/movies")) else with(gated) { answer() }
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":11,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals("1080p (Default)", sheet.settled().picker(SeerrPickerKind.QUALITY_PROFILE)?.value)

        // 4K on (no 4K instance: no destination), off again: a fresh options load.
        sheet.store.set4k(true)
        assertNull(sheet.store.state.value.form.advanced)
        sheet.store.set4k(false)
        gated.awaitCount(1)
        assertTrue(sheet.store.state.value.form.advanced!!.loading)

        // Back to 4K while it loads: the late answer must not bring the non-4K destination back.
        sheet.store.set4k(true)
        assertNull(sheet.store.state.value.form.advanced)
        gated.pending.value.single().complete(radarrDetail(main, 6, "1080p", "/movies"))

        sheet.submitAndClose()
        assertEquals(jsonObject("""{"mediaType":"movie","mediaId":550,"is4k":true}"""), posted)
        sheet.store.release()
    }

    @Test
    fun tagsTheUserClearedStayEmptyWhenAnOlderDetailLoadLands() = runTest {
        var posted: JsonObject? = null
        val gated = Gates()
        var mainCalls = 0
        val permissions = SeerrPermission.REQUEST or SeerrPermission.REQUEST_ADVANCED or SeerrPermission.REQUEST_4K or SeerrPermission.REQUEST_4K_TV
        val sheet = Sheet(this, permissions, MediaKind.SHOW, 46260) { request ->
            when (request.path) {
                "/api/v1/settings/public" -> json(settings().replace(""""series4kEnabled":false""", """"series4kEnabled":true"""))
                "/api/v1/tv/46260" -> json(tvDetails(anime = false))
                "/api/v1/service/sonarr" -> json("[$sonarrServer]")
                "/api/v1/service/sonarr/0" -> if (mainCalls++ == 0) json(sonarrDetail) else with(gated) { answer() }
                "/api/v1/request" -> {
                    posted = request.bodyJson()
                    json("""{"id":12,"status":2}""", 201)
                }
                else -> fail("unexpected request ${request.path}")
            }
        }
        assertEquals("tv", sheet.settled().advanced?.tags?.summary)

        // Two 4K round trips leave two loads of the same instance in flight; only the second counts.
        repeat(2) {
            sheet.store.set4k(true)
            sheet.store.set4k(false)
        }
        gated.awaitCount(2)
        gated.pending.value[1].complete(sonarrDetail)
        assertEquals("tv", sheet.settled().advanced?.tags?.summary)

        // The user clears the instance's default tag; the abandoned load landing later keeps the edit.
        sheet.store.setTagSelected(7, false)
        assertEquals(T.seerr.noTags, sheet.store.state.value.form.advanced?.tags?.summary)
        gated.pending.value[0].complete(sonarrDetail)

        sheet.store.setSeasonSelected(1, true)
        sheet.submitAndClose()
        assertEquals(
            jsonObject(
                """{"mediaType":"tv","mediaId":46260,"seasons":[1],"is4k":false,"serverId":0,"profileId":1,"rootFolder":"/tv",
                "languageProfileId":1,"tags":[]}""",
            ),
            posted,
        )
        sheet.store.release()
    }
}
