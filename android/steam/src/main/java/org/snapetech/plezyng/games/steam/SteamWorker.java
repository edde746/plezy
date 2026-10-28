// SPDX-License-Identifier: GPL-3.0-or-later
package org.snapetech.plezyng.games.steam;

/** The session worker owns decoder teardown; the UI only requests cancellation. */
final class SteamWorker {
  private SteamWorker() {}

  static void await(Thread worker) {
    if (worker == Thread.currentThread())
      throw new IllegalStateException("Cannot join the current decoder worker");
    boolean interrupted = false;
    while (worker.isAlive()) {
      try {
        worker.join();
      } catch (InterruptedException error) {
        interrupted = true;
      }
    }
    // Preserve cancellation for the caller after resource ownership really ends.
    if (interrupted)
      Thread.currentThread().interrupt();
  }
}
