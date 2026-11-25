package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.model.MediaKind
import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.ALIEN_MS
import com.edde746.plezy.watch.FakeOwpRelay
import com.edde746.plezy.watch.Member
import com.edde746.plezy.watch.Screen
import com.edde746.plezy.watch.WatchCopy
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchPartyRelays
import com.edde746.plezy.watch.WatchSnapshot
import com.edde746.plezy.watch.WatchWorld
import com.edde746.plezy.watch.alien
import com.edde746.plezy.watch.copyOf
import com.edde746.plezy.watch.guestAlien
import com.edde746.plezy.watch.hostAlien
import com.edde746.plezy.watch.lookup
import com.edde746.plezy.watch.watchWorld
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import party.openwatch.Candidate
import party.openwatch.Connection
import party.openwatch.Control
import party.openwatch.EndReason
import party.openwatch.Match
import party.openwatch.MatchState
import party.openwatch.Media
import party.openwatch.Mismatch
import party.openwatch.Participant
import party.openwatch.PartyState
import party.openwatch.Phase
import party.openwatch.PlayerState
import party.openwatch.Ranked
import party.openwatch.Room
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The Watch Together screen's store: the lobby, recent rooms, the join dialog and the room, against a relay. */
class WatchTogetherStoreTest {
    private val text = T.watchTogether

    private fun WatchWorld.store(member: Member) = WatchTogetherStore(member.watch, test.backgroundScope)

    private val WatchTogetherStore.lobby: WatchLobbyUi
        get() = assertIs<WatchScreenContent.Lobby>(state.value.content).lobby

    private val WatchTogetherStore.room: WatchRoomUi
        get() = assertIs<WatchScreenContent.Room>(state.value.content).room

    private val WatchTogetherStore.join: JoinRoomUi
        get() = assertNotNull(state.value.join)

    private fun WatchRoomUi.row(name: String): ParticipantUi = participants.single { it.name == name }

    private fun WatchWorld.recent(profile: String, relayScope: String = WatchPartyRelays.relayScopeOf(null)) =
        settle { recentRooms.observe(profile, relayScope).first() }

    // Out of a room

    @Test
    fun `Create Room makes the user host of a new room shown by its K7M Q2X code`() = runTest {
        watchWorld {
            val host = host(profileScope = "p1")
            val store = store(host)
            assertEquals(text.relayPublic, store.lobby.relay)
            assertEquals(text.createRoom, store.lobby.create)

            store.create()
            until("the room exists") { host.watch.isConnected }

            assertEquals(1, relay.sent("create").size)
            val room = store.room
            assertEquals("K7M-Q2X", room.header.code)
            assertEquals(text.youAreHost, room.header.role)
            assertEquals(text.hostBadge, room.row(text.nameYou("Host")).hostBadge)
            assertEquals(text.roomSettings, room.settings?.title)
            assertEquals(text.nothingPlayingHost, room.media.idleDetail)
            assertNull(room.media.title)
            assertEquals(text.endRoom, room.end?.label)
            assertEquals(listOf(FakeOwpRelay.CODE), recent("p1").map { it.code })
        }
    }

    @Test
    fun `a create the relay refuses says why in the lobby and Create Room works again`() = runTest {
        watchWorld {
            val other = member("Cleo")
            settle { other.watch.createRoom() }
            val host = host()
            val store = store(host)

            store.create()
            until("the lobby says why") { (store.state.value.content as? WatchScreenContent.Lobby)?.lobby?.error == text.errors.rateLimited }
            assertFalse(host.state.inSession)
            assertFalse(store.lobby.busy, "Create Room and Join Room work again")
            assertFalse(store.lobby.creating)

            other.watch.leave()
            until("the other room is gone") { relay.peerIds.isEmpty() }
            store.create()
            until("the room exists") { host.watch.isConnected }
            assertEquals("K7M-Q2X", store.room.header.code)
            host.watch.leave()
            until("the lobby is back") { store.state.value.content is WatchScreenContent.Lobby }
            assertNull(store.lobby.error)
        }
    }

