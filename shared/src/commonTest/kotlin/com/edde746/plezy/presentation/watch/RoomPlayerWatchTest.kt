package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.model.MediaItem
import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.ALIEN_MS
import com.edde746.plezy.watch.FakeRoomPlayer
import com.edde746.plezy.watch.Member
import com.edde746.plezy.watch.WatchAway
import com.edde746.plezy.watch.WatchCopy
import com.edde746.plezy.watch.WatchFileStart
import com.edde746.plezy.watch.WatchLabels
import com.edde746.plezy.watch.WatchWorld
import com.edde746.plezy.watch.alien
import com.edde746.plezy.watch.copyOf
import com.edde746.plezy.watch.hostAlien
import com.edde746.plezy.watch.lookup
import com.edde746.plezy.watch.watchWorld
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import party.openwatch.Control
import party.openwatch.EndReason
import party.openwatch.Match
import party.openwatch.MatchState
import party.openwatch.Phase
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Watch Together in the player ([RoomPlayerWatch]): the room pill, the session sheet and its pages, the prompts over
 * the video and the notices, for a player the room opens its files in.
 */
class RoomPlayerWatchTest {
    private val text = T.watchTogether

    /** A player screen bound to the room as the app binds it: the room opens its files in it. */
    private class PlayerSide(world: WatchWorld, val member: Member, roomLaunch: Boolean = true) {
        val player = FakeRoomPlayer(renderedFrame = true)
        val opened = MutableStateFlow<WatchOpen?>(null)
        val restricted = MutableStateFlow(false)
        val profileHeld = MutableStateFlow(false)
        val negotiating = MutableStateFlow(false)
        val background = MutableStateFlow(false)
        val failure = MutableStateFlow(false)
        val opens = mutableListOf<WatchCopy>()
        val notices = mutableListOf<String>()
        var exits = 0

        val watch = RoomPlayerWatch(
            watch = member.watch,
            player = player,
            opened = opened,
            failed = failure,
            backgrounded = background,
            vehicleRestricted = restricted,
            profileHeld = profileHeld,
            held = negotiating,
            roomLaunch = roomLaunch,
            openInPlace = ::open,
            exitPlayer = { exits++ },
            scope = world.test.backgroundScope,
            timeSource = world.test.testScheduler.timeSource,
        )

        init {
            member.watch.navigatorOpener = ::open
            world.test.backgroundScope.launch(start = CoroutineStart.UNDISPATCHED) { watch.notices.collect { notices += it } }
        }

        suspend fun open(copy: WatchCopy): Boolean {
            opens += copy
            player.durationMs = copy.durationMs
            opened.value = WatchOpen(copy, shareable = true)
            return true
        }

        val ui: PlayerWatchUi get() = assertNotNull(watch.state.value)
    }

    private fun WatchWorld.player(member: Member, roomLaunch: Boolean = true) = PlayerSide(this, member, roomLaunch)

    private fun ParticipantUi.isNamed(name: String) = this.name == name

    // The guest's copies: Alien 5 and 10 minutes longer than the host's, and Aliens 2 minutes shorter.
    private val alien5 = alien("g-alien-5", "guest-nas", durationMs = ALIEN_MS + 300_000, version = "g-5")
    private val alien10 = alien("g-alien-10", "guest-nas", durationMs = ALIEN_MS + 600_000, version = "g-10")
    private val aliens = alien("g-aliens", "guest-nas", durationMs = ALIENS_MS - 120_000, version = "g-a").copy(title = "Aliens", year = 1986)
    private val hostAliens: MediaItem = alien("aliens", "host-nas", durationMs = ALIENS_MS).copy(title = "Aliens", year = 1986)

    private fun WatchWorld.mismatchedGuest(): Member {
        guestAnswer = { query -> lookup(listOf(alien5, alien10, aliens).filter { it.title == query.title }, succeeded = setOf("guest-nas")) }
        return guest("Ben")
    }

    // The session sheet

