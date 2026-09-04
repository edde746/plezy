// Combined benchmark: Flutter's own UI/raster frame times (VM Service timeline)
// plus HWUI composite framestats, correlated over the same scripted D-pad run.
//
// Usage: bun tools/perf/bench.mjs <vmUri> <label> <scenario> [repeats]

import { VM, durationsByName, pct, adb, sleep } from "./vmclient.mjs";
import { appendFileSync, writeFileSync } from "node:fs";

const PKG = "com.edde746.plezy";
const [uri, label, scenario = "railRight", repeats = "3"] = process.argv.slice(2);

const R = 22, L = 21, U = 19, D = 20, OK = 23, BACK = 4;
/** One `input` invocation per burst: ~30ms/key, mimics holding the remote. */
const burst = (...codes) => adb("shell", "input", "keyevent", ...codes.map(String));

const scenarios = {
  // Stay inside the rail: 8 right, 8 left, repeated. Never dead-ends.
  railRight: async () => {
    for (let i = 0; i < 8; i++) {
      burst(...Array(8).fill(R));
      await sleep(700);
      burst(...Array(8).fill(L));
      await sleep(700);
    }
  },
  // Cross rails vertically: forces new rows to build and new artwork to load.
  railVertical: async () => {
    for (let i = 0; i < 6; i++) {
      burst(D, D, D, R, R, R);
      await sleep(900);
      burst(U, U, U, L, L, L);
      await sleep(900);
    }
  },
  // Detail screen push/pop: route transition + full-screen backdrop.
  detailRoundTrip: async () => {
    for (let i = 0; i < 5; i++) {
      burst(OK);
      await sleep(3200);
      burst(BACK);
      await sleep(2200);
    }
  },
  // Sidebar focus in/out: whole-screen chrome reaction.
  sidebar: async () => {
    for (let i = 0; i < 8; i++) {
      burst(L, L, L, L);
      await sleep(600);
      burst(R, R, R, R);
      await sleep(600);
    }
  },
  idle: async () => sleep(10000),
};

const PHASES = [
  "Animator::BeginFrame",
  "Rasterizer::DoDraw",
  "BUILD",
  "LAYOUT",
  "PAINT",
  "COMPOSITING",
  "SEMANTICS",
  "POST_FRAME",
  "shader_compile",
  "LayerTree::Preroll",
  "LayerTree::Paint",
  "GrDirectContext::flushAndSubmit",
  "CompositorContext::ScopedFrame::Raster",
];

function parseGfx(text) {
  const num = (re) => { const m = text.match(re); return m ? Number(m[1]) : null; };
  const start = text.indexOf("---PROFILEDATA---");
  const frames = [];
  if (start >= 0) {
    for (const line of text.slice(start).split("\n")) {
      if (!/^\d/.test(line.trim())) continue;
      const r = line.trim().split(",").map(Number);
      if (r.length < 14) continue;
      const total = (r[13] - r[1]) / 1e6;
      if (!(total > 0) || total > 500) continue;
      frames.push({ total, draw: (r[9] - r[8]) / 1e6, gpu: (r[12] - r[11]) / 1e6 });
    }
  }
  return {
    totalFrames: num(/Total frames rendered:\s*(\d+)/),
    jankyPct: num(/Janky frames:\s*\d+\s*\(([\d.]+)%\)/),
    p90: num(/90th percentile:\s*(\d+)ms/),
    p95: num(/95th percentile:\s*(\d+)ms/),
    p99: num(/99th percentile:\s*(\d+)ms/),
    slowBitmapUploads: num(/Number Slow bitmap uploads:\s*(\d+)/),
    slowIssueDraw: num(/Number Slow issue draw commands:\s*(\d+)/),
    slowUiThread: num(/Number Slow UI thread:\s*(\d+)/),
    missedVsync: num(/Number Missed Vsync:\s*(\d+)/),
    hwuiFrameTotal: pct(frames.map((f) => f.total)),
    hwuiGpu: pct(frames.map((f) => f.gpu)),
  };
}

const run = scenarios[scenario] ?? scenarios.railRight;
const vm = await VM.connect(uri);
await vm.call("setVMTimelineFlags", { recordedStreams: ["Dart", "Embedder", "GC"] });

