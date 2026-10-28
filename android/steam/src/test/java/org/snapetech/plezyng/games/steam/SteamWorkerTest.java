// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

import static org.junit.Assert.*;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Test;

public final class SteamWorkerTest {
  @Test
  public void interruptionCannotAcknowledgeALiveDecoder() throws Exception {
    CountDownLatch started = new CountDownLatch(1);
    CountDownLatch release = new CountDownLatch(1);
    CountDownLatch acknowledged = new CountDownLatch(1);
    AtomicBoolean preservedInterrupt = new AtomicBoolean();
    Thread decoder = new Thread(() -> {
      started.countDown();
      try {
        release.await();
      } catch (InterruptedException error) {
        throw new AssertionError(error);
      }
    });
    decoder.start();
    assertTrue(started.await(1, TimeUnit.SECONDS));
    Thread owner = new Thread(() -> {
      Thread.currentThread().interrupt();
      SteamWorker.await(decoder);
      preservedInterrupt.set(Thread.currentThread().isInterrupted());
      acknowledged.countDown();
    });
    owner.start();
    try {
      assertFalse(acknowledged.await(30, TimeUnit.MILLISECONDS));
      owner.interrupt();
      assertFalse(acknowledged.await(30, TimeUnit.MILLISECONDS));
    } finally {
      release.countDown();
      owner.join(1000);
      decoder.join(1000);
    }
    assertFalse(owner.isAlive());
    assertFalse(decoder.isAlive());
    assertEquals(0, acknowledged.getCount());
    assertTrue(preservedInterrupt.get());
    SteamWorker.await(decoder); // Repeated teardown remains harmless.
  }

  @Test
  public void cannotJoinTheCurrentWorker() {
    assertThrows(IllegalStateException.class, () -> SteamWorker.await(Thread.currentThread()));
  }
}
