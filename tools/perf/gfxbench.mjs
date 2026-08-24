// HWUI frame-timing benchmark. Flutter renders into a TextureView here, so
// `dumpsys gfxinfo` sees real composited frames — this is the channel where
// surface-opacity and overdraw costs actually land.
//
// Usage: bun tools/perf/gfxbench.mjs <label> <scenario> [repeats]

import { adb, keys, sleep } from "./vmclient.mjs";
import { appendFileSync, writeFileSync } from "node:fs";

const PKG = "com.edde746.plezy";
const [label, scenario = "railRight", repeats = "3"] = process.argv.slice(2);
const DPAD = { up: 19, down: 20, left: 21, right: 22, center: 23, back: 4 };

const scenarios = {
  railRight: async () => keys(Array(30).fill(DPAD.right), 240),
  railVertical: async () => {
    for (let i = 0; i < 7; i++) await keys([DPAD.down, DPAD.right, DPAD.right], 260);
    await keys(Array(7).fill(DPAD.up), 260);
  },
  detailRoundTrip: async () => {
    for (let i = 0; i < 5; i++) {
      await keys([DPAD.center], 2800);
      await keys([DPAD.back], 1900);
    }
  },
  idle: async () => sleep(8000),
};

/** Parse the aggregate stats block from `dumpsys gfxinfo <pkg>`. */
function parseAggregate(text) {
  const num = (re) => {
    const m = text.match(re);
    return m ? Number(m[1]) : null;
  };
  return {
    totalFrames: num(/Total frames rendered:\s*(\d+)/),
    jankyFrames: num(/Janky frames:\s*(\d+)/),
    jankyPct: num(/Janky frames:\s*\d+\s*\(([\d.]+)%\)/),
    p50: num(/50th percentile:\s*(\d+)ms/),
    p90: num(/90th percentile:\s*(\d+)ms/),
    p95: num(/95th percentile:\s*(\d+)ms/),
    p99: num(/99th percentile:\s*(\d+)ms/),
    missedVsync: num(/Number Missed Vsync:\s*(\d+)/),
    highInputLatency: num(/Number High input latency:\s*(\d+)/),
    slowUiThread: num(/Number Slow UI thread:\s*(\d+)/),
    slowBitmapUploads: num(/Number Slow bitmap uploads:\s*(\d+)/),
    slowIssueDraw: num(/Number Slow issue draw commands:\s*(\d+)/),
    frameDeadlineMissed: num(/Number Frame deadline missed:\s*(\d+)/),
  };
}

/**
 * framestats gives per-frame nanosecond timestamps. Column 1 is INTENDED_VSYNC
 * and column 13 is FRAME_COMPLETED; their delta is the true end-to-end frame
 * time, which is what the viewer perceives.
 */
function parseFramestats(text) {
  const start = text.indexOf("---PROFILEDATA---");
  if (start < 0) return [];
  const rows = text
    .slice(start)
    .split("\n")
    .filter((l) => /^\d/.test(l.trim()))
    .map((l) => l.trim().split(",").map(Number));
  const out = [];
  for (const r of rows) {
    if (r.length < 14) continue;
    const intendedVsync = r[1];
    const frameCompleted = r[13];
    if (!intendedVsync || !frameCompleted || frameCompleted <= intendedVsync) continue;
    const totalMs = (frameCompleted - intendedVsync) / 1e6;
    if (totalMs > 500) continue; // idle gaps, not frames
    out.push({
      totalMs,
      handleInputMs: (r[5] - r[4]) / 1e6,
      animationMs: (r[6] - r[5]) / 1e6,
      traversalMs: (r[8] - r[6]) / 1e6,
      drawMs: (r[9] - r[8]) / 1e6,
      syncMs: (r[10] - r[9]) / 1e6,
      gpuMs: (r[12] - r[11]) / 1e6,
    });
  }
  return out;
}

const pctOf = (a) => {
  if (!a.length) return null;
  const s = [...a].sort((x, y) => x - y);
  const q = (p) => +s[Math.min(s.length - 1, Math.floor(p * s.length))].toFixed(2);
  return {
    n: s.length,
    mean: +(s.reduce((x, y) => x + y, 0) / s.length).toFixed(2),
    p50: q(0.5),
    p90: q(0.9),
    p95: q(0.95),
    p99: q(0.99),
    max: +s[s.length - 1].toFixed(2),
  };
};

const run = scenarios[scenario] ?? scenarios.railRight;
const runs = [];

for (let i = 0; i < Number(repeats); i++) {
  adb("shell", "dumpsys", "gfxinfo", PKG, "reset");
  await sleep(400);
  await run();
  await sleep(600);
  const text = adb("shell", "dumpsys", "gfxinfo", PKG, "framestats");
  const agg = parseAggregate(text);
  const frames = parseFramestats(text);
  runs.push({
    agg,
    frameTotal: pctOf(frames.map((f) => f.totalMs)),
    draw: pctOf(frames.map((f) => f.drawMs)),
    traversal: pctOf(frames.map((f) => f.traversalMs)),
    gpu: pctOf(frames.map((f) => f.gpuMs)),
    sync: pctOf(frames.map((f) => f.syncMs)),
    over16_7: frames.filter((f) => f.totalMs > 16.7).length,
    over33: frames.filter((f) => f.totalMs > 33.4).length,
    frames: frames.length,
  });
  console.log(`run ${i + 1}: ${JSON.stringify(runs[runs.length - 1].agg)}`);
}

// Median-of-runs on the headline numbers keeps a single noisy run from lying.
const med = (vals) => {
  const s = vals.filter((v) => v != null).sort((a, b) => a - b);
  return s.length ? s[Math.floor(s.length / 2)] : null;
};
const summary = {
  label,
  scenario,
  repeats: runs.length,
  median: {
    jankyPct: med(runs.map((r) => r.agg.jankyPct)),
    p50: med(runs.map((r) => r.agg.p50)),
    p90: med(runs.map((r) => r.agg.p90)),
    p95: med(runs.map((r) => r.agg.p95)),
    p99: med(runs.map((r) => r.agg.p99)),
    frameTotalP50: med(runs.map((r) => r.frameTotal?.p50)),
    frameTotalP90: med(runs.map((r) => r.frameTotal?.p90)),
    frameTotalP99: med(runs.map((r) => r.frameTotal?.p99)),
    drawP90: med(runs.map((r) => r.draw?.p90)),
    gpuP90: med(runs.map((r) => r.gpu?.p90)),
    traversalP90: med(runs.map((r) => r.traversal?.p90)),
    over16_7: med(runs.map((r) => r.over16_7)),
    over33: med(runs.map((r) => r.over33)),
    slowBitmapUploads: med(runs.map((r) => r.agg.slowBitmapUploads)),
    slowUiThread: med(runs.map((r) => r.agg.slowUiThread)),
    missedVsync: med(runs.map((r) => r.agg.missedVsync)),
  },
  runs,
};

writeFileSync(`/tmp/gfx_${label}_${scenario}.json`, JSON.stringify(summary, null, 2));
appendFileSync("/tmp/gfx_results.tsv",
  `${label}\t${scenario}\t${JSON.stringify(summary.median)}\n`);
console.log("\n=== MEDIAN ===");
console.log(JSON.stringify(summary.median, null, 2));
