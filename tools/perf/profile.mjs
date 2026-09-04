// Usage: bun tools/perf/profile.mjs <vmServiceUri> <outPrefix> [scenario]
// Scenarios drive the device via adb while the profiler records, then dump
// CPU self-time, timeline frame stats, and allocation profile to JSON + text.

import { VM, selfTime, durationsByName, pct, sleep } from "./vmclient.mjs";
import { scenarios } from "./scenarios.mjs";
import { writeFileSync } from "node:fs";

const [uri, outPrefix, scenario = "idle"] = process.argv.slice(2);
if (!uri || !outPrefix) {
  console.error("need <vmServiceUri> <outPrefix> [scenario]");
  process.exit(1);
}

const run = scenarios[scenario] ?? scenarios.idle;

const vm = await VM.connect(uri);
const iso = await vm.uiIsolate();
const vmInfo = await vm.call("getVM");
const isolates = vmInfo.isolates.map((i) => ({ id: i.id, name: i.name }));

await vm.call("setVMTimelineFlags", { recordedStreams: ["Dart", "Embedder", "GC"] });
await vm.call("clearVMTimeline");
const t0 = (await vm.call("getVMTimelineMicros")).timestamp;

const wallStart = Date.now();
await run();
const wallMs = Date.now() - wallStart;
const t1 = (await vm.call("getVMTimelineMicros")).timestamp;

const out = { scenario, wallMs, isolates, window: { t0, t1 } };

// ---- CPU self time, per isolate ----
out.cpu = {};
for (const i of isolates) {
  try {
    const cpu = await vm.call("getCpuSamples", {
      isolateId: i.id,
      timeOriginMicros: t0,
      timeExtentMicros: t1 - t0,
    });
    const s = selfTime(cpu);
    out.cpu[i.name] = {
      sampleCount: s.sampleCount,
      samplePeriodUs: cpu.samplePeriod,
      busyMsApprox: +((s.sampleCount * cpu.samplePeriod) / 1000).toFixed(1),
      self: s.self.slice(0, 40),
      total: s.total.slice(0, 40),
    };
  } catch (e) {
    out.cpu[i.name] = { error: String(e.message).slice(0, 200) };
  }
}

// ---- Timeline: frame + phase durations ----
const tl = await vm.call("getVMTimeline", { timeOriginMicros: t0, timeExtentMicros: t1 - t0 });
const evts = tl.traceEvents ?? [];
const wanted = [
  "Animator::BeginFrame",
  "Rasterizer::DoDraw",
  "GPURasterizer::Draw",
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
  "SurfaceFrame::Submit",
  "CompositorContext::ScopedFrame::Raster",
];
const durs = durationsByName(evts, wanted);
out.frames = {};
for (const [name, arr] of durs) if (arr.length) out.frames[name] = pct(arr);

// Jank: UI frames over the 16.68 ms budget.
const ui = durs.get("Animator::BeginFrame") ?? [];
const raster = durs.get("Rasterizer::DoDraw") ?? [];
const over = (a, b) => a.filter((x) => x > b).length;
out.jank = {
  uiFrames: ui.length,
  uiOver16_7: over(ui, 16.7),
  uiOver33: over(ui, 33.4),
  rasterFrames: raster.length,
  rasterOver16_7: over(raster, 16.7),
  rasterOver33: over(raster, 33.4),
  shaderCompiles: (durs.get("shader_compile") ?? []).length,
  shaderCompileMs: +(durs.get("shader_compile") ?? []).reduce((a, b) => a + b, 0).toFixed(1),
};

// ---- GC / allocation ----
try {
  const ap = await vm.call("getAllocationProfile", { isolateId: iso });
  out.gc = {
    newSpace: ap.memoryUsage,
    topClasses: (ap.members ?? [])
      .map((m) => ({
        cls: m.class?.name,
        instances: (m.accumulatedSize ?? 0) > 0 ? m.instancesAccumulated : m.instancesCurrent,
        bytesAccum: m.accumulatedSize ?? 0,
      }))
      .sort((a, b) => b.bytesAccum - a.bytesAccum)
      .slice(0, 25),
  };
} catch (e) {
  out.gc = { error: String(e.message).slice(0, 200) };
}

writeFileSync(`${outPrefix}.json`, JSON.stringify(out, null, 2));

// ---- Human summary ----
const L = [];
L.push(`## scenario=${scenario}  wall=${wallMs}ms`);
L.push(`jank: ${JSON.stringify(out.jank)}`);
L.push(`\n### frame phases (ms)`);
for (const [k, v] of Object.entries(out.frames)) {
  L.push(`  ${k.padEnd(38)} n=${String(v.n).padStart(5)} p50=${String(v.p50).padStart(7)} p90=${String(v.p90).padStart(7)} p99=${String(v.p99).padStart(8)} max=${String(v.max).padStart(8)}`);
}
for (const [name, c] of Object.entries(out.cpu)) {
  if (c.error) { L.push(`\n### cpu ${name}: ERROR ${c.error}`); continue; }
  L.push(`\n### cpu ${name}: ${c.sampleCount} samples (~${c.busyMsApprox}ms busy @${c.samplePeriodUs}us)`);
  for (const r of c.self.slice(0, 22)) L.push(`  ${String(r.pctOfSamples).padStart(6)}%  ${String(r.samples).padStart(5)}  ${r.fn}`);
}
if (out.gc?.topClasses) {
  L.push(`\n### allocation (accumulated bytes)`);
  for (const t of out.gc.topClasses.slice(0, 18)) L.push(`  ${String(t.bytesAccum).padStart(11)}  ${String(t.instances).padStart(8)}  ${t.cls}`);
}
const text = L.join("\n");
writeFileSync(`${outPrefix}.txt`, text);
console.log(text);
vm.close();
