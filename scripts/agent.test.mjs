import { afterEach, expect, test } from "bun:test";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runCli } from "./agent.mjs";
import { VM, vmWebSocketUrl } from "./perf/vmclient.mjs";

const servers = [];
const directories = [];
const HOLD = Symbol("no response");
const SESSION = "profile-session-a";
const TARGET = { serverId: "server-a", itemId: "item-a" };

function endpoint(handler, { advertised = true, rpc } = {}) {
  const commands = [];
  const server = Bun.serve({
    hostname: "127.0.0.1",
    port: 0,
    fetch(request, server) {
      if (server.upgrade(request)) return;
      return new Response(null, { status: 400 });
    },
    websocket: {
      message(socket, data) {
        const message = JSON.parse(String(data));
        let result;
        if (rpc) result = rpc(message, socket);
        if (result === undefined && message.method === "getVM") {
          result = { isolates: [{ id: "isolates/main", name: "main" }, { id: "isolates/ui", name: "other" }] };
        } else if (result === undefined && message.method === "getIsolate") {
          result = { extensionRPCs: advertised && message.params.isolateId === "isolates/ui" ? ["ext.plezy.agent"] : [] };
        } else if (result === undefined && message.method === "ext.plezy.agent") {
          const request = JSON.parse(message.params.payload);
          commands.push(request);
          if (message.params.isolateId !== "isolates/ui") {
            result = { version: 1, requestId: request.requestId, sessionToken: SESSION, ok: false, error: { code: "wrongIsolate", message: "Wrong isolate." } };
          } else {
            const value = handler?.(request, socket);
            if (value === HOLD) return;
            result = {
              version: 1, requestId: request.requestId, sessionToken: SESSION, ok: true,
              result: value ?? { profileReady: true },
            };
          }
        }
        if (result !== HOLD) socket.send(JSON.stringify({ jsonrpc: "2.0", id: message.id, result }));
      },
    },
  });
  servers.push(server);
  return { uri: `http://127.0.0.1:${server.port}/private-auth-token/`, commands };
}

function invoke(host, ...args) {
  return runCli(["--uri", host.uri, "--timeout-ms", "1500", "--poll-ms", "10", ...args], {});
}

function start(host, ...args) {
  return invoke(host, "playback", "start", "--server", TARGET.serverId, "--item", TARGET.itemId, ...args);
}

afterEach(async () => {
  for (const server of servers.splice(0)) server.stop(true);
  for (const directory of directories.splice(0)) await rm(directory, { recursive: true, force: true });
});

test("VM endpoint normalization preserves auth/query and does not append a second ws path", () => {
  expect(vmWebSocketUrl("https://localhost:4321/auth%2Fvalue/?q=token"))
    .toBe("wss://localhost:4321/auth%2Fvalue/ws?q=token");
  expect(vmWebSocketUrl("ws://localhost:4321/auth/ws/"))
    .toBe("ws://localhost:4321/auth/ws");
});

test("agent discovery uses the advertising isolate rather than a named main isolate", async () => {
  const host = endpoint();
  const result = await invoke(host, "app", "status");
  expect(result.exitCode).toBe(0);
  expect(result.output.result.profileReady).toBe(true);
});

test("missing opt-in never falls back to an available isolate", async () => {
  const host = endpoint(undefined, { advertised: false });
  const result = await runCli(["--uri", host.uri, "--timeout-ms", "100", "app", "status"], {});
  expect(result.exitCode).toBe(1);
  expect(host.commands).toEqual([]);
  expect(JSON.stringify(result)).not.toContain("private-auth-token");
});

test("disconnect rejects outstanding VM calls instead of leaving the request timer alive", async () => {
  const host = endpoint(undefined, {
    rpc(message, socket) {
      if (message.method === "slowCall") {
        socket.close(1000, "sensitive disconnect reason");
        return HOLD;
      }
    },
  });
  const vm = await VM.connect(host.uri);
  try {
    await expect(vm.call("slowCall", {}, { timeoutMs: 60000 })).rejects.toMatchObject({ code: "disconnected" });
    await expect(vm.call("getVM")).rejects.toMatchObject({ code: "disconnected" });
  } finally {
    vm.close();
  }
}, 1500);

test("a disconnected mutation is never retried and reports its request identity without transport secrets", async () => {
  let writes = 0;
  const host = endpoint((request, socket) => {
    if (request.command === "settings.set") {
      writes++;
      socket.close(1000, "private-auth-token raw provider error");
      return HOLD;
    }
  });
  const result = await invoke(host, "settings", "set", "enable_hardware_decoding", "false");
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("disconnected");
  expect(writes).toBe(1);
  const mutation = host.commands.find((request) => request.command === "settings.set");
  expect(mutation.sessionToken).toBe(SESSION);
  expect(result.output.requestId).toBe(mutation.requestId);
  expect(result.output.error.details.mutationMayHaveExecuted).toBe(true);
  expect(JSON.stringify(result)).not.toContain("private-auth-token");
  expect(JSON.stringify(result)).not.toContain("raw provider error");
});

test("malformed transport JSON becomes a safe command failure", async () => {
  const host = endpoint(undefined, {
    rpc(message, socket) {
      socket.send("private-auth-token invalid JSON");
      return HOLD;
    },
  });
  const result = await invoke(host, "app", "status");
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("invalidResponse");
  expect(JSON.stringify(result)).not.toContain("private-auth-token");
});

