package com.edde746.plezy.watch

import com.edde746.plezy.backend.FakeMediaBackend
import com.edde746.plezy.log.Log
import com.edde746.plezy.model.ExternalIds
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.putJsonObject
import party.openwatch.Connection
import party.openwatch.Control
import party.openwatch.EndReason
import party.openwatch.MatchState
import party.openwatch.PartyException
import party.openwatch.Phase
import party.openwatch.PlayerState
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

/** Watch Together for one profile session: rooms, the room's media and the player the room drives. */
class WatchTogetherTest {
    // Outside a room

    @Test
    fun `works without a room with presses left to the player and the public relays`() = runTest {
        watchWorld {
            val watch = member("Anna").watch
            assertFalse(watch.state.value.inSession)
            assertNull(watch.state.value.room)
            assertTrue(watch.participants.isEmpty())
            assertEquals(Control.HOST, watch.state.value.control)
            assertNull(watch.state.value.media)
            assertEquals(WatchPartyRelays.relayScopeOf(null), watch.relayScope)
            assertNull(watch.state.value.relayBaseUrl)
            assertFalse(watch.play())
            assertFalse(watch.pause())
            assertFalse(watch.seek(5_000))
            assertFalse(watch.setRate(1.5))
            watch.leave()

            assertEquals(PartyException.INVALID_CODE, refusal { watch.joinRoom("K7M-Q2") })
            assertFalse(watch.state.value.inSession)
            assertTrue(relay.received.isEmpty(), "no relay was asked")
            assertEquals(Connection.IDLE, watch.state.value.connection)
        }
    }

    @Test
    fun `a player opened outside a room is only remembered and another one releases it`() = runTest {
        watchWorld {
            val member = host()
            val first = openPlayer(copyOf(alien("alien", "nas")))
            val second = openPlayer(copyOf(alien("alien-2", "nas")))

            member.watch.playerOpened(first.adapter, shareable = true, roomLaunch = false)
            assertFalse(member.watch.isFollowing)
            assertFalse(settle { member.watch.shareCopy(first.adapter) })
            assertFalse(first.adapter.isReleased)

            member.watch.playerOpened(second.adapter, shareable = true, roomLaunch = false)
            assertTrue(first.adapter.isReleased)

            settle { member.watch.playerClosed(second.adapter, continuing = false).join() }
            assertTrue(second.adapter.isReleased)
            assertTrue(first.player.commandLog.isEmpty())
        }
    }

    // In a room

    @Test
    fun `create and join show the code and the participants with their names and clients and a join notice`() = runTest {
        watchWorld {
            val h = host(profileScope = "profile-host")
            val g = member(" \u200FGuest\tOne\n", profileScope = "profile-guest")

            val code = settle { h.watch.createRoom() }
            assertEquals(FakeOwpRelay.CODE, code)
            assertEquals(code, h.state.roomCode)
            assertEquals("K7M-Q2X", h.state.formattedRoomCode)
            assertTrue(h.watch.isConnected && h.state.inSession && h.watch.isHost)
            assertEquals(WatchPartyRelays.relayScopeOf(null), h.watch.relayScope)

            settle { g.watch.joinRoom("k7m-q2x") }
            until("the host sees the guest") { h.watch.participants.size == 2 }

            assertEquals(code, g.state.roomCode)
            assertFalse(g.watch.isHost)
            assertFalse(g.watch.canControl)
            assertEquals(Control.HOST, g.state.control)
            assertEquals(h.peerId, g.state.host?.peerId)
            assertNotEquals(h.peerId, g.peerId)
            for (view in listOf(h, g)) {
                assertEquals(mapOf(h.peerId to "Host", g.peerId to "Guest One"), view.watch.participants.associate { it.peerId to it.name })
                assertEquals(setOf(WatchWorld.CLIENT), view.watch.participants.map { it.client }.toSet())
            }
            assertEquals("Guest One", relay.sent("join").single()["name"].toString().trim('"'))
            noticed<WatchNotice.Joined>(h, "the host is told") { it.name == "Guest One" }
            assertTrue(g.noticesOf<WatchNotice.Joined>().isEmpty())

            for (profile in listOf("profile-host", "profile-guest")) {
                val rooms = settle { recentRooms.observe(profile, WatchPartyRelays.relayScopeOf(null)).first() }
                assertEquals(listOf(code), rooms.map { it.code }, profile)
                val elsewhere = settle { recentRooms.observe(profile, WatchPartyRelays.relayScopeOf("http://x.test")).first() }
                assertTrue(elsewhere.isEmpty(), profile)
            }
        }
    }

