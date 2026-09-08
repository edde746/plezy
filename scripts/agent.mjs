#!/usr/bin/env bun
// Explicit host-side agent control. No device discovery, app launch, or adb changes.
import { randomUUID } from "node:crypto";
import { constants } from "node:fs";
import { open } from "node:fs/promises";
import { VM, VMError, sleep } from "./perf/vmclient.mjs";

const EXTENSION = "ext.plezy.agent";
const MAX_PAYLOAD_BYTES = 1024 * 1024;
const MAX_INPUT_BYTES = 768 * 1024;
const MAX_BINARY_BYTES = 512 * 1024;
const SCOPES = new Set([
  "app", "player", "server", "library", "profile", "catalog", "account",
  "syncRule", "liveTvFavorites", "dvrRule",
]);
const TARGET_FLAGS = {
  server: "serverId", item: "itemId", library: "libraryId", profile: "profileId",
  account: "accountId", rule: "ruleId", catalog: "catalogId", connection: "connectionId",
  channel: "channelId", dvr: "dvrId",
};
const STAGES = new Set([
  "accepted", "resolving", "opening", "ready", "playing", "paused", "buffering",
  "completed", "failed", "cancelled", "blocked", "externalLaunched", "stopped",
]);
const COMMAND_FLAGS = {
  "app.status": ["wait"],
  "settings.list": ["scope", "scope-json", ...Object.keys(TARGET_FLAGS)],
  "settings.get": ["scope", "scope-json", ...Object.keys(TARGET_FLAGS)],
  "settings.set": ["scope", "scope-json", ...Object.keys(TARGET_FLAGS), "file", "text-file", "base64-file", "value-field", "value-json"],
  "settings.reset": ["scope", "scope-json", ...Object.keys(TARGET_FLAGS)],
  "settings.apply": ["scope", "scope-json", ...Object.keys(TARGET_FLAGS), "file"],
  "media.servers": [],
  "media.search": ["server", "query", "limit", "offset", "type", "target-kind"],
  "media.get": ["server", "item", "target-kind", "offline"],
  "media.children": ["server", "item", "limit", "offset"],
  "playback.start": ["server", "item", "target-kind", "start", "from-start", "position-ms", "media-index", "media-source-id", "offline", "wait"],
  "playback.status": ["operation", "wait"],
  "playback.stop": ["operation", "wait"],
};
const GLOBAL_FLAGS = ["uri", "timeout-ms", "poll-ms", "help"];
const BOOLEAN_FLAGS = new Set(["help", "from-start", "offline"]);
const ALL_FLAGS = new Set([...GLOBAL_FLAGS, ...Object.values(COMMAND_FLAGS).flat()]);