    @Test
    fun `the lobby error goes when the join dialog opens and when another attempt starts`() = runTest {
        watchWorld {
            val other = member("Cleo")
            settle { other.watch.createRoom() }
            val host = host()
            val store = store(host)
            fun refusedCreate() {
                store.create()
                until("the lobby says why") { (store.state.value.content as? WatchScreenContent.Lobby)?.lobby?.error == text.errors.rateLimited }
            }

            refusedCreate()
            store.openJoin()
            assertNull(store.lobby.error, "the join dialog opens on a clear lobby")
            store.closeJoin()
            assertNull(store.lobby.error)

            refusedCreate()
            relay.holdJoins = true
            store.joinRecent(FakeOwpRelay.CODE)
            assertTrue(store.lobby.busy, "the recent join runs")
            assertNull(store.lobby.error, "and the old error went with its start")
        }
    }

    @Test
    fun `Join Room asks for the code and shows the room once joined`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val guest = guest()
            val store = store(guest)

            assertNull(store.state.value.join)
            store.openJoin()
            assertEquals(text.joinRoom, store.join.title)
            store.editJoin("k7mq2x")
            store.submitJoin()
            until("the guest is in") { guest.watch.isConnected && store.state.value.join == null }

            assertEquals("K7M-Q2X", store.room.header.code)
            assertEquals(text.hostedBy("Host"), store.room.header.role)
        }
    }

    @Test
    fun `recent rooms of this relay are listed and a tile joins its room or makes it again or says why it cannot`() = runTest {
        watchWorld {
            val public = WatchPartyRelays.relayScopeOf(null)
            settle {
                recentRooms.remember("p1", "ABC234", public)
                recentRooms.rename("p1", "ABC234", public, "Movie night")
                recentRooms.remember("p1", FakeOwpRelay.CODE, public)
                recentRooms.remember("p1", "XYZ789", WatchPartyRelays.relayScopeOf("https://r.test"))
            }
            val host = host()
            settle { host.watch.createRoom() }
            val guest = guest(profileScope = "p1")
            val store = store(guest)
            until("the rooms are listed") { store.lobby.recentRooms.size == 2 }

            val lobby = store.lobby
            assertEquals(text.recentRooms, lobby.recentTitle)
            assertEquals(listOf("K7M-Q2X", "Movie night"), lobby.recentRooms.map { it.title })
            assertEquals(listOf(null, "ABC-234"), lobby.recentRooms.map { it.subtitle }, "a named room shows its code under the name")

            store.joinRecent(FakeOwpRelay.CODE)
            until("the guest is in") { guest.watch.isConnected }
            assertEquals(text.hostedBy("Host"), store.room.header.role)
            assertFalse(guest.watch.isHost, "the room exists, so the tile joins it")

            host.watch.endRoom()
            until("the room is over") { !guest.state.inSession }
            store.joinRecent("ABC234")
            until("the room is made again") { guest.watch.isConnected }
            assertEquals("ABC234", guest.state.roomCode)
            assertTrue(guest.watch.isHost)
            assertEquals("true", relay.sent("join").last()["create"].toString())

            guest.watch.leave()
            until("the guest left") { !guest.state.inSession }
            relay.refuseJoins = "relay_full"
            store.joinRecent(FakeOwpRelay.CODE)
            until("the lobby says why") { (store.state.value.content as? WatchScreenContent.Lobby)?.lobby?.error == text.errors.relayFull }
            assertFalse(guest.state.inSession)
        }
    }

    @Test
    fun `a recent room is renamed and unnamed and removed from its actions`() = runTest {
        watchWorld {
            settle { recentRooms.remember("p1", FakeOwpRelay.CODE, WatchPartyRelays.relayScopeOf(null)) }
            val guest = guest(profileScope = "p1")
            val store = store(guest)
            until("the room is listed") { store.lobby.recentRooms.isNotEmpty() }
            assertEquals(text.roomActions, store.lobby.recentActions.menuLabel)
            assertEquals("K7M-Q2X", store.lobby.recentRooms.single().hint)

            store.renameRecent(FakeOwpRelay.CODE, "  Friday  ")
            until("the name shows") { store.lobby.recentRooms.single().title == "Friday" }
            assertEquals("K7M-Q2X", store.lobby.recentRooms.single().subtitle, "the code under the name")
            assertEquals("Friday", store.lobby.recentRooms.single().name, "the rename field starts from it")
            assertEquals("Friday", recent("p1").single().name)

            store.renameRecent(FakeOwpRelay.CODE, " ")
            until("the name goes") { store.lobby.recentRooms.single().title == "K7M-Q2X" }
            assertNull(store.lobby.recentRooms.single().subtitle)
            assertNull(recent("p1").single().name)

            store.removeRecent(FakeOwpRelay.CODE)
            until("the room goes") { store.lobby.recentRooms.isEmpty() }
            assertTrue(recent("p1").isEmpty())
        }
    }

    @Test
    fun `the lobby names the relay rooms use and lists only that relays rooms`() = runTest {
        watchWorld {
            settle { recentRooms.remember("p1", FakeOwpRelay.CODE, WatchPartyRelays.relayScopeOf(null)) }
            val store = store(guest(profileScope = "p1"))
            until("the room is listed") { store.lobby.recentRooms.isNotEmpty() }
            assertEquals(text.relayPublic, store.lobby.relay)

            relayBaseUrl.value = "https://relay.example.com"
            val custom = store(member("Ben", profileScope = "p1"))
            until("the relay is named") { custom.lobby.relay == text.relayCustom("https://relay.example.com") }
            test.testScheduler.runCurrent()
            assertTrue(custom.lobby.recentRooms.isEmpty(), "that code belongs to the public relays")
        }
    }

    // In a room

    @Test
    fun `the room header gives the formatted code to copy and the invite to share`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val header = store(host).room.header
            assertEquals("K7M-Q2X", header.code)
            assertEquals(text.codeCopied, header.copied)
            assertEquals(text.inviteMessage("K7M-Q2X"), header.invite)
            assertEquals(text.inviteCopied, header.invited)
        }
    }

    @Test
    fun `participants show who hosts and who is you and each ones app connection player and match`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            Screen(guest, this).listen()
            together(host, listOf(guest))
            val store = store(host)

            assertEquals(text.hostBadge, store.room.row(text.nameYou("Host")).hostBadge)
            assertNull(store.room.row("Ben").hostBadge)
            val idle = listOf("Plezy", text.connected, WatchLabels.playerStateText(PlayerState.IDLE)).joinToString(" · ")
            assertEquals(idle, store.room.row("Ben").details)

            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing }
            until("the host sees the match") { host.participant(guest.peerId).match?.state == MatchState.MATCHED }
            assertTrue(WatchLabels.matchStateText(MatchState.MATCHED) in store.room.row("Ben").details)
        }
    }

    @Test
    fun `host settings for who controls playback and the lock reach the room`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest()
            together(host, listOf(guest))
            val store = store(host)
            val guestStore = store(guest)
            assertFalse(store.room.settings!!.everyone.checked)
            // The host's setting says who controls playback; the header says it to a guest only.
            assertNull(store.room.header.control)
            assertEquals(text.hostControlsPlayback, store.room.settings!!.everyone.detail)
            until("the guest's header says it") { guestStore.room.header.control == text.hostControlsPlayback }

            store.execute(WatchCommand.SetEveryoneControls(true))
            until("the guest controls playback") { guest.watch.canControl }
            until("the switch is on") { store.room.settings!!.everyone.checked }
            assertNull(store.room.header.control)
            assertEquals(text.anyoneCanControl, store.room.settings!!.everyone.detail)
            until("the guest's header follows") { guestStore.room.header.control == text.anyoneCanControl }

            store.execute(WatchCommand.Lock(true))
            until("the guest sees the lock") { guest.state.locked }
            until("the lock shows") { store.room.settings!!.lock.checked }
            assertEquals(text.roomLocked, store.room.header.locked)

            store.execute(WatchCommand.Lock(false))
            until("the guest sees the unlock") { !guest.state.locked }
            until("the lock goes") { store.room.header.locked == null }
        }
    }

    @Test
    fun `Make host asks first and then hands the room over`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            together(host, listOf(guest))
            val store = store(host)

            val actions = assertNotNull(store.room.row("Ben").actions)
            assertEquals("Ben", actions.title)
            assertEquals(WatchConfirmUi(text.makeHost, text.makeHostQuestion, text.makeHostConfirm("Ben"), text.transfer, T.common.cancel, false), actions.makeHost)
            assertTrue(relay.sent("transferHost").isEmpty())

            store.execute(WatchCommand.MakeHost(guest.peerId))
            until("Ben hosts") { guest.watch.isHost && !host.watch.isHost }
            until("the room shows it") { !store.room.isHost }
            val room = store.room
            assertEquals(text.hostedBy("Ben"), room.header.role)
            assertEquals(text.hostBadge, room.row("Ben").hostBadge)
            assertNull(room.settings)
            assertNull(room.end)
            assertTrue(room.participants.all { it.actions == null }, "the actions closed")
        }
    }

    @Test
    fun `Remove asks first and the row goes once the relay drops the guest`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            together(host, listOf(guest))
            val store = store(host)

            val remove = store.room.row("Ben").actions!!.remove
            assertEquals(text.removeParticipantQuestion("Ben"), remove.question)
            assertEquals(text.remove, remove.confirm)
            assertTrue(remove.destructive)

            store.execute(WatchCommand.Kick(guest.peerId))
            until("the relay dropped the guest") { host.watch.participants.size == 1 }
            until("the row goes") { store.room.participants.none { it.name == "Ben" } }
            assertEquals(EndReason.KICKED, guest.state.party.endReason)
            assertTrue(host.watch.isConnected)
        }
    }

    @Test
    fun `Leave asks first and leaving shows the lobby and the others see the user go`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest()
            together(host, listOf(guest))
            val store = store(guest)

            assertEquals(
                WatchConfirmUi(text.leaveRoom, text.leaveRoomQuestion, text.leaveRoomConfirm, text.leave, T.common.cancel, destructive = false),
                store.room.leave,
            )
            store.execute(WatchCommand.Leave)
            until("the guest is out") { !guest.state.inSession }
            until("the host sees the guest go") { host.watch.participants.size == 1 }
            assertEquals(EndReason.LEFT, guest.state.party.endReason)
            until("the lobby is back") { store.state.value.content is WatchScreenContent.Lobby }
            assertEquals(text.createRoom, store.lobby.create)
        }
    }

    @Test
    fun `End asks first and ends the room for everyone`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest()
            together(host, listOf(guest))
            val store = store(host)

            val end = assertNotNull(store.room.end)
            assertEquals(text.endRoomQuestion, end.question)
            assertTrue(end.destructive)
            assertTrue(relay.sent("end").isEmpty())

            store.execute(WatchCommand.End)
            until("the room is over") { !host.state.inSession && !guest.state.inSession }
            assertEquals(EndReason.ENDED, guest.state.party.endReason)
            until("the lobby is back") { store.state.value.content is WatchScreenContent.Lobby }
        }
    }

    @Test
    fun `a guest sees who hosts but no host settings or End Room or participant actions`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest()
            together(host, listOf(guest))
            val room = store(guest).room

            assertEquals(text.hostedBy("Host"), room.header.role)
            assertEquals(text.nothingPlayingGuest, room.media.idleDetail)
            assertEquals(text.hostBadge, room.row("Host").hostBadge)
            assertNull(room.settings)
            assertNull(room.end)
            assertEquals(text.leaveRoom, room.leave.label)
            assertTrue(room.participants.all { it.actions == null })
        }
    }

    @Test
    fun `the reconnecting banner shows while the connection is down and a host sees the dropped guest as disconnected`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            together(host, listOf(guest))
            val guestStore = store(guest)
            val hostStore = store(host)
            assertNull(guestStore.room.reconnecting)

            relay.drop(guest.peerId)
            until("the guest reconnects") { guest.state.reconnecting }
            assertEquals(WatchBannerUi(text.reconnecting, text.reconnectingDescription), guestStore.room.reconnecting)
            assertEquals("K7M-Q2X", guestStore.room.header.code, "the room stays on screen")
            until("the host sees the drop") { !host.participant(guest.peerId).connected }
            assertEquals(listOf("Plezy", text.disconnected).joinToString(" · "), hostStore.room.row("Ben").details)
        }
    }

    @Test
    fun `a video without catalogue identity is marked as not shareable and a movie is not`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val store = store(host)

            hostPlays(host, hostAlien)
            until("the room shows it") { store.room.media.title != null }
            assertEquals("Alien (1979)", store.room.media.title)
            assertIs<WatchMatchUi.Sharing>(store.room.media.match)
            assertEquals(text.sharingYourCopy, store.room.media.summary)
            assertNull(store.room.media.notShareable)
            assertEquals(text.stopMedia, store.room.media.stop)

            hostPlays(host, alien("home", "host-nas").copy(title = "Birthday", year = null, kind = MediaKind.CLIP))
            until("the room shows it") { store.room.media.title == "Birthday" }
            assertEquals(party.openwatch.MediaKind.VIDEO, host.state.media?.kind)
            assertEquals(text.notShareable, store.room.media.notShareable)
        }
    }

    @Test
    fun `Join Current Playback opens the room file for a guest who is not watching it`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest()
            val screen = Screen(guest, this)
            val opened = mutableListOf<WatchCopy>()
            // The room's own open fails (the player could not start); the card then opens it on request.
            guest.watch.navigatorOpener = { copy ->
                opened += copy
                opened.size > 1 && screen.open(copy)
            }
            together(host, listOf(guest))
            val store = store(guest)

            hostPlays(host, hostAlien)
            until("the guest may join") { guest.state.canJoinPlayback }
            assertEquals(listOf(copyOf(guestAlien)), opened)
            assertEquals(WatchActionUi(text.joinCurrentPlayback, text.joinCurrentPlaybackDescription), store.room.media.joinPlayback)

            store.execute(WatchCommand.JoinPlayback)
            until("the guest follows") { guest.watch.isFollowing }
            assertEquals(listOf(copyOf(guestAlien), copyOf(guestAlien)), opened)
            until("the card goes") { store.room.media.joinPlayback == null }
        }
    }

    @Test
    fun `a search that failed on a server says so on the room and on the copies page until searched again`() = runTest {
        watchWorld {
            var failing = true
            guestAnswer = { if (failing) lookup(emptyList(), failed = setOf("guest-nas")) else lookup(listOf(guestAlien), succeeded = setOf("guest-nas")) }
            val host = host()
            val guest = guest("Ben")
            guest.watch.navigatorOpener = { false }
            together(host, listOf(guest))
            val store = store(guest)

            hostPlays(host, hostAlien)
            until("the search failed") { guest.state.searchFailed && store.room.media.match is WatchMatchUi.Unavailable }
            val unavailable = assertIs<WatchMatchUi.Unavailable>(store.room.media.match)
            assertEquals(text.notices.searchFailed, unavailable.title, "not found is not the same as absent")
            assertEquals(text.notices.searchFailed, store.room.media.copies.empty)

            failing = false
            store.execute(WatchCommand.SearchAgain)
            until("the copy is found") { guest.state.party.candidates.isNotEmpty() }
            assertFalse(guest.state.searchFailed)
            until("the room says so") { store.room.media.copies.rows.isNotEmpty() }
            assertNull(store.room.media.copies.empty)
        }
    }

    // The join dialog

    @Test
    fun `a typed code shows as K7M Q2X in upper case with separators dropped and six symbols at most`() = runTest {
        watchWorld {
            val store = store(guest())
            store.openJoin()
            fun typed(value: String): String {
                store.editJoin(value)
                return store.join.text
            }

            assertEquals("K", typed("k"))
            assertEquals("K7M", typed("k7m"))
            assertEquals("K7M-Q", typed("k7mq"))
            assertEquals("K7M-Q2X", typed("k7m q2x"))
            assertEquals("K7M-Q2X", typed("k7m\u2013q2x"), "a dash is a separator")
            assertEquals("K7M-Q2X", typed("K7M-Q2XYZ"))
            assertEquals(7, store.join.caret)

            // A symbol typed in the middle keeps the caret after it.
            store.editJoin("K7xM-Q2", caret = 3)
            assertEquals("K7X-MQ2", store.join.text)
            assertEquals(3, store.join.caret)
        }
    }

    @Test
    fun `a code that cannot be one is refused inline without asking the relay`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val guest = guest()
            val store = store(guest)
            store.openJoin()

            store.editJoin("K7M-Q0X")
            store.submitJoin()
            assertEquals(text.errors.invalidCode, store.join.error)

            store.editJoin("K7M-Q2")
            assertNull(store.join.error, "editing clears the error")
            store.submitJoin()
            assertEquals(text.errors.invalidCode, store.join.error)

            runFor(100)
            assertTrue(relay.sent("join").isEmpty())
            assertFalse(guest.state.inSession)
            assertNotNull(store.state.value.join)
        }
    }

    @Test
    fun `the relay refusals show inline each with its own text and the dialog stays for another try`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val guest = guest()
            val store = store(guest)
            store.openJoin()

            fun refused(code: String, expected: String) {
                store.editJoin(code)
                store.submitJoin()
                assertTrue(store.join.joining)
                assertEquals(text.joiningRoom, store.join.join)
                until("the dialog says $expected") { store.state.value.join?.error == expected }
                assertFalse(store.join.joining)
                assertEquals(code.uppercase(), store.join.text, "the code stays for another try")
                assertFalse(guest.state.inSession)
            }

            // The relay holds one room, K7M-Q2X.
            refused("abc-def", text.errors.roomNotFound)

            host.watch.setLocked(true)
            until("the room is locked") { host.state.locked }
            refused("k7m-q2x", text.errors.roomLocked)

            relay.refuseJoins = "room_full"
            refused("K7M-Q2X", text.errors.roomFull)
            relay.refuseJoins = "no_such_code"
            refused("K7M-Q2X", text.errors.generic)

            relay.refuseJoins = null
            host.watch.setLocked(false)
            until("the room is open") { !host.state.locked }
            store.submitJoin()
            until("the guest is in") { guest.watch.isConnected && store.state.value.join == null }
        }
    }

    @Test
    fun `closing the dialog while the relay is still answering cancels the join`() = runTest {
        watchWorld {
            val host = host()
            settle { host.watch.createRoom() }
            val guest = guest()
            val store = store(guest)
            store.openJoin()
            relay.holdJoins = true

            store.editJoin("K7M-Q2X")
            store.submitJoin()
            until("the join reached the relay") { relay.sent("join").isNotEmpty() }
            assertEquals(text.joiningRoom, store.join.join)
            store.closeJoin()
            assertNull(store.state.value.join)

            relay.releaseJoins()
            runFor(1_000)
            assertFalse(guest.state.inSession, "the user backed out of the join")
            assertEquals(1, host.watch.participants.size)
        }
    }

    @Test
    fun `closing the dialog without a join leaves the lobby as it was`() = runTest {
        watchWorld {
            val guest = guest()
            val store = store(guest)
            store.openJoin()
            store.closeJoin()
            assertNull(store.state.value.join)
            assertIs<WatchScreenContent.Lobby>(store.state.value.content)
            assertFalse(guest.state.inSession)
        }
    }

    @Test
    fun `a copy the room cannot take says so and the copies page stays`() = runTest {
        watchWorld {
            val noLength = alien("g-0", "guest-nas", durationMs = null, version = "g-0")
            guestAnswer = { lookup(listOf(longer, noLength), succeeded = setOf("guest-nas")) }
            val host = host()
            val guest = guest("Ben")
            together(host, listOf(guest))
            val store = store(guest)
            val messages = mutableListOf<String>()
            test.backgroundScope.launch { store.messages.collect { messages += it } }

            hostPlays(host, hostAlien)
            until("the copies are listed") { store.room.media.copies.rows.size == 2 }
            val copies = store.room.media.copies
            store.execute(WatchCommand.ChooseCopy(copies.rows.single { it.id.contains("g-0") }.id))
            until("the user is told") { messages.isNotEmpty() }
            assertEquals(listOf(text.choiceFailed), messages)
            assertEquals("Couldn't play this copy for the room", text.choiceFailed)
            assertEquals(copies.chosen, store.room.media.copies.chosen, "the page stays open")
        }
    }

    @Test
    fun `changes made in one turn reach the screen as one state`() = runTest {
        watchWorld {
            val store = store(guest())
            val seen = mutableListOf<WatchTogetherUiState>()
            test.backgroundScope.launch { store.state.collect { seen += it } }
            runFor(0)
            seen.clear()

            store.openJoin()
            store.editJoin("k7m")
            store.editJoin("k7mq2x")
            runFor(0)
            assertEquals(listOf("K7M-Q2X"), seen.map { it.join?.text })
        }
    }

    // The match section, from the party's state

    private val me = Participant("p2", "Ben", "Plezy/1.0", host = false, connected = true, player = PlayerState.IDLE, match = null, offsetMs = 0)
    private val longer = alien("g-5", "guest-nas", durationMs = ALIEN_MS + 300_000, version = "g-5")
    private val longest = alien("g-10", "guest-nas", durationMs = ALIEN_MS + 600_000, version = "g-10")

    private fun candidate(item: MediaItem, id: String = item.id) = Candidate(id = id, ref = copyOf(item), durationMs = item.durationMs)

    private fun room(
        match: Match? = null,
        choice: Candidate<WatchCopy>? = null,
        mismatch: Mismatch<WatchCopy>? = null,
        candidates: List<Ranked<WatchCopy>> = emptyList(),
        searchFailed: Boolean = false,
        media: Boolean = true,
    ): WatchRoomUi = WatchRoomText.room(
        WatchSnapshot(
            party = PartyState(
                connection = Connection.CONNECTED,
                peerId = me.peerId,
                room = Room(1, "K7MQ2X", 3, Phase.PAUSED, 0, 0, 1.0, Control.HOST, false, emptyList(), listOf(me)),
                media = if (media) Media(party.openwatch.MediaKind.MOVIE, "Alien", ALIEN_MS, year = 1979) else null,
                match = match,
                choice = choice,
                mismatch = mismatch,
                candidates = candidates,
            ),
            searchFailed = searchFailed,
        ),
    )

    private fun copyUi(item: MediaItem, label: String? = null) = WatchCopyUi(label, WatchLabels.copyTitle(copyOf(item)), WatchLabels.copyDetails(copyOf(item)))

    @Test
    fun `the match section and its summary follow the party from searching to the copy this user plays`() {
        room(media = false).media.let {
            assertNull(it.match)
            assertNull(it.summary, "no media, no summary")
        }
        for (searching in listOf(null, Match(MatchState.SEARCHING))) {
            val media = room(match = searching).media
            assertEquals(WatchMatchUi.Searching("Looking for this video in your libraries…"), media.match)
            assertEquals(text.searching, media.summary)
        }

        val own = room(match = Match(MatchState.MATCHED, 0), choice = candidate(hostAlien, id = "")).media
        assertEquals(WatchMatchUi.Sharing(copyUi(hostAlien, "You're sharing your copy")), own.match)
        assertEquals(text.sharingYourCopy, own.summary)

        val matched = candidate(guestAlien)
        val one = room(match = Match(MatchState.MATCHED, 800), choice = matched, candidates = listOf(Ranked(matched, 800L))).media
        assertEquals(WatchMatchUi.Playing("Your copy", copyUi(guestAlien), chooseAnother = null), one.match)
        assertEquals(WatchLabels.copyTitle(copyOf(guestAlien)), one.summary, "the copy's title")
        val two = room(match = Match(MatchState.MATCHED, 800), choice = matched, candidates = listOf(Ranked(matched, 800L), Ranked(candidate(longer), 300_000L)))
        assertEquals("Choose Another Copy", assertIs<WatchMatchUi.Playing>(two.media.match).chooseAnother, "more than one copy")
        assertEquals(text.yourCopy, room(match = Match(MatchState.MATCHED, 0)).media.summary, "a match without a known copy")

        val accepted = room(match = Match(MatchState.MISMATCHED, 300_000), choice = candidate(longer)).media
        assertEquals("Playing your copy, 5m longer", assertIs<WatchMatchUi.Playing>(accepted.match).label)
        assertEquals("Playing your copy, 5m longer", accepted.summary)
    }

    @Test
    fun `a pending mismatch shows the different length block with the offered copy and its three answers`() {
        val media = room(match = Match(MatchState.SEARCHING), mismatch = Mismatch(candidate(longer), 300_000)).media
        assertEquals(
            WatchMatchUi.Mismatch(
                WatchMismatchUi(
                    key = "3|g-5",
                    title = "Your Copy Is a Different Length",
                    description = "Your closest copy is 5m longer than the room's video. It may be another cut or version.",
                    copy = copyUi(longer),
                    playAnyway = "Play Anyway",
                    chooseAnother = "Choose Another Copy",
                    dontPlay = "Don't Play",
                ),
            ),
            media.match,
        )
        assertEquals("Your Copy Is a Different Length", media.summary)
    }

    @Test
    fun `a video this user does not have offers to choose a copy or search again`() {
        val media = room(match = Match(MatchState.UNAVAILABLE)).media
        assertEquals(
            WatchMatchUi.Unavailable(
                title = "You don't have this video",
                description = "Plezy couldn't find it in your libraries. Pick a copy yourself or search again.",
                choose = "Choose a Copy",
                searchAgain = "Search Again",
            ),
            media.match,
        )
        assertEquals("You don't have this video", media.summary)
        assertEquals("Some servers couldn't be searched for the room's video", room(match = Match(MatchState.UNAVAILABLE), searchFailed = true).media.summary)
    }

    @Test
    fun `the copies page checks the current copy and says when there are none or a search runs`() {
        val searching = room(match = Match(MatchState.SEARCHING)).media.copies
        assertEquals("Choose a Copy", searching.title)
        assertTrue(searching.rows.isEmpty())
        assertNull(searching.empty, "no empty text while searching")
        assertEquals(text.searching, searching.searching)
        assertFalse(searching.searchAgainEnabled)

        val none = room(match = Match(MatchState.UNAVAILABLE)).media.copies
        assertEquals("No copies found in your libraries.", none.empty)
        assertNull(none.searching)
        assertTrue(none.searchAgainEnabled)

        val chosen = candidate(longest)
        val rows = room(
            match = Match(MatchState.MISMATCHED, 600_000),
            choice = chosen,
            candidates = listOf(Ranked(candidate(longer), 300_000L), Ranked(chosen, 600_000L)),
        ).media.copies.rows
        assertEquals(listOf("g-5", "g-10"), rows.map { it.id })
        assertEquals(listOf(false, true), rows.map { it.current })
        assertEquals("${WatchLabels.copyDetails(copyOf(longer))} · 5m longer", rows[0].subtitle)
    }
}
