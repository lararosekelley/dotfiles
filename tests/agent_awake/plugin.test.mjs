import { test } from "node:test";
import assert from "node:assert/strict";
import util from "node:util";
import { syncBuiltinESMExports } from "node:module";
import { readFile } from "node:fs/promises";

test("OpenCode leases follow activity, pending requests, sessions and disposal", async (t) => {
  const calls = [];
  t.mock.method(util, "promisify", () => async (command, args) => {
    calls.push(args.slice(2, 4)); // action, session
    return { stdout: "", stderr: "" };
  });
  syncBuiltinESMExports();
  let heartbeat;
  t.mock.method(globalThis, "setInterval", (fn) => {
    heartbeat = fn;
    return { unref() {} };
  });
  t.mock.method(globalThis, "clearInterval", () => {});
  const source = await readFile(new URL(
    "../../content/.config/opencode/plugins/agent-awake.js", import.meta.url), "utf8");
  const { default: plugin } = await import(`data:text/javascript;base64,${Buffer.from(source).toString("base64")}`);
  const hooks = await plugin({ client: { app: { log: async () => {} } } });
  const event = (type, properties) => hooks.event({ event: { type, properties } });
  const last = () => calls.at(-1);
  await event("session.status", { sessionID: "a", status: { type: "busy" } });
  assert.deepEqual(last(), ["on", "a"]);
  await event("permission.asked", { sessionID: "a", id: "p1" });
  await event("question.asked", { sessionID: "a", id: "q1" });
  await event("permission.replied", { sessionID: "a", requestID: "p1" });
  assert.deepEqual(last(), ["off", "a"]);
  await event("session.status", { sessionID: "a", status: { type: "busy" } });
  assert.deepEqual(last(), ["off", "a"]);
  const before = calls.length;
  await heartbeat();
  assert.equal(calls.length, before);
  await event("question.replied", { sessionID: "a", requestID: "q1" });
  assert.deepEqual(last(), ["on", "a"]);
  await event("session.status", { sessionID: "b", status: { type: "retry" } });
  await event("session.idle", { sessionID: "a" });
  await heartbeat();
  assert.deepEqual(last(), ["on", "b"]);
  await event("session.error", { sessionID: "b" });
  const stopped = calls.length;
  await heartbeat();
  assert.equal(calls.length, stopped);
  await event("session.status", { sessionID: "c", status: { type: "busy" } });
  await event("session.deleted", { info: { id: "c" } });
  assert.deepEqual(last(), ["off", "c"]);
  await event("session.status", { sessionID: "d", status: { type: "busy" } });
  await event("server.instance.disposed", {});
  assert.deepEqual(last(), ["off", "d"]);
  t.mock.restoreAll();
  syncBuiltinESMExports();
});