export const HELP = {
  usage: "bun scripts/agent.mjs [--uri VM_URI] <group> <command> [arguments] [options]",
  commands: [
    "app status [--wait [ready]]",
    "settings list [scope options]",
    "settings get KEY [scope options]",
    "settings set KEY JSON [scope options]",
    "settings set KEY --file FILE|- [scope options]",
    "settings set KEY --text-file FILE|- [--value-field PATH] [--value-json JSON] [scope options]",
    "settings set KEY --base64-file FILE [--value-field PATH] [--value-json JSON] [scope options]",
    "settings reset KEY [scope options]",
    "settings apply --file FILE|- [scope options]",
    "media servers",
    "media search --server ID --query TEXT [--limit N] [--offset N] [--type TYPE] [--target-kind channel]",
    "media get --server ID --item ID [--target-kind channel] [--offline]",
    "media children --server ID --item ID [--limit N] [--offset N]",
    "playback start --server ID --item ID [--target-kind KIND] [--from-start|--start beginning|resume] [--position-ms N] [--media-index N] [--media-source-id ID] [--offline] [--wait [playing|ready|STAGE]]",
    "playback status [--operation ID] [--wait [playing|ready|STAGE]]",
    "playback stop [--operation ID] [--wait [stopped]]",
  ],
  connection: "Explicit --uri or PLEZY_VM_SERVICE_URI is required. Supply a host-reachable authenticated VM URI; no adb forwarding or app/device selection is performed.",
  build: "flutter run -d DEVICE --dart-define=PLEZY_AGENT_CONTROL=true (debug/profile only; never release)",
  maestro: "python3 scripts/maestro/run_maestro.py basic --device DEVICE --agent-control",
  scope: {
    types: [...SCOPES],
    options: "--scope TYPE (default app), --server/--item/--library/--profile/--account/--rule/--catalog/--connection/--channel/--dvr ID. --scope-json JSON is exclusive with scope flags; it supports advanced fields such as player persistence.",
    discovery: "Use settings list --scope TYPE to discover keys and target scopes. Resource writes require the complete target scope returned by discovery.",
  },
  input: {
    json: "Values are JSON, parsed exactly once; string values require JSON quotes. With no value/file, settings set/apply reads JSON stdin. --file - explicitly selects stdin.",
    batch: "An array of {key,value,scope?,reset?:false} or {key,scope?,reset:true}; wire arguments are {changes:[...]}. At most 100 changes, validated before any write, then applied in order; not atomic.",
    files: "--text-file transfers UTF-8 content, --base64-file transfers explicit binary bytes as base64. --value-field is a dotted domain-object path; --value-json supplies other domain fields. Use --file for a complete JSON domain value. Host paths are never interpreted as device paths.",
    limits: { payloadBytes: MAX_PAYLOAD_BYTES, inputBytes: MAX_INPUT_BYTES, binaryBytes: MAX_BINARY_BYTES },
    shaderExample: "bun scripts/agent.mjs settings set custom_shaders --base64-file shader.glsl --value-field import.base64 --value-json '{\"import\":{\"fileName\":\"shader.glsl\",\"name\":\"Agent shader\"}}'",
    mpvExample: "bun scripts/agent.mjs settings set mpv_config_text --text-file mpv.conf",
    start: "start is beginning or resume; positionMs overrides either policy, including explicit zero. --from-start translates to beginning and is exclusive with other position options.",
  },
  timing: "--timeout-ms N bounds the entire invocation (default 30000, maximum 600000), including input/connect/discovery/requests/wait. --poll-ms N defaults to 200. Mutations are never retried. Timeout/disconnect may occur after a mutation executed; inspect requestId/operationId/latestStatus before deciding what to do next.",
  output: "One JSON object on stdout; safe diagnostics on stderr. Failed requests, disconnects, timeouts and failed waits exit nonzero. Waits are tied to the observed operation and profile session; ready does not mean audible output.",
};

export class AgentCliError extends Error {
  constructor(code, message, details) {
    super(message);
    this.name = "AgentCliError";
    this.code = code;
    this.details = details;
  }
}

function invalid(message) {
  throw new AgentCliError("invalidArguments", message);
}

function json(text) {
  try {
    const value = JSON.parse(text);
    const finite = (item) => {
      if (typeof item === "number" && !Number.isFinite(item)) invalid("JSON numbers must be finite.");
      if (item && typeof item === "object") Object.values(item).forEach(finite);
    };
    finite(value);
    return value;
  } catch (error) {
    if (error instanceof AgentCliError) throw error;
    invalid("Input must be valid JSON; string values need JSON quotes.");
  }
}

function isObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function integer(value, name, minimum, maximum = Number.MAX_SAFE_INTEGER) {
  if (!/^\d+$/.test(value ?? "")) invalid(`${name} must be an integer.`);
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < minimum || number > maximum) {
    invalid(`${name} is outside its supported range.`);
  }
  return number;
}