test("playing events for a later operation cannot satisfy a launch wait", async () => {
  const host = endpoint((request) => {
    if (request.command === "playback.start") return { operationId: "launch-a", stage: "accepted", item: TARGET };
    if (request.command === "playback.status") return { operationId: "launch-b", stage: "playing", playing: true, item: TARGET };
  });
  const result = await start(host, "--from-start", "--wait", "playing");
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("operationChanged");
  expect(result.output.error.details.operationId).toBe("launch-a");
});

test("unscoped stop waits for current playback even after an older operation lost ownership", async () => {
  let activeSession = "music";
  const previous = { operationId: "launch-a", stage: "cancelled", playing: false, item: TARGET };
  const host = endpoint((request) => {
    if (request.command === "playback.status") return { ...previous, activeSession };
    if (request.command === "playback.stop") {
      if (request.arguments.operationId) return { ...previous, activeSession };
      activeSession = null;
      return { ...previous, stage: "stopped", activeSession };
    }
  });
  const scoped = await invoke(host, "playback", "stop", "--operation", "launch-a", "--wait");
  expect(scoped.exitCode).toBe(1);
  expect(activeSession).toBe("music");
  const unscoped = await invoke(host, "playback", "stop", "--wait");
  expect(unscoped.exitCode).toBe(0);
  expect(unscoped.output.result.stage).toBe("stopped");
  expect(activeSession).toBeNull();
});

test("an accepted or merely ready launch does not satisfy a playing wait", async () => {
  const stages = ["opening", "ready", "playing"];
  const host = endpoint((request) => {
    if (request.command === "playback.start") return { operationId: "launch-a", stage: "accepted", item: TARGET };
    if (request.command === "playback.status") {
      const stage = stages.shift() ?? "playing";
      return { operationId: "launch-a", stage, playing: stage === "playing", item: TARGET };
    }
  });
  const result = await start(host, "--wait", "playing");
  expect(result.exitCode).toBe(0);
  expect(result.output.result.stage).toBe("playing");
  expect(result.output.result.operationId).toBe("launch-a");
  expect(result.output.requestId).toBe(host.commands.find((request) => request.command === "playback.start").requestId);
});

test("completed playback cannot satisfy ready from a retained first-frame latch", async () => {
  const host = endpoint((request) => {
    if (request.command === "playback.status") {
      return { operationId: "launch-a", stage: "completed", ready: true, playing: false, item: TARGET };
    }
  });
  const ready = await invoke(host, "playback", "status", "--operation", "launch-a", "--wait", "ready");
  expect(ready.exitCode).toBe(1);
  expect(ready.output.error.code).toBe("waitUnsatisfied");
  const completed = await invoke(host, "playback", "status", "--operation", "launch-a", "--wait", "completed");
  expect(completed.exitCode).toBe(0);
  expect(completed.output.result.stage).toBe("completed");
});

test("wait timeout keeps the accepted launch and latest status without retrying start", async () => {
  const host = endpoint((request) => {
    if (request.command === "playback.start") return { operationId: "launch-a", stage: "accepted", item: TARGET };
    if (request.command === "playback.status") return { operationId: "launch-a", stage: "opening", playing: false, item: TARGET };
  });
  const result = await runCli([
    "--uri", host.uri, "--timeout-ms", "150", "--poll-ms", "10", "playback", "start",
    "--server", TARGET.serverId, "--item", TARGET.itemId, "--wait", "playing",
  ], {});
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("timeout");
  expect(result.output.error.details.operationId).toBe("launch-a");
  expect(result.output.error.details.latestStatus.stage).toBe("opening");
  expect(host.commands.filter((request) => request.command === "playback.start")).toHaveLength(1);
});

test("profile-session changes invalidate a correlated operation wait", async () => {
  const host = endpoint((request) => {
    if (request.command === "playback.start") return { operationId: "launch-a", stage: "accepted", item: TARGET };
  }, {
    rpc(message) {
      if (message.method !== "ext.plezy.agent") return;
      const request = JSON.parse(message.params.payload);
      if (request.command === "playback.status") {
        return {
          version: 1, requestId: request.requestId, sessionToken: "profile-session-b", ok: true,
          result: { operationId: "launch-a", stage: "playing", playing: true, item: TARGET },
        };
      }
    },
  });
  const result = await start(host, "--wait", "playing");
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("sessionChanged");
});

test("invalid batch input causes no mutation, including a contradictory reset and value", async () => {
  const host = endpoint();
  const result = await invoke(host, "settings", "apply", JSON.stringify([
    { key: "enable_hardware_decoding", value: false },
    { key: "theme_mode", reset: true, value: "dark" },
  ]));
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("invalidArguments");
  expect(host.commands).toEqual([]);
});

test("oversized binary resources are rejected before invoking the app", async () => {
  const host = endpoint();
  const directory = await mkdtemp(join(tmpdir(), "plezy-agent-"));
  directories.push(directory);
  const path = join(directory, "shader.glsl");
  await writeFile(path, Buffer.alloc(512 * 1024 + 1));
  const result = await invoke(host, "settings", "set", "custom_shaders", "--base64-file", path,
    "--value-field", "import.base64", "--value-json", '{"import":{"fileName":"shader.glsl","name":"Shader"}}');
  expect(result.exitCode).toBe(1);
  expect(result.output.error.code).toBe("inputTooLarge");
  expect(host.commands).toEqual([]);
});
