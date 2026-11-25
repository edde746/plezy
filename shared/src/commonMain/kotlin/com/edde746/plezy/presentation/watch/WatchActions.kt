package com.edde746.plezy.presentation.watch

import com.edde746.plezy.input.WatchCommand
import com.edde746.plezy.strings.T
import com.edde746.plezy.watch.WatchTogether
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import party.openwatch.Control

/**
 * Runs the room's [WatchCommand]s on [watch], for the screen's store and the player alike; [message] shows what the
 * user must know of one that failed ("Couldn't play this copy for the room").
 */
internal class WatchActions(
    private val watch: WatchTogether,
    private val scope: CoroutineScope,
    private val message: (String) -> Unit,
) {
    fun run(command: WatchCommand) {
        when (command) {
            WatchCommand.JoinPlayback -> scope.launch { watch.openRoomCopy() }
            WatchCommand.StopMedia -> watch.stopMedia()
            is WatchCommand.ChooseCopy -> {
                val candidate = watch.state.value.party.candidates.firstOrNull { it.candidate.id == command.candidateId }?.candidate ?: return
                scope.launch { if (!watch.choose(candidate)) message(T.watchTogether.choiceFailed) }
            }
            WatchCommand.SearchAgain -> watch.searchAgain()
            WatchCommand.PlayAnyway -> watch.acceptMismatch()
            WatchCommand.DontPlay -> watch.declineMismatch()
            is WatchCommand.SetOffset -> watch.setOffset(command.offsetMs)
            is WatchCommand.SetEveryoneControls -> watch.setControl(if (command.everyone) Control.EVERYONE else Control.HOST)
            is WatchCommand.Lock -> watch.setLocked(command.locked)
            is WatchCommand.MakeHost -> watch.transferHost(command.peerId)
            is WatchCommand.Kick -> watch.kick(command.peerId)
            WatchCommand.Leave -> watch.leave()
            WatchCommand.End -> watch.endRoom()
            WatchCommand.PlayBlockedPlayer -> scope.launch { watch.playBlockedPlayer() }
        }
    }
}