export function parseArguments(argv, environment = process.env) {
  const flags = {};
  const positional = [];
  for (let index = 0; index < argv.length; index++) {
    const token = argv[index];
    if (token === "--") {
      positional.push(...argv.slice(index + 1));
      break;
    }
    if (token === "-h") {
      flags.help = true;
      continue;
    }
    if (!token.startsWith("--")) {
      positional.push(token);
      continue;
    }
    const equal = token.indexOf("=");
    const name = token.slice(2, equal < 0 ? undefined : equal);
    if (!ALL_FLAGS.has(name)) invalid("Unknown option; use --help to see supported flags.");
    if (Object.hasOwn(flags, name)) invalid("Options must not be repeated.");
    if (BOOLEAN_FLAGS.has(name)) {
      if (equal >= 0) invalid("Boolean options do not accept a value.");
      flags[name] = true;
    } else if (name === "wait" && equal < 0 && (!argv[index + 1] || argv[index + 1].startsWith("--"))) {
      flags.wait = true;
    } else {
      const value = equal >= 0 ? token.slice(equal + 1) : argv[++index];
      if (!value || value.startsWith("--")) invalid("An option is missing its value.");
      flags[name] = value;
    }
  }
  if (flags.help || positional.length === 0) return { help: true };
  const command = `${positional.shift()}.${positional.shift()}`;
  const allowed = COMMAND_FLAGS[command];
  if (!allowed) invalid("Unknown command; use --help to see supported commands.");
  if (Object.keys(flags).some((name) => !GLOBAL_FLAGS.includes(name) && !allowed.includes(name))) {
    invalid("An option is not supported by this command.");
  }
  const uri = flags.uri ?? environment.PLEZY_VM_SERVICE_URI;
  if (!uri) invalid("Supply --uri or PLEZY_VM_SERVICE_URI; no endpoint is selected automatically.");
  const timeoutMs = flags["timeout-ms"] === undefined ? 30000 : integer(flags["timeout-ms"], "timeout-ms", 1, 600000);
  const pollMs = flags["poll-ms"] === undefined ? 200 : integer(flags["poll-ms"], "poll-ms", 10, 5000);
  let waitStage = flags.wait;
  if (waitStage === true) {
    waitStage = command === "app.status" ? "ready" : command === "playback.stop" ? "stopped" : "playing";
  }
  if (waitStage && (command === "app.status" ? waitStage !== "ready" : !STAGES.has(waitStage))) {
    invalid("Unsupported wait stage.");
  }
  if (command === "playback.stop" && waitStage && waitStage !== "stopped") {
    invalid("playback stop can only wait for stopped.");
  }
  return { command, flags, positional, uri, timeoutMs, pollMs, waitStage };
}

function scopeFrom(flags) {
  const targeted = flags.scope !== undefined || Object.keys(TARGET_FLAGS).some((flag) => flags[flag] !== undefined);
  if (flags["scope-json"] !== undefined) {
    if (targeted) invalid("--scope-json cannot be combined with scope target flags.");
    const scope = json(flags["scope-json"]);
    if (!isObject(scope) || !SCOPES.has(scope.type)) invalid("Scope must be an object with a supported type.");
    if (scope.type === "app" && Object.keys(scope).length !== 1) invalid("App scope does not accept target IDs; choose an explicit target scope.");
    return scope;
  }
  const scope = { type: flags.scope ?? "app" };
  if (!SCOPES.has(scope.type)) invalid("Unsupported scope type.");
  for (const [flag, field] of Object.entries(TARGET_FLAGS)) {
    if (flags[flag] !== undefined) scope[field] = flags[flag];
  }
  if (scope.type === "app" && Object.keys(scope).length !== 1) invalid("Target IDs require a non-app --scope.");
  return scope;
}

function remaining(deadline) {
  const ms = deadline - performance.now();
  if (ms <= 0) throw new AgentCliError("timeout", "The command deadline expired; a mutation may have executed.");
  return ms;
}

async function readStdin(deadline, limit) {
  if (process.stdin.isTTY) invalid("Provide a JSON value, an explicit file, or piped stdin.");
  return await new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    const finish = (error) => {
      clearTimeout(timer);
      process.stdin.off("data", onData);
      process.stdin.off("end", onEnd);
      process.stdin.off("error", onError);
      process.stdin.pause();
      error ? reject(error) : resolve(Buffer.concat(chunks, size));
    };
    const onData = (chunk) => {
      size += chunk.length;
      if (size > limit) finish(new AgentCliError("inputTooLarge", "Input exceeds the supported byte limit."));
      else chunks.push(chunk);
    };
    const onEnd = () => finish();
    const onError = () => finish(new AgentCliError("inputFailed", "Could not read stdin."));
    const timer = setTimeout(() => finish(new AgentCliError("timeout", "Reading stdin timed out.")), remaining(deadline));
    process.stdin.on("data", onData);
    process.stdin.once("end", onEnd);
    process.stdin.once("error", onError);
    process.stdin.resume();
  });
}