    @Test
    fun `a code without a room is refused and a display name without text is Plezy`() = runTest {
        watchWorld {
            val h = member("\u202E\n")
            settle { h.watch.createRoom() }
            val g = guest()

            assertEquals(PartyException.ROOM_NOT_FOUND, refusal { g.watch.joinRoom("K7M-Q2Y") })
            assertFalse(g.state.inSession)
            assertEquals("Plezy", h.watch.participants.single().name)
        }
    }

    @Test
    fun `every failed join is logged with the relays it tried and the code while the user sees only its text`() = runTest {
        val lines = mutableListOf<String>()
        val sink = Log.sink
        Log.sink = Log.Sink { level, tag, message, _ -> if (tag == "WatchTogether" && level == Log.Level.WARN) lines += message }
        try {
            watchWorld {
                val g = guest()
                assertEquals(PartyException.ROOM_NOT_FOUND, refusal { g.watch.joinRoom("K7M-Q2Y") })
                relayBaseUrl.value = "http://relay.example.test"
                assertEquals(PartyException.ROOM_NOT_FOUND, refusal { g.watch.joinRoom("K7M-Q2Y", create = false) })
                assertTrue(g.notices.isEmpty(), "the screen shows the code's text, not the relay's message")
            }
        } finally {
            Log.sink = sink
        }
        assertEquals(2, lines.size, "$lines")
        assertTrue(lines[0].startsWith("join failed on the public relays: room_not_found: "), lines[0])
        assertTrue(lines[1].startsWith("join failed on the custom relay: room_not_found: "), lines[1])
    }

    @Test
    fun `host transfer and control mode and lock work and a guest is refused host commands`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            together(h, listOf(g))

            g.watch.setLocked(true)
            g.watch.setControl(Control.EVERYONE)
            g.watch.transferHost(h.peerId)
            g.watch.endRoom()
            runFor(0)
            assertEquals(List(4) { PartyException.FORBIDDEN }, g.noticesOf<WatchNotice.Refused>().map { it.code })

            h.watch.setControl(Control.EVERYONE)
            until("all control") { g.watch.canControl && g.state.control == Control.EVERYONE }

            h.watch.setLocked(true)
            until("the guest sees the lock") { g.state.locked }
            val latecomer = guest("Late")
            assertEquals("room_locked", refusal { latecomer.watch.joinRoom(h.state.roomCode!!) })
            h.watch.setLocked(false)
            until("the guest sees the unlock") { !g.state.locked }
            settle { latecomer.watch.joinRoom(h.state.roomCode!!) }
            until("the latecomer is in") { h.watch.participants.size == 3 }

