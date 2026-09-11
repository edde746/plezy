package com.edde746.plezy.exoplayer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class MpvAudioFilterStateTest {
  @Test
  fun disabledEqStaysOffAfterNormalizationAndCoreRecreation() {
    val writes = mutableListOf<String>()
    val state = MpvAudioFilterState("", "eq") { chain, done ->
      writes.add(chain)
      done(Result.success(Unit))
    }
    state.setBase("loudnorm") { assertTrue(it.isSuccess) }
    state.setEqualizer("") { assertTrue(it.isSuccess) }
    val recreated = MpvAudioFilterState(state.base, state.equalizer) { _, done -> done(Result.success(Unit)) }
    assertEquals("loudnorm", recreated.combined)
    assertEquals("loudnorm", writes.last())
    assertFalse(state.base.contains("eq"))
  }

  @Test
  fun concurrentChangesUseAcceptedStateAndFailureDoesNotPoisonReplay() {
    val pending = mutableListOf<(Result<Unit>) -> Unit>()
    val chains = mutableListOf<String>()
    val state = MpvAudioFilterState("loudnorm", "eq1") { chain, done ->
      chains.add(chain)
      pending.add(done)
    }
    state.setEqualizer("eq2") { assertTrue(it.isFailure) }
    state.setBase("custom") { assertTrue(it.isSuccess) }
    assertEquals(listOf("loudnorm,eq2"), chains)
    pending.removeAt(0)(Result.failure(IllegalStateException("native refusal")))
    assertEquals("custom,eq1", chains.last())
    pending.removeAt(0)(Result.success(Unit))
    assertEquals("custom,eq1", state.combined)
  }

  @Test
  fun invalidationCompletesPendingRepliesAndRejectsLateSuccess() {
    var complete: ((Result<Unit>) -> Unit)? = null
    var replies = 0
    val state = MpvAudioFilterState("base", "") { _, done -> complete = done }
    state.setEqualizer("eq") {
      assertTrue(it.isFailure)
      replies++
    }
    state.setBase("new") {
      assertTrue(it.isFailure)
      replies++
    }
    state.invalidate()
    complete!!(Result.success(Unit))
    assertEquals(2, replies)
    assertEquals("base", state.combined)
  }
}