async function readInput(path, deadline, limit) {
  if (path === "-") return readStdin(deadline, limit);
  let file;
  try {
    file = await open(path, constants.O_RDONLY | constants.O_NONBLOCK);
    const stat = await file.stat();
    if (!stat.isFile()) invalid("Input must be a regular file or explicit stdin (-).");
    if (stat.size > limit) throw new AgentCliError("inputTooLarge", "Input exceeds the supported byte limit.");
    const bytes = Buffer.alloc(Math.min(stat.size + 1, limit + 1));
    let size = 0;
    while (size < bytes.length) {
      remaining(deadline);
      const result = await file.read(bytes, size, bytes.length - size);
      if (result.bytesRead === 0) break;
      size += result.bytesRead;
    }
    if (size > stat.size) throw new AgentCliError("inputChanged", "Input changed while being read; retry with a stable file.");
    return bytes.subarray(0, size);
  } catch (error) {
    if (error instanceof AgentCliError) throw error;
    throw new AgentCliError("inputFailed", "Could not read the input file.");
  } finally {
    await file?.close();
  }
}

function utf8(bytes) {
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
  } catch {
    invalid("Text input must be valid UTF-8; use --base64-file for binary content.");
  }
}

async function settingValue(parsed, deadline) {
  const { flags, positional } = parsed;
  const modes = ["file", "text-file", "base64-file"].filter((flag) => flags[flag] !== undefined);
  if (modes.length > 1 || (modes.length && positional.length)) invalid("Choose one value input source.");
  if (positional.length > 1) invalid("A setting value must be one JSON argument.");
  const mode = modes[0] ?? "file";
  if (mode === "base64-file" && flags[mode] === "-") invalid("Binary input requires an explicit regular file.");
  let value;
  if (positional.length) {
    if (Buffer.byteLength(positional[0]) > MAX_INPUT_BYTES) invalid("JSON input exceeds the supported byte limit.");
    value = json(positional[0]);
  } else {
    const bytes = await readInput(flags[mode] ?? "-", deadline, mode === "base64-file" ? MAX_BINARY_BYTES : MAX_INPUT_BYTES);
    value = mode === "base64-file" ? bytes.toString("base64") : mode === "text-file" ? utf8(bytes) : json(utf8(bytes));
  }
  if (flags["value-json"] !== undefined && flags["value-field"] === undefined) {
    invalid("--value-json requires --value-field to locate the input in the domain object.");
  }
  if (flags["value-field"] !== undefined) {
    const document = flags["value-json"] === undefined ? {} : json(flags["value-json"]);
    if (!isObject(document)) invalid("--value-json must be a domain object.");
    const path = flags["value-field"].split(".");
    if (path.some((key) => !key || ["__proto__", "constructor", "prototype"].includes(key))) {
      invalid("--value-field must be a safe dotted object path.");
    }
    let target = document;
    for (const key of path.slice(0, -1)) {
      if (!Object.hasOwn(target, key)) target[key] = {};
      if (!isObject(target[key])) invalid("--value-field must traverse objects, not scalar values or arrays.");
      target = target[key];
    }
    const key = path.at(-1);
    if (Object.hasOwn(target, key)) invalid("--value-field would overwrite an existing domain value.");
    target[key] = value;
    value = document;
  }
  return value;
}