            h.watch.transferHost(g.peerId)
            until("the guest is host") { g.watch.isHost && !h.watch.isHost }
            assertEquals(g.peerId, h.state.host?.peerId)
            assertEquals(g.peerId, latecomer.state.host?.peerId)
            h.watch.kick(latecomer.peerId)
            runFor(0)
            assertEquals(PartyException.FORBIDDEN, h.noticesOf<WatchNotice.Refused>().single().code)
        }
    }

    @Test
    fun `a kicked guest is told and the room goes on without them`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            together(h, listOf(g))

            h.watch.kick(g.peerId)
            noticed<WatchNotice.Ended>(g, "the guest is told") { it.reason == EndReason.KICKED }
            until("the guest is out") { !g.state.inSession }
            assertEquals(EndReason.KICKED, g.state.party.endReason)
            assertNull(g.state.room)
            until("the host is alone") { h.watch.participants.size == 1 }
            assertTrue(h.watch.isConnected)
            assertTrue(h.noticesOf<WatchNotice.Ended>().isEmpty())
        }
    }

    @Test
    fun `closing it as a profile switch does leaves the room at once`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            together(h, listOf(g))

            g.watch.close()
            // Left, not dropped: a dropped guest would stay listed while the relay keeps its place for a resume.
            noticed<WatchNotice.Left>(h, "the host sees the guest go") { it.name == "Guest" }
            until("the host is alone") { h.watch.participants.size == 1 }
        }
    }

    @Test
    fun `leaving tells the others without an end notice and ending ends it for everyone`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            val other = guest("Other")
            together(h, listOf(g, other))

            g.watch.leave()
            until("the guest is out") { !g.state.inSession }
            noticed<WatchNotice.Left>(h, "the host is told") { it.name == "Guest" }
            until("the other guest sees two") { other.watch.participants.size == 2 }
            assertEquals(EndReason.LEFT, g.state.party.endReason)
            assertTrue(g.noticesOf<WatchNotice.Ended>().isEmpty())
            g.watch.leave()

            h.watch.endRoom()
            noticed<WatchNotice.Ended>(other, "the other guest is told") { it.reason == EndReason.ENDED }
            until("the room is over") { !h.state.inSession && !other.state.inSession }
            assertEquals(EndReason.ENDED, other.state.party.endReason)
        }
    }

    @Test
    fun `leaving a join the relay has not answered cancels it without an end notice`() = runTest {
        watchWorld {
            val h = host()
            settle { h.watch.createRoom() }
            val g = guest()
            relay.holdJoins = true
            var refused: String? = null
            var done = false
            test.backgroundScope.launch {
                refused = try {
                    g.watch.joinRoom(FakeOwpRelay.CODE)
                    null
                } catch (e: PartyException) {
                    e.code
                }
                done = true
            }
            until("the join reached the relay") { relay.sent("join").isNotEmpty() }
            assertTrue(g.state.inSession, "joining")

            g.watch.leave()
            until("the join ended") { done }
            assertEquals(PartyException.CANCELLED, refused)
            assertFalse(g.state.inSession)
            relay.releaseJoins()
            runFor(1_000)
            assertFalse(g.state.inSession, "a late answer doesn't put the user in the room")
            assertTrue(g.noticesOf<WatchNotice.Ended>().isEmpty())
            assertTrue(g.noticesOf<WatchNotice.Refused>().isEmpty())
            assertEquals(1, h.watch.participants.size)
        }
    }

    @Test
    fun `a command the relay refuses and one the party refuses each tell the user why`() = runTest {
        watchWorld {
            val f = following()
            f.host.watch.setControl(Control.EVERYONE)
            until("the guest controls playback") { f.guest.watch.canControl }

            // The host takes control back while the guest's pause is on its way: the relay refuses the pause.
            f.host.watch.setControl(Control.HOST)
            assertTrue(f.guest.watch.pause())
            noticed<WatchNotice.Refused>(f.guest, "the relay's refusal is told") { it.code == PartyException.FORBIDDEN }
            until("the guest sees the host controls playback") { !f.guest.watch.canControl }

            f.guest.watch.setLocked(true)
            runFor(0)
            assertEquals(2, f.guest.noticesOf<WatchNotice.Refused>().size, "refused by the party before any message")
            for (notice in f.guest.noticesOf<WatchNotice.Refused>()) assertEquals("Only the host can do that.", WatchLabels.noticeText(notice))
            assertTrue(relay.sent("lock").isEmpty())
        }
    }

    @Test
    fun `a new join closes the room session before it and the open player follows in the new one at once`() = runTest {
        watchWorld {
            val f = following()
            val first = f.guest.peerId

            settle { f.guest.watch.joinRoom(f.host.state.roomCode!!) }
            noticed<WatchNotice.Left>(f.host, "the first session left") { it.name == "Guest" }
            until("one session of the guest is in the room") { relay.peerIds.size == 2 && first !in relay.peerIds }
            until("the open player follows the new session") { f.guest.watch.isFollowing }
            assertEquals(1, f.screen.players.size, "the player that was open, not a new one")
        }
    }

    @Test
    fun `the host shares its file and a guest finds its own copy and opens it and follows`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest

            assertEquals("0", relay.sent("setMedia").single()["positionMs"].toString())
            val media = h.state.media!!
            assertEquals(party.openwatch.MediaKind.MOVIE, media.kind)
            assertEquals("Alien", media.title)
            assertEquals(1979L, media.year)
            assertEquals(ALIEN_MS, media.durationMs)
            assertEquals(mapOf("imdb" to "tt0078748", "tmdb" to "348"), media.ids)
            assertEquals(
                buildJsonObject {
                    putJsonObject("app.plezy") {
                        put("server", "host-nas")
                        put("item", "alien")
                        put("version", "hd")
                    }
                },
                media.ext,
            )
            assertEquals("", h.watch.roomCopy?.id)
            assertTrue(h.watch.isFollowing)
            assertFalse(h.state.canJoinPlayback)

            // The guest searched by the identity the descriptor carried.
            val query = guestQueries.single()
            assertEquals(MediaKind.MOVIE, query.kind)
            assertEquals("Alien", query.title)
            assertEquals(1979, query.year)
            assertEquals(ExternalIds(imdb = "tt0078748", tmdb = 348), query.ids)

            assertEquals(media, g.state.media)
            assertEquals(MatchState.MATCHED, g.state.party.match?.state)
            assertEquals(800L, g.state.party.match?.deltaMs)
            assertEquals(copyOf(guestAlien), f.screen.players.single().adapter.copy)
            assertEquals(copyOf(guestAlien), g.watch.roomCopy?.ref)
            assertFalse(g.state.canJoinPlayback)
            until("the host sees the guest matched") { h.participant(g.peerId).match?.state == MatchState.MATCHED }
            assertFalse(f.hostPlayer.adapter.isReleased)
        }
    }

    @Test
    fun `presses go through the room while following and without control they are refused`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest
            val bystander = guest("Bystander")
            settle { bystander.watch.joinRoom(h.state.roomCode!!) }
            until("the bystander is in") { h.watch.participants.size == 3 }
            until("the shared file plays") { f.hostPlayer.player.playing }

            assertTrue(g.watch.pause(), "the screen leaves its player alone")
            assertFalse(bystander.watch.pause(), "without the room file open the player is the user's own")
            runFor(100)
            assertIs<WatchNotice.ControlRefused>(g.notices.last())
            assertTrue(relay.sent("pause").isEmpty())

            h.watch.setControl(Control.EVERYONE)
            until("the guest controls") { g.watch.canControl }

            assertTrue(g.watch.pause())
            noticed<WatchNotice.Action>(h, "the host sees the pause") { it.kind == "pause" && it.name == "Guest" }
            until("the host player pauses") { !f.hostPlayer.player.playing }

            assertTrue(g.watch.play())
            noticed<WatchNotice.Action>(h, "the host sees the play") { it.kind == "play" }
            until("the host player plays") { f.hostPlayer.player.playing }

            assertTrue(g.watch.seek(600_000))
            noticed<WatchNotice.Action>(h, "the host sees the seek") { it.kind == "seek" }
            assertEquals(WatchNotice.Action("seek", name = "Guest", positionMs = 600_000), h.noticesOf<WatchNotice.Action>().last())

            assertTrue(g.watch.setRate(3.0))
            noticed<WatchNotice.Action>(h, "the host sees the rate") { it.kind == "rate" }
            assertEquals(WatchNotice.Action("rate", name = "Guest", rate = WatchPartyRelays.MAX_RATE), h.noticesOf<WatchNotice.Action>().last())
            assertEquals(WatchPartyRelays.MAX_RATE, h.state.room?.rate)

            assertTrue(h.watch.seek(-5))
            noticed<WatchNotice.Action>(g, "the guest sees the host seek") { it.kind == "seek" && it.positionMs == 0L }
            assertEquals("0", relay.sent("seek").last()["positionMs"].toString())
            assertTrue(g.noticesOf<WatchNotice.Action>().none { it.name == "Guest" }, "not its own")
            assertTrue(g.noticesOf<WatchNotice.Refused>().isEmpty())
            assertTrue("rate:2.0" in f.screen.players.single().player.commandLog)
        }
    }

    @Test
    fun `a controller ends the media for everyone at the rooms end and the room holds there until sought back`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest
            until("the room plays") { h.state.room?.phase == Phase.PLAYING }

            assertTrue(g.watch.endMedia(), "the screen leaves its player alone")
            runFor(100)
            assertIs<WatchNotice.ControlRefused>(g.notices.last())
            assertTrue(relay.sent("seek").isEmpty())

            h.watch.setControl(Control.EVERYONE)
            until("the guest controls") { g.watch.canControl }
            g.watch.setOffset(1500)
            until("the host sees the offset") { h.participant(g.peerId).offsetMs == 1500L }

            assertTrue(g.watch.endMedia())
            until("the room is at its end") { h.state.atMediaEnd && g.state.atMediaEnd }
            assertEquals(ALIEN_MS.toString(), relay.sent("seek").single()["positionMs"].toString(), "the rooms end and not the guests own")
            assertEquals(Phase.PAUSED, h.state.room?.phase)
            noticed<WatchNotice.Action>(h, "the host is told") { it.kind == "ended" && it.name == null }

            assertTrue(g.watch.endMedia())
            runFor(100)
            assertEquals(1, relay.sent("seek").size, "a room at its end has nothing left to end")

            assertTrue(h.watch.seek(600_000))
            until("the room left its end") { !g.state.atMediaEnd }
            assertTrue(g.watch.endMedia())
            until("the room is at its end again") { h.state.atMediaEnd }
            assertTrue(g.noticesOf<WatchNotice.Refused>().isEmpty())
        }
    }

    @Test
    fun `a player that refuses to start blocks until the user presses play`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            val screen = Screen(g, this).also {
                it.refusePlay = true
                it.listen()
            }
            together(h, listOf(g))
            hostPlays(h, hostAlien)

            noticed<WatchNotice.PlayBlocked>(g, "the guest is told to press play")
            assertTrue(g.state.playBlocked)

            settle { g.watch.playBlockedPlayer() }
            assertEquals(2, g.noticesOf<WatchNotice.PlayBlocked>().size, "refused again, it stays blocked")
            assertTrue(g.state.playBlocked)

            assertEquals(Phase.PLAYING, g.state.room?.phase)
            assertFalse(g.watch.play(), "the press starts the player itself")
            assertFalse(g.state.playBlocked)
            assertFalse(screen.players.single().player.playing)
        }
    }

    @Test
    fun `an offset is the guests own and shifts its file within bounds and the room sees it`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest

            g.watch.setOffset(1500)
            until("the guest file is shifted") { g.state.party.offsetMs == 1500L }
            until("the host sees the offset") { h.participant(g.peerId).offsetMs == 1500L }

            g.watch.setOffset(WatchPartyRelays.MAX_OFFSET_MS * 2)
            until("the offset stops at 7 days") { g.state.party.offsetMs == WatchPartyRelays.MAX_OFFSET_MS }
            g.watch.setOffset(-WatchPartyRelays.MAX_OFFSET_MS * 2)
            until("and at minus 7 days") { g.state.party.offsetMs == -WatchPartyRelays.MAX_OFFSET_MS }
            assertTrue(g.noticesOf<WatchNotice.Refused>().isEmpty())
            assertEquals(0L, h.state.party.offsetMs)
        }
    }

    @Test
    fun `the host closing its player stops the media and the following guest player closes`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest

            settle { h.watch.playerClosed(f.hostPlayer.adapter, continuing = false).join() }
            assertTrue(f.hostPlayer.adapter.isReleased)
            assertEquals(1, relay.sent("clearMedia").size)
            until("the room has no media") { g.state.media == null && h.state.media == null }
            assertEquals(1, f.screen.exits)
            assertFalse(h.watch.isFollowing)
            assertTrue(g.state.inSession)
        }
    }

    @Test
    fun `a host player that hands over to the next file keeps the room media`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest

            settle { h.watch.playerClosed(f.hostPlayer.adapter, continuing = true).join() }
            val next = hostPlays(h, alien("alien-2", "host-nas", version = "remux"))

            assertTrue(relay.sent("clearMedia").isEmpty())
            assertEquals(2, relay.sent("setMedia").size)
            until("the guest searches for the next media") { guestQueries.size == 2 }
            until("the guest follows the next media") { g.watch.isFollowing }
            assertEquals(0, f.screen.exits)
            assertFalse(next.adapter.isReleased)
        }
    }

    @Test
    fun `the host sharing the same file again keeps the guest player and the room still seeks it`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest
            val guestPlayer = f.screen.players.single()

            assertTrue(settle { h.watch.shareCopy(f.hostPlayer.adapter) })
            assertEquals(2, relay.sent("setMedia").size)
            until("the guest searches for the new epoch") { guestQueries.size == 2 }
            until("the guest follows again") { g.watch.isFollowing }
            assertEquals(1, f.screen.players.size, "the open file is the match again, so nothing reopens")
            assertEquals(0, f.screen.exits)
            assertFalse(guestPlayer.adapter.isReleased)

            assertTrue(h.watch.seek(1_200_000))
            until("the room seeks the guest player") {
                guestPlayer.player.commandLog.any { it.startsWith("seek:") && it.removePrefix("seek:").toLong() >= 1_200_000 }
            }
            assertTrue(g.noticesOf<WatchNotice.Refused>().isEmpty())
        }
    }

    @Test
    fun `a guest that switches to another version of its file keeps following and the room seeks it`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest
            val remux = openPlayer(copyOf(alien("g-alien", "guest-nas", durationMs = ALIEN_MS + 800, version = "g-remux")))

            g.watch.playerOpened(remux.adapter, shareable = true, roomLaunch = false)
            until("the guest follows the other version") { g.watch.isFollowing && g.watch.roomCopy?.ref == remux.adapter.copy }
            assertFalse(g.state.canJoinPlayback)
            assertEquals(1, f.screen.players.size, "the switched file is the guest pick so nothing reopens")

            assertTrue(h.watch.seek(1_200_000))
            until("the room seeks the other version") {
                remux.player.commandLog.any { it.startsWith("seek:") && it.removePrefix("seek:").toLong() >= 1_200_000 }
            }
        }
    }

    @Test
    fun `a version the room cannot take sits out instead of holding the room`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest
            // No length anywhere and no server to read it from: the party refuses it.
            val unknown = openPlayer(copyOf(alien("g-alien", "guest-nas", durationMs = null, version = "g-remux")))

            g.watch.playerOpened(unknown.adapter, shareable = true, roomLaunch = false)
            noticed<WatchNotice.ChoiceFailed>(g, "the guest is told")
            assertFalse(g.watch.isFollowing)
            assertEquals(copyOf(guestAlien), g.watch.roomCopy?.ref, "the room keeps the guest earlier pick")
            until("the room stops waiting for the guest") { h.participant(g.peerId).player == PlayerState.IDLE }
        }
    }

    @Test
    fun `a search again that fails keeps the file playing and says the search failed`() = runTest {
        watchWorld {
            val f = following()
            val g = f.guest
            guestAnswer = { lookup(emptyList(), failed = setOf("guest-nas")) }

            g.watch.searchAgain()
            noticed<WatchNotice.SearchFailed>(g, "the guest is told")
            assertTrue(g.state.searchFailed)
            assertTrue(g.state.party.candidates.isEmpty())
            assertTrue(g.watch.isFollowing, "the open file goes on")
            assertEquals(copyOf(guestAlien), g.watch.roomCopy?.ref)
            assertFalse(f.screen.players.single().adapter.isReleased)
        }
    }

    @Test
    fun `a host that hands over keeps its own file as the room copy and not a search`() = runTest {
        watchWorld {
            val f = following()
            val h = f.host
            val g = f.guest

            h.watch.transferHost(g.peerId)
            until("the guest is host") { g.watch.isHost && !h.watch.isHost }
            assertEquals(MatchState.MATCHED, h.state.party.match?.state)
            assertEquals("", h.watch.roomCopy?.id, "the media is still this participant's own")
            assertEquals(f.hostPlayer.adapter.copy, h.watch.roomCopy?.ref)
            assertTrue(h.watch.isFollowing)
            assertFalse(h.state.canJoinPlayback)

            // Out of the player, the former host is offered its own file again.
            settle { h.watch.playerClosed(f.hostPlayer.adapter, continuing = false).join() }
            assertTrue(relay.sent("clearMedia").isEmpty(), "a guest leaving its player keeps the room media")
            runFor(100)
            assertTrue(h.state.media != null)
            assertEquals("", h.watch.roomCopy?.id)
            assertTrue(h.state.canJoinPlayback)
        }
    }

    @Test
    fun `a file the room cannot get is not shared and stops what the room played`() = runTest {
        watchWorld {
            val h = host(shareDurationWait = 300.milliseconds)
            val g = guest()
            together(h, listOf(g))
            hostPlays(h, hostAlien)
            until("the guest has the media") { g.state.media != null }

            // A download: the room keeps its media.
            val download = openPlayer(copyOf(alien("alien", "host-nas", version = "sd")))
            h.watch.playerOpened(download.adapter, shareable = false, roomLaunch = false)
            runFor(0)
            assertIs<WatchNotice.NotShared>(h.notices.last())
            assertFalse(h.watch.isFollowing)
            assertTrue(h.state.canJoinPlayback)

            // No length anywhere: the share waits for the player, then gives up.
            val unknown = openPlayer(copyOf(alien("home", "host-nas", durationMs = null, version = "raw")), durationMs = 0)
            h.watch.playerOpened(unknown.adapter, shareable = true, roomLaunch = false)
            runFor(200)
            assertTrue(h.noticesOf<WatchNotice.ShareFailed>().isEmpty(), "still waiting for the player's length")
            noticed<WatchNotice.ShareFailed>(h, "the host is told")
            until("the room media stops") { g.state.media == null && h.state.media == null }

            // A server this profile can't describe from.
            val foreign = openPlayer(copyOf(alien("alien", "usb-drive")))
            h.watch.playerOpened(foreign.adapter, shareable = true, roomLaunch = false)
            until("the host is told again") { h.noticesOf<WatchNotice.ShareFailed>().size == 2 }
            assertEquals(1, relay.sent("setMedia").size)
            assertEquals(1, relay.sent("clearMedia").size)
            assertTrue(h.noticesOf<WatchNotice.Refused>().isEmpty())
        }
    }

    @Test
    fun `a host file without a server length is shared once the player knows it`() = runTest {
        watchWorld {
            val h = host()
            settle { h.watch.createRoom() }
            val opened = openPlayer(copyOf(alien("home", "host-nas", durationMs = null, version = "raw")), durationMs = 0)
            h.watch.playerOpened(opened.adapter, shareable = true, roomLaunch = false)
            runFor(1_000)
            assertTrue(relay.sent("setMedia").isEmpty())

            opened.player.emitDuration(5_400_000)
            until("the room plays it") { h.state.media != null }
            assertEquals(5_400_000L, h.state.media?.durationMs)
        }
    }

    @Test
    fun `a file the host opened before the room is shared once the room exists`() = runTest {
        watchWorld {
            val h = host()
            val opened = openPlayer(copyOf(hostAlien))
            h.watch.playerOpened(opened.adapter, shareable = true, roomLaunch = false)

            settle { h.watch.createRoom() }

            until("the room plays the host file") { h.watch.isFollowing }
            assertEquals("Alien", h.state.media?.title)
            assertEquals(opened.adapter.copy, h.watch.roomCopy?.ref)
        }
    }

    @Test
    fun `a code whose room ended is refused and joining it with create makes the room again with the open file`() = runTest {
        watchWorld {
            val h = host()
            settle { h.watch.createRoom() }
            h.watch.endRoom()
            until("the room is over") { !h.state.inSession }
            val g = guest()
            assertEquals(PartyException.ROOM_NOT_FOUND, refusal { g.watch.joinRoom("k7m-q2x") })

            val opened = openPlayer(copyOf(hostAlien))
            h.watch.playerOpened(opened.adapter, shareable = true, roomLaunch = false)
            settle { h.watch.joinRoom("k7m-q2x", create = true) }

            assertEquals(FakeOwpRelay.CODE, h.state.roomCode)
            assertTrue(h.watch.isHost)
            assertEquals("true", relay.sent("join").last()["create"].toString())
            until("the room plays the host file") { h.watch.isFollowing }
            assertEquals("Alien", h.state.media?.title)
        }
    }

    @Test
    fun `a failed search is reported and searched again and without a player the file is offered`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            var failing = true
            guestAnswer = {
                if (failing) lookup(emptyList(), failed = setOf("guest-nas")) else lookup(listOf(guestAlien), succeeded = setOf("guest-nas"))
            }
            together(h, listOf(g))
            hostPlays(h, hostAlien)

            noticed<WatchNotice.SearchFailed>(g, "the guest is told the search failed")
            until("nothing to play") { g.state.party.match?.state == MatchState.UNAVAILABLE }
            assertNull(g.watch.roomCopy)
            assertTrue(g.state.searchFailed, "nothing found is not taken as absence")

            failing = false
            g.watch.searchAgain()
            assertFalse(g.state.searchFailed)
            until("the copy is found") { g.state.party.match?.state == MatchState.MATCHED }
            // Nothing can open the file: the guest sits out and is offered to join.
            noticed<WatchNotice.OpenFailed>(g, "the guest is told the file did not open")
            assertTrue(g.state.canJoinPlayback)
            assertFalse(g.watch.isFollowing)

            val screen = Screen(g, this)
            g.watch.navigatorOpener = screen::open
            assertTrue(settle { g.watch.openRoomCopy() })
            until("the guest follows") { g.watch.isFollowing }
            assertEquals(copyOf(guestAlien), screen.players.single().adapter.copy)
            assertFalse(g.state.canJoinPlayback)
        }
    }

    @Test
    fun `a failed search in one room is not shown for the next rooms media at the same epoch`() = runTest {
        watchWorld {
            val first = host()
            val g = guest()
            guestAnswer = { lookup(emptyList(), failed = setOf("guest-nas")) }
            together(first, listOf(g))
            hostPlays(first, hostAlien)
            noticed<WatchNotice.SearchFailed>(g, "the guest is told the search failed")
            assertTrue(g.state.searchFailed)
            g.watch.leave()
            first.watch.leave()
            until("the room is over") { !g.state.inSession && !first.state.inSession }

            val second = host()
            guestAnswer = { lookup(emptyList(), succeeded = setOf("guest-nas")) }
            together(second, listOf(g))
            hostPlays(second, hostAlien)
            until("nothing to play") { g.state.party.match?.state == MatchState.UNAVAILABLE }
            assertFalse(g.state.searchFailed, "this room's search found nothing; it did not fail")
        }
    }

    @Test
    fun `only joining a room or being in one or reconnecting to it is a session and nothing of the room shows outside it`() = runTest {
        watchWorld {
            val before = guest("Before").state
            assertFalse(before.inSession)
            assertNull(before.roomCopy)
            assertFalse(before.locked)

            val f = following()
            val g = f.guest
            f.host.watch.setLocked(true)
            f.host.watch.setControl(Control.EVERYONE)
            until("the guest sees the lock and control") { g.state.locked && g.state.control == Control.EVERYONE }
            val live = g.state
            for (connection in listOf(Connection.CONNECTING, Connection.CONNECTED, Connection.RECONNECTING)) {
                val s = live.copy(party = live.party.copy(connection = connection))
                assertTrue(s.inSession, "$connection")
                assertNotNull(s.room, "$connection")
                assertNotNull(s.media, "$connection")
                assertNotNull(s.roomCopy, "$connection")
            }
            for (connection in listOf(Connection.IDLE, Connection.ENDED)) {
                val s = live.copy(party = live.party.copy(connection = connection))
                assertFalse(s.inSession, "$connection")
                assertNull(s.room, "$connection")
                assertNull(s.media, "$connection")
                assertNull(s.roomCopy, "$connection")
                assertEquals(Control.HOST, s.control, "$connection")
                assertFalse(s.locked, "$connection")
            }

            g.watch.leave()
            until("the guest is out") { !g.state.inSession }
            assertNull(g.state.room)
            assertNull(g.state.media)
            assertNull(g.watch.roomCopy)
            assertEquals(Control.HOST, g.state.control)
            assertFalse(g.state.locked)
        }
    }

    @Test
    fun `a copy chosen from anywhere becomes the room copy and one without a server or a length or for older media is refused`() = runTest {
        watchWorld {
            val probe = CompletableDeferred<MediaItem?>()
            val guestServer = FakeMediaBackend("guest-nas").apply {
                items = { id -> if (id == "g-alien-asked") alien(id, "guest-nas") else probe.await() }
            }
            val h = host()
            val g = member("Guest", clientFor = { if (it == "guest-nas") guestServer else null }, findCopies = { lookup(listOf(guestAlien), succeeded = setOf("guest-nas")) })
            Screen(g, this).listen()
            together(h, listOf(g))
            val hostPlayer = hostPlays(h, hostAlien)
            until("the guest follows the room") { g.watch.isFollowing }

            val uhd = alien("g-alien-uhd", "guest-nas", version = "uhd")
            assertFalse(settle { g.watch.chooseCopy(uhd.copy(serverId = null), uhd.mediaVersions!!.first()) }, "no server")
            assertFalse(settle { g.watch.chooseCopy(alien("g-alien-nolen", "other-nas", durationMs = null), null) }, "no length")
            assertEquals(copyOf(guestAlien), g.watch.roomCopy?.ref)
            assertEquals(0, g.state.chosen)

            assertTrue(settle { g.watch.chooseCopy(uhd, uhd.mediaVersions!!.first()) })
            assertEquals(copyOf(uhd), g.watch.roomCopy?.ref)
            assertEquals(ALIEN_MS, g.watch.roomCopy?.durationMs)
            assertEquals(1, g.state.chosen)

            // A copy without a length takes the one its server answers.
            assertTrue(settle { g.watch.chooseCopy(alien("g-alien-asked", "guest-nas", durationMs = null), null) })
            assertEquals(2, g.state.chosen)

            // A copy whose length is still being asked of its server while the room's media changes.
            val pending = test.backgroundScope.async { g.watch.chooseCopy(alien("g-alien-probe", "guest-nas", durationMs = null), null) }
            runFor(100)
            settle { h.watch.playerClosed(hostPlayer.adapter, continuing = false).join() }
            until("the room has no media") { g.state.media == null }
            probe.complete(alien("g-alien-probe", "guest-nas"))
            until("the choice settled") { pending.isCompleted }
            assertFalse(pending.getCompleted(), "the media changed")
            assertEquals(2, g.state.chosen)
        }
    }

    @Test
    fun `the newest player screen gets the room switch and close and only its own owner takes its hooks away`() = runTest {
        watchWorld {
            val h = host()
            val g = guest()
            val older = Screen(g, this)
            val newer = Screen(g, this)
            var navigatorOpens = 0
            g.watch.navigatorOpener = {
                navigatorOpens++
                false
            }
            g.watch.registerPlayer(older, WatchPlayerHooks(older::open) { older.exits++ })
            g.watch.registerPlayer(newer, WatchPlayerHooks(newer::open) { newer.exits++ })
            g.watch.unregisterPlayer(older)

            together(h, listOf(g))
            val hostPlayer = hostPlays(h, hostAlien)
            until("the guest follows the room") { g.watch.isFollowing }
            assertEquals(1, newer.players.size)
            assertTrue(older.players.isEmpty())
            assertEquals(0, navigatorOpens)

            settle { h.watch.playerClosed(hostPlayer.adapter, continuing = false).join() }
            until("the room has no media") { g.state.media == null }
            assertEquals(1, newer.exits)
            assertEquals(0, older.exits)

            settle { g.watch.playerClosed(newer.players.single().adapter, continuing = false).join() }
            g.watch.unregisterPlayer(newer)
            hostPlays(h, hostAlien)
            until("the room opens through the navigator") { navigatorOpens == 1 }
            assertEquals(1, newer.players.size)
        }
    }
}