    @Test
    fun `the room pill and the sheet give the room at a glance and each row its page`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing }

            val ui = side.ui
            assertEquals("2", ui.pill.count)
            assertTrue(ui.pill.connected)
            assertFalse(ui.pill.isHost)
            assertNull(ui.pill.status)
            val room = ui.room
            assertEquals("K7M-Q2X", room.header.code)
            assertEquals("${text.connected} · ${text.participantCount(2)}", room.status)
            assertEquals("Alien (1979)", room.media.title)
            assertNull(room.settings, "host settings are the host's")
            assertNull(room.end)
            assertEquals(text.leaveRoom, room.leave.label)
            assertEquals(text.hostBadge, room.participants.single { it.isNamed("Host") }.hostBadge)
            assertNull(room.participants.single { it.isNamed(text.nameYou("Ben")) }.hostBadge)
            assertTrue(room.participants.all { it.actions == null }, "a guest has no participant actions")
            val playing = assertIs<WatchMatchUi.Playing>(room.media.match)
            assertEquals(text.yourCopy, playing.label)
            assertNull(room.media.stop, "only the host stops the media")
            assertTrue(ui.following)
            assertFalse(ui.canControl)
            assertEquals(text.notices.controlRefused, ui.controlsLocked)
            assertFalse(ui.canChangeEpisode)
        }
    }

    @Test
    fun `the host settings and participant actions and Stop reach the room from the sheet`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            val side = player(host)

            assertNotNull(side.ui.room.settings)
            side.watch.execute(WatchCommand.SetEveryoneControls(true))
            until("the guest controls playback") { guest.watch.canControl }
            side.watch.execute(WatchCommand.Lock(true))
            until("the guest sees the lock") { guest.state.locked }

            assertNotNull(side.ui.room.participants.single { it.isNamed("Ben") }.actions)
            side.watch.execute(WatchCommand.Kick(guest.peerId))
            until("the guest is removed") { !guest.state.inSession }
            until("the row goes") { side.ui.room.participants.none { it.isNamed("Ben") } }
            assertEquals(1, side.ui.room.participants.count { it.isNamed(text.nameYou("Host")) })

            assertEquals(text.sharingYourCopy, side.ui.room.media.summary)
            assertEquals(text.stopMedia, side.ui.room.media.stop)
            side.watch.execute(WatchCommand.StopMedia)
            until("the media stops") { host.state.media == null }
            until("the sheet says so") { side.ui.room.media.title == null }
            assertEquals(text.nothingPlaying, side.ui.room.media.idle)
        }
    }

    @Test
    fun `the offset page steps and resets and reaches the room`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing }

            assertEquals(WatchLabels.offsetText(0), side.ui.room.offset.value)
            assertFalse(side.ui.room.offset.reset.enabled)

            fun step(label: String, expected: Long) {
                val offset = side.ui.room.offset
                val button = (offset.steps + offset.reset).single { it.label == label }
                side.watch.execute(WatchCommand.SetOffset(button.offsetMs))
                until("the offset is $expected") { guest.state.party.offsetMs == expected && side.ui.room.offset.value == WatchLabels.offsetText(expected) }
            }

            step(text.offsetPlusTenth, 100)
            step(text.offsetPlusSecond, 1100)
            step(text.offsetMinusTenth, 1000)
            step(text.offsetMinusSecond, 0)
            step(text.offsetMinusSecond, -1000)
            until("the host sees the offset") { host.participant(guest.peerId).offsetMs == -1000L }
            assertTrue(side.ui.room.offset.reset.enabled)
            step(T.common.reset, 0)
            assertFalse(side.ui.room.offset.reset.enabled)
        }
    }

    @Test
    fun `Join Current Playback opens the room file from the sheet`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            var refuse = true
            guest.watch.navigatorOpener = { copy -> if (refuse) false else side.open(copy) }
            guest.watch.unregisterPlayer(side.watch)
            together(host, listOf(guest))
            assertNull(side.ui.room.media.joinPlayback)

            hostPlays(host, hostAlien)
            until("the guest may join") { guest.state.canJoinPlayback }
            assertNotNull(side.ui.room.media.joinPlayback)

            refuse = false
            side.watch.execute(WatchCommand.JoinPlayback)
            until("the guest follows") { guest.watch.isFollowing }
            assertEquals(1, side.opens.size)
            until("the row goes") { side.ui.room.media.joinPlayback == null }
        }
    }

    @Test
    fun `leaving or the rooms end takes the room out of the player and the player stays`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val other = guest("Cleo")
            val side = player(guest)
            val otherSide = player(other)
            together(host, listOf(guest, other))

            side.watch.execute(WatchCommand.Leave)
            until("the guest is out") { !guest.state.inSession }
            until("the room leaves the player") { side.watch.state.value == null }
            assertEquals(0, side.exits, "leaving the room keeps the player")
            until("the host sees the guest go") { host.watch.participants.size == 2 }

            host.watch.endRoom()
            until("the room is over") { !other.state.inSession }
            until("the room leaves the other player") { otherSide.watch.state.value == null }
            assertEquals(EndReason.ENDED, other.state.party.endReason)
        }
    }

    @Test
    fun `the sheet and the pill show the reconnecting state while the connection is down`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            assertNull(side.ui.reconnecting)
            assertNull(side.ui.room.reconnecting)

            relay.drop(guest.peerId)
            until("the guest reconnects") { guest.state.reconnecting }
            val ui = side.ui
            assertEquals(text.reconnecting, ui.reconnecting)
            assertEquals(text.reconnecting, ui.pill.status)
            assertFalse(ui.pill.connected)
            assertEquals(text.reconnectingDescription, ui.room.reconnecting?.description)
            assertEquals("${text.reconnecting} · ${text.participantCount(2)}", ui.room.status)

            until("the guest is back") { guest.watch.isConnected }
            assertNull(side.ui.reconnecting)
            assertNull(side.ui.pill.status)
        }
    }

    // The mismatch prompt

    @Test
    fun `a copy of another length is offered with the closest copy and the difference and nothing plays until answered`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            assertNull(side.ui.mismatch)

            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }
            val mismatch = side.ui.mismatch!!
            assertEquals(text.mismatchTitle, mismatch.title)
            assertEquals(text.mismatchDescription(WatchLabels.lengthDifference(300_000)), mismatch.description, "the closest copy is offered")
            assertEquals(text.playAnyway, mismatch.playAnyway)
            assertEquals(text.chooseAnotherCopy, mismatch.chooseAnother)
            assertEquals(text.dontPlay, mismatch.dontPlay)
            assertTrue(side.opens.isEmpty(), "nothing plays until the user answers")

            // A room change that isn't the mismatch keeps its key: the player asks once.
            host.watch.setControl(Control.EVERYONE)
            until("the guest sees the control") { guest.watch.canControl }
            assertEquals(mismatch.key, side.ui.mismatch?.key)
            // The sheet's media row still says it.
            assertEquals(text.mismatchTitle, side.ui.room.media.summary)
            assertIs<WatchMatchUi.Mismatch>(side.ui.room.media.match)
        }
    }

    @Test
    fun `Play Anyway plays the offered copy and the prompt closes`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }

            side.watch.execute(WatchCommand.PlayAnyway)
            until("the guest plays the copy") { guest.watch.isFollowing }
            assertNull(side.ui.mismatch)
            assertEquals(Match(MatchState.MISMATCHED, 300_000), guest.state.party.match)
            assertEquals(listOf(copyOf(alien5)), side.opens)
        }
    }

    @Test
    fun `Choose Another Copy lists the copies closest first and the one chosen plays and the prompt closes`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }

            val copies = side.ui.room.media.copies
            val rows = copies.rows
            assertEquals(2, rows.size)
            assertTrue(WatchLabels.lengthDifference(300_000) in rows[0].subtitle, "closest length first")
            assertTrue(WatchLabels.lengthDifference(600_000) in rows[1].subtitle)

            side.watch.execute(WatchCommand.ChooseCopy(rows[1].id))
            until("the guest plays the chosen copy") { guest.watch.isFollowing }
            assertNull(side.ui.mismatch)
            assertEquals(Match(MatchState.MISMATCHED, 600_000), guest.state.party.match)
            assertEquals(listOf(copyOf(alien10)), side.opens)
            assertTrue(side.ui.room.media.copies.rows.single { it.id == rows[1].id }.current)
            assertEquals(copies.chosen + 1, side.ui.room.media.copies.chosen, "the room took the choice: the page closes")
        }
    }

    @Test
    fun `Do not Play plays nothing and the room sees this user has no copy`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }

            side.watch.execute(WatchCommand.DontPlay)
            until("the host sees the guest has no copy") { host.participant(guest.peerId).match?.state == MatchState.UNAVAILABLE }
            assertNull(side.ui.mismatch)
            assertTrue(side.opens.isEmpty())
        }
    }

    @Test
    fun `a new mismatch asks again`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }
            val first = side.ui.mismatch!!.key
            side.watch.execute(WatchCommand.DontPlay)
            until("the prompt closes") { side.ui.mismatch == null }

            hostPlays(host, hostAliens)
            until("the room plays Aliens") { guest.state.media?.title == "Aliens" }
            until("the guest is asked again") { side.ui.mismatch != null }
            assertNotEquals(first, side.ui.mismatch!!.key)
            assertEquals(text.mismatchDescription(WatchLabels.lengthDifference(-120_000)), side.ui.mismatch!!.description)
        }
    }

    @Test
    fun `a mismatch settled elsewhere closes the prompt when the host stops the media`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }

            host.watch.stopMedia()
            until("the room media stops") { guest.state.media == null }
            assertNull(side.ui.mismatch)
        }
    }

    @Test
    fun `never asks the host about the hosts own media`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(host)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest has a mismatch") { guest.state.party.mismatch != null }
            assertNull(side.ui.mismatch)
            assertIs<WatchMatchUi.Sharing>(side.ui.room.media.match)
        }
    }

    @Test
    fun `after Play Anyway the offset page offers the length difference and it sets the offset`() = runTest {
        watchWorld {
            val host = host()
            val guest = mismatchedGuest()
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest is asked") { side.ui.mismatch != null }
            side.watch.execute(WatchCommand.PlayAnyway)
            until("the guest plays the copy") { guest.watch.isFollowing }

            val offset = side.ui.room.offset
            assertEquals(text.offsetHint(WatchLabels.lengthDifference(300_000)), offset.hint)
            val apply = assertNotNull(offset.apply)
            assertEquals(text.applyDifference(WatchLabels.offsetText(300_000)), apply.label)
            side.watch.execute(WatchCommand.SetOffset(apply.offsetMs))
            until("the offset is the difference") { guest.state.party.offsetMs == 300_000L }
            until("the page shows it") { side.ui.room.offset.value == WatchLabels.offsetText(300_000) }
            until("the host sees the offset") { host.participant(guest.peerId).offsetMs == 300_000L }
        }
    }

    // The player's overlays

    @Test
    fun `a player that refused to start shows Play and Play starts it and the prompt goes`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            var refuse = true
            side.player.refusePlay = { refuse }
            together(host, listOf(guest))
            assertNull(side.ui.playBlocked)

            hostPlays(host, hostAlien)
            until("the guest player refuses to start") { side.ui.playBlocked != null }
            assertEquals(WatchPlayBlockedUi(text.playBlockedTitle, text.playBlockedDescription, T.common.play), side.ui.playBlocked)

            // Refused again, it stays.
            settle { side.watch.execute(WatchCommand.PlayBlockedPlayer) }
            runFor(100)
            assertNotNull(side.ui.playBlocked)
            assertFalse(side.player.playing)

            refuse = false
            side.watch.execute(WatchCommand.PlayBlockedPlayer)
            until("the guest player plays") { side.player.playing }
            until("the prompt goes") { side.ui.playBlocked == null }
        }
    }

    // The player's files

    @Test
    fun `a hosts file is shared where it opens and not where the player still is`() = runTest {
        watchWorld {
            val host = host()
            val side = player(host, roomLaunch = false)
            together(host, emptyList())
            // The engine opens the saved position (90 s) but still reports its own start until the file's first frame.
            side.player.positionMs = 2_000
            side.player.startLoad(1)
            side.opened.value = WatchOpen(copyOf(hostAlien), shareable = true, start = WatchFileStart(loadId = 1, positionMs = 90_000))
            until("the room plays the host's file") { host.state.roomCopy != null }
            assertEquals(90_000, host.state.room?.positionMs)

            side.player.showFirstFrame(90_000)
            runFor(3_000)
            val seeks = side.player.commandLog.filter { it.startsWith("seek:") }.map { it.removePrefix("seek:").toLong() }
            assertTrue(seeks.all { it >= 90_000 }, "never back to the engine's start: $seeks")
        }
    }

    @Test
    fun `the room starts the files of a connected host and the rooms file of a guest but not a guests own`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val hostSide = player(host, roomLaunch = false)
            val guestSide = player(guest, roomLaunch = false)
            assertFalse(hostSide.watch.ownsStart(), "outside a room the player starts its own files")
            together(host, listOf(guest))
            assertTrue(hostSide.watch.ownsStart())
            assertFalse(guestSide.watch.ownsStart(), "a guest's own file")

            guestSide.watch.openingForRoom()
            assertTrue(guestSide.watch.ownsStart(), "the room's file opening for the guest")
            guestSide.watch.abandonRoomOpen()
            assertFalse(guestSide.watch.ownsStart())

            hostSide.opened.value = WatchOpen(copyOf(hostAlien), shareable = false)
            runFor(100)
            assertFalse(hostSide.watch.ownsStart(), "a file the room can't get plays as the host's own")
        }
    }

    @Test
    fun `the rooms commands wait while the player switches the display for the file`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            side.negotiating.value = true
            hostPlays(host, hostAlien)
            until("the guest opened the room's file") { side.opens.isNotEmpty() }
            runFor(3_000)
            assertTrue(side.player.commandLog.isEmpty(), "${side.player.commandLog}")
            assertFalse(side.player.playing)

            side.negotiating.value = false
            until("the guest plays with the room") { side.player.playing }
        }
    }

    @Test
    fun `a car that forbids video pauses this player alone and the room catches it up once lifted`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows and plays") { guest.watch.isFollowing && side.player.playing }

            side.restricted.value = true
            until("the guest player pauses") { !side.player.playing }
            runFor(1_000)
            assertFalse(guest.watch.isFollowing, "the room stops waiting for the guest")
            assertEquals(Phase.PLAYING, host.state.room?.phase, "not a pause for everyone")

            side.restricted.value = false
            until("the room catches the guest up") { guest.watch.isFollowing && side.player.playing }
        }
    }

    @Test
    fun `ending the media from the player takes the room to its end and the item is over in the player`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows and plays") { guest.watch.isFollowing && side.player.playing }
            host.watch.setControl(Control.EVERYONE)
            until("the guest controls") { guest.watch.canControl }
            assertFalse(side.ui.atMediaEnd)

            side.watch.endMedia()
            until("the item is over in the player") { side.ui.atMediaEnd }
            assertEquals(Phase.PAUSED, host.state.room?.phase)
            assertFalse(side.player.playing)
        }
    }

    @Test
    fun `the profile picker over the player pauses it alone and the room catches it up once a profile is chosen`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows and plays") { guest.watch.isFollowing && side.player.playing }

            side.profileHeld.value = true
            until("the guest player pauses") { !side.player.playing }
            runFor(1_000)
            assertTrue(guest.watch.isAway(WatchAway.PROFILE_SELECTION))
            assertFalse(guest.watch.isFollowing, "the room stops waiting for the guest")
            assertEquals(Phase.PLAYING, host.state.room?.phase, "not a pause for everyone")
            assertFalse(side.player.playing, "the room doesn't start it under the picker")

            side.profileHeld.value = false
            until("the room catches the guest up") { guest.watch.isFollowing && side.player.playing }
        }
    }

    @Test
    fun `an app out of sight leaves the rooms playback and the room catches it up on return`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing && side.player.playing }

            side.background.value = true
            until("the room stops waiting for the guest") { !guest.watch.isFollowing }
            assertEquals(Phase.PLAYING, host.state.room?.phase)

            side.background.value = false
            until("the room catches the guest up") { guest.watch.isFollowing }
        }
    }

    @Test
    fun `a released player is let go of with what it was away for and the room keeps the hosts file when another takes over`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing && side.player.playing }
            side.background.value = true
            side.restricted.value = true
            side.profileHeld.value = true
            runFor(100)
            assertTrue(guest.watch.isAway(WatchAway.BACKGROUND))

            val released = assertNotNull(side.watch.release(continuing = true))
            runFor(100)
            assertTrue(released.isCompleted, "the room let go of the player")
            assertFalse(guest.watch.isAway(WatchAway.BACKGROUND))
            assertFalse(guest.watch.isAway(WatchAway.VEHICLE_RESTRICTED))
            assertFalse(guest.watch.isAway(WatchAway.PROFILE_SELECTION))
            assertNotNull(host.state.media)
        }
    }

    @Test
    fun `a reload of the rooms file keeps following and a failed file leaves the room until a retry opens it again`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing }
            val copy = side.opens.single()

            // A quality switch: the same file again, which reads as opening until its frame.
            side.player.startLoad(2)
            side.opened.value = WatchOpen(copy, shareable = true, start = WatchFileStart(loadId = 2, positionMs = side.player.positionMs))
            runFor(20)
            assertTrue(guest.watch.isFollowing, "the same adapter: no new choice")
            side.player.showFirstFrame(side.player.positionMs)

            side.failure.value = true
            until("the room stops commanding the dead file") { !guest.watch.isFollowing }
            runFor(1_000)
            assertNotNull(host.state.media, "the room keeps its media")
            assertEquals(listOf(copy), side.opens, "nor does it open the file again by itself")

            side.failure.value = false
            side.player.startLoad(3)
            side.opened.value = WatchOpen(copy, shareable = true, start = WatchFileStart(loadId = 3, positionMs = 0))
            side.player.showFirstFrame(0)
            until("the retry follows the room again") { guest.watch.isFollowing }
        }
    }

    @Test
    fun `a room copy without a version stands for whichever version of that item the player opened`() = runTest {
        watchWorld {
            val bare = alien("g-alien", "guest-nas", durationMs = ALIEN_MS + 800).copy(mediaVersions = null)
            val versioned = alien("g-alien", "guest-nas", durationMs = ALIEN_MS + 800, version = "g-hd")
            guestAnswer = { lookup(listOf(bare), succeeded = setOf("guest-nas")) }
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            hostPlays(host, hostAlien)
            until("the guest follows") { guest.watch.isFollowing }
            assertEquals("", side.opens.single().versionId, "the server listed no version")

            // The player reloads the item, which now names its version: the same file to the room.
            side.player.startLoad(2)
            side.opened.value = WatchOpen(copyOf(versioned), shareable = true, start = WatchFileStart(loadId = 2, positionMs = side.player.positionMs))
            side.player.showFirstFrame(side.player.positionMs)
            runFor(1_000)
            assertTrue(guest.watch.isFollowing)
            assertEquals(copyOf(bare), side.watch.openCopy, "the adapter of the room's copy stays")
            assertEquals(1, side.opens.size, "nothing opens again")
        }
    }

    // Notices

    @Test
    fun `each notice is told in the player`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(host)
            together(host, listOf(guest))
            until("the join is told") { text.notices.joined("Ben") in side.notices }

            guest.watch.leave()
            until("the leave is told") { text.notices.left("Ben") in side.notices }
        }
    }

    @Test
    fun `nothing is told for the users own leave and the hosts end is told`() = runTest {
        watchWorld {
            val host = host()
            val guest = guest("Ben")
            val side = player(guest)
            together(host, listOf(guest))
            val before = side.notices.size

            guest.watch.leave()
            until("the guest is out") { !guest.state.inSession }
            runFor(100)
            assertEquals(before, side.notices.size)

            settle { guest.watch.joinRoom(host.state.roomCode!!) }
            until("the guest is back") { host.watch.participants.size == 2 }
            host.watch.endRoom()
            until("the room is over") { !guest.state.inSession }
            until("the end is told") { WatchLabels.endText(EndReason.ENDED)!! in side.notices }
            assertEquals(1, guest.noticesOf<com.edde746.plezy.watch.WatchNotice.Ended>().size)
        }
    }

    private companion object {
        const val ALIENS_MS = 8_220_000L
    }
}
