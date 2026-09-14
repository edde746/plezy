// Repeatable D-pad workloads. One `input` invocation per burst (~30ms/key on
// the target box) so host-side adb latency does not dilute the device workload.

import { adb, sleep } from "./vmclient.mjs";

export const R = 22, L = 21, U = 19, D = 20, OK = 23, BACK = 4;
export const burst = (...codes) => adb("shell", "input", "keyevent", ...codes.map(String));

export const scenarios = {
  // Stay inside the rail: 8 right, 8 left, repeated. Never dead-ends.
  railRight: async () => {
    for (let i = 0; i < 8; i++) {
      burst(...Array(8).fill(R));
      await sleep(700);
      burst(...Array(8).fill(L));
      await sleep(700);
    }
  },
  railVertical: async () => {
    for (let i = 0; i < 6; i++) {
      burst(D, D, D, R, R, R);
      await sleep(900);
      burst(U, U, U, L, L, L);
      await sleep(900);
    }
  },
  detailRoundTrip: async () => {
    for (let i = 0; i < 5; i++) {
      burst(OK);
      await sleep(3200);
      burst(BACK);
      await sleep(2200);
    }
  },
  sidebar: async () => {
    for (let i = 0; i < 8; i++) {
      burst(L, L, L, L);
      await sleep(600);
      burst(R, R, R, R);
      await sleep(600);
    }
  },
  // Playback, chrome raised: exercises the 4 Hz position fan-out, the timeline
  // slider repaint and the gradient scrim. Assumes a player is already running.
  playbackChrome: async () => {
    for (let i = 0; i < 6; i++) {
      burst(U);
      await sleep(2200);
    }
  },
  // Held D-pad seek: the worst frame-time window on the TV path, because the
  // key-repeat feedback and the decoder flush land in the same frames.
  playbackSeek: async () => {
    for (let i = 0; i < 6; i++) {
      burst(...Array(8).fill(R));
      await sleep(1400);
      burst(...Array(8).fill(L));
      await sleep(1400);
    }
  },
  idle: async () => sleep(10000),
};