export async function commandArguments(parsed, deadline) {
  const { command, flags, positional } = parsed;
  const args = {};
  if (command.startsWith("settings.")) {
    const scope = scopeFrom(flags);
    if (["settings.get", "settings.set", "settings.reset"].includes(command)) {
      args.key = positional.shift();
      if (!args.key?.trim()) invalid("A setting key is required.");
    }
    if (command === "settings.set") args.value = await settingValue(parsed, deadline);
    else if (command === "settings.apply") {
      const changes = await settingValue(parsed, deadline);
      if (!Array.isArray(changes) || changes.length === 0 || changes.length > 100) {
        invalid("A settings batch must be an array of 1 to 100 changes.");
      }
      args.changes = changes.map((change) => {
        if (!isObject(change) || typeof change.key !== "string" || !change.key.trim() ||
            Object.keys(change).some((key) => !["key", "value", "scope", "reset"].includes(key)) ||
            (change.reset !== undefined && typeof change.reset !== "boolean") ||
            (change.reset === true ? Object.hasOwn(change, "value") : !Object.hasOwn(change, "value"))) {
          invalid("Each change needs a key and either a value or reset:true, with an optional scope.");
        }
        const target = change.scope ?? scope;
        if (!isObject(target) || !SCOPES.has(target.type)) invalid("Each change scope needs a supported type.");
        if (target.type === "app" && Object.keys(target).length !== 1) invalid("App-scoped changes cannot include target IDs.");
        return { ...change, scope: target };
      });
      return args;
    } else if (positional.length) invalid("Unexpected positional arguments.");
    args.scope = scope;
    return args;
  }
  if (positional.length) invalid("Unexpected positional arguments.");
  const fieldFlags = {
    server: "serverId", item: "itemId", query: "query", type: "type", "target-kind": "targetKind",
    start: "start", "media-source-id": "mediaSourceId", operation: "operationId",
  };
  for (const [flag, field] of Object.entries(fieldFlags)) {
    if (flags[flag] !== undefined) args[field] = flags[flag];
  }
  for (const [flag, field] of [["position-ms", "positionMs"], ["media-index", "mediaIndex"], ["limit", "limit"], ["offset", "offset"]]) {
    if (flags[flag] !== undefined) args[field] = integer(flags[flag], flag, flag === "limit" ? 1 : 0);
  }
  if (flags.offline) args.offline = true;
  if (flags["from-start"]) {
    if (flags.start || flags["position-ms"] !== undefined) invalid("--from-start cannot be combined with another start policy.");
    args.start = "beginning";
  }
  if (args.start && !["beginning", "resume"].includes(args.start)) invalid("Start must be beginning or resume.");
  if (["media.search", "media.get", "media.children", "playback.start"].includes(command) && !args.serverId?.trim()) {
    invalid("An explicit --server is required.");
  }
  if (["media.get", "media.children", "playback.start"].includes(command) && !args.itemId?.trim()) {
    invalid("An explicit --item is required.");
  }
  if (command === "media.search" && !args.query?.trim()) invalid("media search requires --query.");
  return args;
}

function reached(status, stage) {
  if (stage === "ready") return status.stage === "ready" || status.stage === "playing" || status.ready === true;
  return status.stage === stage;
}

function checkLaunchFailure(status) {
  if (["failed", "cancelled", "blocked"].includes(status?.stage)) {
    throw new AgentCliError(status.stage === "failed" ? "playbackFailed" : status.stage, "Playback did not complete the requested operation.");
  }
}