const runs = [];
for (let i = 0; i < Number(repeats); i++) {
  adb("shell", "dumpsys", "gfxinfo", PKG, "reset");
  await vm.call("clearVMTimeline");
  const t0 = (await vm.call("getVMTimelineMicros")).timestamp;
  await sleep(300);

  await run();

  await sleep(700);
  const t1 = (await vm.call("getVMTimelineMicros")).timestamp;
  const tl = await vm.call("getVMTimeline", { timeOriginMicros: t0, timeExtentMicros: t1 - t0 });
  const gfx = parseGfx(adb("shell", "dumpsys", "gfxinfo", PKG, "framestats"));

  const durs = durationsByName(tl.traceEvents ?? [], PHASES);
  const ui = durs.get("Animator::BeginFrame") ?? [];
  const raster = durs.get("Rasterizer::DoDraw") ?? [];
  const shader = durs.get("shader_compile") ?? [];
  const phases = {};
  for (const [k, v] of durs) if (v.length) phases[k] = pct(v);

  runs.push({
    gfx,
    phases,
    uiFrames: ui.length,
    uiOver16_7: ui.filter((x) => x > 16.7).length,
    uiOver33: ui.filter((x) => x > 33.4).length,
    uiTotalMs: +ui.reduce((a, b) => a + b, 0).toFixed(1),
    rasterOver16_7: raster.filter((x) => x > 16.7).length,
    rasterTotalMs: +raster.reduce((a, b) => a + b, 0).toFixed(1),
    shaderCompiles: shader.length,
    shaderMs: +shader.reduce((a, b) => a + b, 0).toFixed(1),
  });
  console.log(
    `run ${i + 1}: uiFrames=${ui.length} uiP90=${phases["Animator::BeginFrame"]?.p90} ` +
    `uiP99=${phases["Animator::BeginFrame"]?.p99} over16.7=${runs[i].uiOver16_7} ` +
    `rasterP90=${phases["Rasterizer::DoDraw"]?.p90} shader=${shader.length}/${runs[i].shaderMs}ms ` +
    `hwuiFrames=${gfx.totalFrames} hwuiP90=${gfx.p90} janky=${gfx.jankyPct}%`
  );
}

const med = (v) => { const s = v.filter((x) => x != null).sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : null; };
const summary = {
  label, scenario, repeats: runs.length,
  median: {
    uiFrames: med(runs.map((r) => r.uiFrames)),
    uiP50: med(runs.map((r) => r.phases["Animator::BeginFrame"]?.p50)),
    uiP90: med(runs.map((r) => r.phases["Animator::BeginFrame"]?.p90)),
    uiP99: med(runs.map((r) => r.phases["Animator::BeginFrame"]?.p99)),
    uiMax: med(runs.map((r) => r.phases["Animator::BeginFrame"]?.max)),
    uiOver16_7: med(runs.map((r) => r.uiOver16_7)),
    uiOver33: med(runs.map((r) => r.uiOver33)),
    uiTotalMs: med(runs.map((r) => r.uiTotalMs)),
    buildP90: med(runs.map((r) => r.phases["BUILD"]?.p90)),
    buildTotalP50: med(runs.map((r) => r.phases["BUILD"]?.p50)),
    layoutP90: med(runs.map((r) => r.phases["LAYOUT"]?.p90)),
    paintP90: med(runs.map((r) => r.phases["PAINT"]?.p90)),
    semanticsP90: med(runs.map((r) => r.phases["SEMANTICS"]?.p90)),
    semanticsN: med(runs.map((r) => r.phases["SEMANTICS"]?.n)),
    rasterP90: med(runs.map((r) => r.phases["Rasterizer::DoDraw"]?.p90)),
    rasterP99: med(runs.map((r) => r.phases["Rasterizer::DoDraw"]?.p99)),
    rasterTotalMs: med(runs.map((r) => r.rasterTotalMs)),
    rasterOver16_7: med(runs.map((r) => r.rasterOver16_7)),
    shaderCompiles: med(runs.map((r) => r.shaderCompiles)),
    shaderMs: med(runs.map((r) => r.shaderMs)),
    hwuiFrames: med(runs.map((r) => r.gfx.totalFrames)),
    hwuiP90: med(runs.map((r) => r.gfx.p90)),
    hwuiP99: med(runs.map((r) => r.gfx.p99)),
    hwuiJankyPct: med(runs.map((r) => r.gfx.jankyPct)),
    hwuiGpuP90: med(runs.map((r) => r.gfx.hwuiGpu?.p90)),
    slowBitmapUploads: med(runs.map((r) => r.gfx.slowBitmapUploads)),
    slowIssueDraw: med(runs.map((r) => r.gfx.slowIssueDraw)),
  },
  runs,
};

writeFileSync(`/tmp/bench_${label}_${scenario}.json`, JSON.stringify(summary, null, 2));
appendFileSync("/tmp/bench_results.jsonl", JSON.stringify({ label, scenario, ...summary.median }) + "\n");
console.log("\n=== MEDIAN " + label + " / " + scenario + " ===");
console.log(JSON.stringify(summary.median, null, 2));
vm.close();
