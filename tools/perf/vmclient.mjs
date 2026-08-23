// Dart VM Service client + measurement helpers for on-device Flutter profiling.
// Measurement scaffolding only: not shipped, not referenced by lib/.

import { spawnSync } from "node:child_process";

const ADB = `${process.env.HOME}/Library/Android/sdk/platform-tools/adb`;
export const DEVICE = process.env.PLEZY_DEVICE ?? "192.168.1.7:5555";

export function adb(...args) {
  const r = spawnSync(ADB, ["-s", DEVICE, ...args], { encoding: "utf8" });
  if (r.status !== 0) throw new Error(`adb ${args.join(" ")}: ${r.stderr}`);
  return r.stdout;
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

/** Send a keyevent burst with a fixed inter-key delay. */
export async function keys(sequence, delayMs = 320) {
  for (const k of sequence) {
    adb("shell", "input", "keyevent", String(k));
    await sleep(delayMs);
  }
}

export class VM {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    ws.addEventListener("message", (e) => {
      const msg = JSON.parse(e.data);
      if (msg.id != null && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        msg.error ? reject(new Error(JSON.stringify(msg.error))) : resolve(msg.result);
      }
    });
  }

  static async connect(uri) {
    const url = uri.replace(/^http/, "ws").replace(/\/$/, "") + "/ws";
    const ws = new WebSocket(url);
    await new Promise((res, rej) => {
      ws.addEventListener("open", res);
      ws.addEventListener("error", rej);
    });
    return new VM(ws);
  }

  call(method, params = {}) {
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ jsonrpc: "2.0", id, method, params }));
      setTimeout(() => {
        if (this.pending.delete(id)) reject(new Error(`${method} timed out`));
      }, 120000);
    });
  }

  close() {
    this.ws.close();
  }

  /** The main UI isolate (the one running the Flutter framework). */
  async uiIsolate() {
    const vm = await this.call("getVM");
    const named = vm.isolates.find((i) => i.name === "main" || /main/i.test(i.name));
    return (named ?? vm.isolates[0]).id;
  }
}

/** p50/p90/p95/p99/max over a numeric array. */
export function pct(values) {
  if (!values.length) return null;
  const s = [...values].sort((a, b) => a - b);
  const at = (q) => s[Math.min(s.length - 1, Math.floor(q * s.length))];
  return {
    n: s.length,
    mean: +(s.reduce((a, b) => a + b, 0) / s.length).toFixed(2),
    p50: +at(0.5).toFixed(2),
    p90: +at(0.9).toFixed(2),
    p95: +at(0.95).toFixed(2),
    p99: +at(0.99).toFixed(2),
    max: +s[s.length - 1].toFixed(2),
  };
}

/**
 * Duration (ms) of every begin/end pair for the named timeline events,
 * keyed by event name. Handles the engine's 'B'/'E' and 'X' phases.
 */
export function durationsByName(traceEvents, names) {
  const want = new Set(names);
  const stacks = new Map(); // `${pid}:${tid}:${name}` -> [ts...]
  const out = new Map(names.map((n) => [n, []]));
  for (const e of traceEvents) {
    if (!want.has(e.name)) continue;
    if (e.ph === "X" && typeof e.dur === "number") {
      out.get(e.name).push(e.dur / 1000);
      continue;
    }
    const key = `${e.pid}:${e.tid}:${e.name}`;
    if (e.ph === "B") {
      if (!stacks.has(key)) stacks.set(key, []);
      stacks.get(key).push(e.ts);
    } else if (e.ph === "E") {
      const st = stacks.get(key);
      if (st?.length) out.get(e.name).push((e.ts - st.pop()) / 1000);
    }
  }
  return out;
}

/** Self-time histogram (in samples) by function, from getCpuSamples output. */
export function selfTime(cpu) {
  const fns = cpu.functions ?? [];
  const label = (i) => {
    const f = fns[i]?.function;
    if (!f) return `<unknown ${i}>`;
    const owner = f.owner?.name ?? f.owner?.class?.name ?? "";
    const uri = f.location?.script?.uri ?? f.owner?.location?.script?.uri ?? "";
    return `${owner ? owner + "." : ""}${f.name}  [${uri.replace(/^package:/, "")}]`;
  };
  const self = new Map();
  const total = new Map();
  for (const s of cpu.samples ?? []) {
    const st = s.stack ?? [];
    if (!st.length) continue;
    const leaf = label(st[0]);
    self.set(leaf, (self.get(leaf) ?? 0) + 1);
    const seen = new Set();
    for (const idx of st) {
      const l = label(idx);
      if (seen.has(l)) continue;
      seen.add(l);
      total.set(l, (total.get(l) ?? 0) + 1);
    }
  }
  const rank = (m) =>
    [...m.entries()].sort((a, b) => b[1] - a[1]).map(([k, v]) => ({
      fn: k,
      samples: v,
      pctOfSamples: +((100 * v) / (cpu.samples?.length || 1)).toFixed(2),
    }));
  return { sampleCount: cpu.samples?.length ?? 0, self: rank(self), total: rank(total) };
}