export async function runCli(argv, environment = process.env) {
  let vm;
  let requestId = randomUUID();
  let sessionToken = null;
  let responseSessionToken;
  let latestStatus;
  let operationId;
  let mutationRequestId;
  try {
    const parsed = parseArguments(argv, environment);
    if (parsed.help) return { exitCode: 0, output: { help: HELP } };
    const deadline = performance.now() + parsed.timeoutMs;
    const args = await commandArguments(parsed, deadline);
    vm = await VM.connect(parsed.uri, {
      timeoutMs: Math.min(10000, remaining(deadline)),
      maxMessageBytes: 8 * MAX_PAYLOAD_BYTES,
    });
    const isolateId = await vm.isolateWithExtension(EXTENSION, { timeoutMs: remaining(deadline) });
    const invoke = async (command, arguments_, { mutation = false } = {}) => {
      requestId = randomUUID();
      const payload = JSON.stringify({ version: 1, requestId, command, arguments: arguments_, sessionToken });
      if (Buffer.byteLength(payload) > MAX_PAYLOAD_BYTES) {
        throw new AgentCliError("inputTooLarge", "The encoded request exceeds the 1 MiB payload limit.");
      }
      if (mutation) mutationRequestId = requestId;
      const response = await vm.call(EXTENSION, { isolateId, payload }, { timeoutMs: remaining(deadline) });
      if (!isObject(response) || response.version !== 1 || response.requestId !== requestId ||
          typeof response.ok !== "boolean" || !(response.sessionToken === null || typeof response.sessionToken === "string")) {
        throw new AgentCliError("invalidResponse", "The agent returned an invalid or uncorrelated response.");
      }
      responseSessionToken = response.sessionToken;
      if (!response.ok) {
        // Only the app's typed, payload-safe agent envelope is forwarded, never VM exceptions.
        if (!isObject(response.error) || typeof response.error.code !== "string" || typeof response.error.message !== "string") {
          throw new AgentCliError("invalidResponse", "The agent returned an invalid error response.");
        }
        throw new AgentCliError(response.error.code, response.error.message, response.error.details);
      }
      if (!Object.hasOwn(response, "result")) throw new AgentCliError("invalidResponse", "The agent response has no result.");
      if ((command === "app.status" || command.startsWith("playback.")) && !isObject(response.result)) {
        throw new AgentCliError("invalidResponse", "The agent returned an invalid status object.");
      }
      return response;
    };
    const mutation = ["settings.set", "settings.reset", "settings.apply", "playback.start", "playback.stop"].includes(parsed.command);
    if (mutation) {
      const handshake = await invoke("app.status", {});
      sessionToken = handshake.sessionToken;
    }
    if (parsed.command === "playback.stop" && args.operationId) {
      const current = await invoke("playback.status", {});
      if (current.sessionToken !== sessionToken) throw new AgentCliError("sessionChanged", "The profile session changed before stop.");
      latestStatus = current.result;
      if (args.operationId && current.result?.operationId !== args.operationId) {
        throw new AgentCliError("operationChanged", "The current playback operation differs from the requested one.");
      }
      operationId = current.result?.operationId;
      if (operationId) args.operationId = operationId;
    }
    let response = await invoke(parsed.command, args, { mutation });
    const initialRequestId = response.requestId;
    if (mutation && parsed.command.startsWith("playback.") && response.sessionToken !== sessionToken) {
      latestStatus = response.result;
      operationId = response.result.operationId;
      throw new AgentCliError("sessionChanged", "The profile session changed during the playback mutation.");
    }
    sessionToken = response.sessionToken;
    if (parsed.command.startsWith("playback.")) {
      latestStatus = response.result;
      if (args.operationId && response.result?.operationId !== args.operationId) {
        throw new AgentCliError("operationChanged", "The response belongs to another playback operation.");
      }
      operationId ??= response.result?.operationId;
      if (parsed.command !== "playback.status") checkLaunchFailure(response.result);
    }
    if (!parsed.waitStage) return { exitCode: 0, output: response };
    if (parsed.command.startsWith("playback.") && !operationId && response.result?.stage !== "stopped") {
      throw new AgentCliError("noPlaybackOperation", "There is no playback operation to wait for.");
    }
    while (true) {
      latestStatus = response.result;
      if (parsed.command === "app.status") {
        if (response.result?.profileReady === true) break;
      } else {
        if (operationId && response.result?.operationId !== operationId) {
          throw new AgentCliError("operationChanged", "Playback changed while waiting; the new operation cannot satisfy this request.");
        }
        checkLaunchFailure(response.result);
        if (response.result?.stage === parsed.waitStage) break;
        if (["externalLaunched", "completed", "stopped"].includes(response.result?.stage)) {
          throw new AgentCliError("waitUnsatisfied", "Playback ended or handed off before the requested state was observed.");
        }
        if (reached(response.result, parsed.waitStage)) break;
      }
      await sleep(Math.min(parsed.pollMs, remaining(deadline)));
      remaining(deadline);
      response = await invoke(parsed.command === "app.status" ? "app.status" : "playback.status", operationId ? { operationId } : {});
      latestStatus = response.result;
      if (parsed.command !== "app.status" && response.sessionToken !== sessionToken) {
        throw new AgentCliError("sessionChanged", "The profile session changed while waiting.");
      }
      if (parsed.command === "app.status") sessionToken = response.sessionToken;
    }
    return {
      exitCode: 0,
      output: { ...response, requestId: initialRequestId, result: { ...response.result, wait: { stage: parsed.waitStage, statusRequestId: response.requestId } } },
    };
  } catch (error) {
    const safe = error instanceof AgentCliError || error instanceof VMError;
    const code = safe ? error.code : "clientError";
    const message = safe ? error.message : "The client could not complete the command.";
    return {
      exitCode: 1,
      diagnostic: `${code}: ${message}`,
      output: {
        version: 1, requestId: mutationRequestId ?? requestId,
        sessionToken: responseSessionToken === undefined ? sessionToken : responseSessionToken, ok: false,
        error: {
          code, message,
          details: {
            ...(safe && isObject(error.details) ? error.details : {}),
            ...(mutationRequestId ? { mutationRequestId, mutationMayHaveExecuted: true } : {}),
            ...(operationId ? { operationId } : {}),
            ...(latestStatus !== undefined ? { latestStatus } : {}),
          },
        },
      },
    };
  } finally {
    vm?.close();
  }
}

if (import.meta.main) {
  const result = await runCli(process.argv.slice(2));
  process.stdout.write(`${JSON.stringify(result.output)}\n`);
  if (result.diagnostic) process.stderr.write(`${result.diagnostic}\n`);
  process.exitCode = result.exitCode;
}
