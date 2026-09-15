// Host-only Dart VM Service client, shared by agent controls and profiling.
// Measurement helpers below are not shipped or referenced by lib/.

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

/** Transport errors deliberately exclude endpoint URLs and VM error payloads. */
export class VMError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "VMError";
    this.code = code;
  }
}

export function vmWebSocketUrl(uri) {
  try {
    const url = new URL(uri);
    if (!["http:", "https:", "ws:", "wss:"].includes(url.protocol)) throw new Error();
    if (url.username || url.password || url.hash) throw new Error();
    url.protocol = url.protocol === "https:" || url.protocol === "wss:" ? "wss:" : "ws:";
    const path = url.pathname.replace(/\/+$/, "");
    url.pathname = path.endsWith("/ws") ? path : `${path}/ws`;
    return url.toString();
  } catch {
    throw new VMError("invalidUri", "Supply a valid HTTP(S) or WS(S) VM service URI.");
  }
}

export class VM {
  constructor(ws, { callTimeoutMs = 120000, maxMessageBytes = Infinity } = {}) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    this.callTimeoutMs = callTimeoutMs;
    this.maxMessageBytes = maxMessageBytes;
    this.closed = false;
    ws.addEventListener("message", (event) => {
      if (this.closed) return;
      let msg;
      try {
        if (typeof event.data !== "string" ||
            Buffer.byteLength(event.data) > this.maxMessageBytes) throw new Error();
        msg = JSON.parse(event.data);
        if (!msg || typeof msg !== "object" || Array.isArray(msg)) throw new Error();
      } catch {
        this.close(new VMError("invalidResponse", "The VM service returned an invalid response."));
        return;
      }
      const pending = this.pending.get(msg.id);
      if (!pending) return; // Events and late replies to timed-out reads.
      this.pending.delete(msg.id);
      clearTimeout(pending.timer);
      if (msg.error) {
        pending.reject(new VMError("rpcError", "The VM service rejected the request."));
      } else if (!Object.hasOwn(msg, "result")) {
        pending.reject(new VMError("invalidResponse", "The VM service response has no result."));
      } else {
        pending.resolve(msg.result);
      }
    });
    ws.addEventListener("close", () => this.close());
    ws.addEventListener("error", () => this.close());
  }

  static async connect(uri, { timeoutMs = 10000, ...options } = {}) {
    const url = vmWebSocketUrl(uri);
    let ws;
    try {
      ws = new WebSocket(url);
    } catch {
      throw new VMError("connectionFailed", "Could not connect to the VM service.");
    }
    const vm = new VM(ws, options);
    await new Promise((resolve, reject) => {
      const finish = (error) => {
        clearTimeout(timer);
        ws.removeEventListener("open", onOpen);
        ws.removeEventListener("error", onError);
        ws.removeEventListener("close", onError);
        if (error) {
          vm.close(error);
          reject(error);
        } else {
          resolve();
        }
      };
      const onOpen = () => finish();
      const onError = () => finish(new VMError("connectionFailed", "Could not connect to the VM service."));
      const timer = setTimeout(
        () => finish(new VMError("timeout", "Connecting to the VM service timed out.")),
        timeoutMs,
      );
      ws.addEventListener("open", onOpen);
      ws.addEventListener("error", onError);
      ws.addEventListener("close", onError);
    });
    return vm;
  }

  call(method, params = {}, { timeoutMs = this.callTimeoutMs } = {}) {
    if (this.closed || this.ws.readyState !== 1) {
      return Promise.reject(new VMError("disconnected", "The VM service disconnected."));
    }
    const id = ++this.id;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new VMError("timeout", "The VM service request timed out; it may have executed."));
      }, timeoutMs);
      this.pending.set(id, { resolve, reject, timer });
      try {
        this.ws.send(JSON.stringify({ jsonrpc: "2.0", id, method, params }));
      } catch {
        this.close();
      }
    });
  }

  close(error = new VMError("disconnected", "The VM service disconnected.")) {
    if (this.closed) return;
    this.closed = true;
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer);
      pending.reject(error);
    }
    this.pending.clear();
    try {
      if (typeof this.ws.terminate === "function") this.ws.terminate();
      else this.ws.close();
    } catch {
      // The socket may already have closed during a send.
    }
  }

  /** Preserved for profiling consumers; agent commands use extension discovery. */
  async uiIsolate() {
    const vm = await this.call("getVM");
    const named = vm.isolates.find((i) => i.name === "main" || /main/i.test(i.name));
    const isolate = named ?? vm.isolates[0];
    if (!isolate) throw new VMError("isolateUnavailable", "No VM isolate is available.");
    return isolate.id;
  }

  /** Wait for registration, never choosing an isolate without the extension. */
  async isolateWithExtension(extension, { timeoutMs = 10000, pollIntervalMs = 100 } = {}) {
    const deadline = performance.now() + timeoutMs;
    const remaining = () => {
      const ms = deadline - performance.now();
      if (ms <= 0) {
        throw new VMError("extensionUnavailable", "No isolate advertises the requested extension; check the opt-in build.");
      }
      return ms;
    };
    while (true) {
      const vm = await this.call("getVM", {}, { timeoutMs: remaining() });
      if (!Array.isArray(vm?.isolates)) {
        throw new VMError("invalidResponse", "The VM service returned an invalid isolate list.");
      }
      const matches = [];
      for (const ref of vm.isolates) {
        if (typeof ref.id !== "string") continue;
        const isolate = await this.call("getIsolate", { isolateId: ref.id }, { timeoutMs: remaining() });
        if (isolate?.extensionRPCs?.includes(extension)) matches.push(ref.id);
      }
      if (matches.length > 1) {
        throw new VMError("ambiguousIsolate", "More than one isolate advertises the requested extension.");
      }
      if (matches.length === 1) return matches[0];
      await sleep(Math.min(pollIntervalMs, remaining()));
    }
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
