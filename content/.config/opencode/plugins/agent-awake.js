import { execFile } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

const exec = promisify(execFile);

export default async function AgentAwake({ client }) {
  if (process.platform !== "linux" || process.env.AGENT_AWAKE_DISABLE === "1") return {};
  const helper = join(homedir(), ".local/share/agent-awake/agent_awake.py");
  const sessions = new Map();
  let queue = Promise.resolve();
  let warned = false;

  async function send(id, active) {
    try {
      await exec("python3", [helper, "opencode", active ? "on" : "off", id, String(process.pid)], {
        timeout: 3000,
      });
    } catch {
      if (!warned) {
        warned = true;
        await client.app.log({ body: { service: "agent-awake", level: "warn",
          message: "Sleep inhibitor helper unavailable; check installation." } }).catch(() => {});
      }
    }
  }

  // Serialize timers and bus callbacks so an older refresh cannot undo a stop.
  function enqueue(fn) {
    queue = queue.then(fn).catch(() => {});
    return queue;
  }

  const timer = setInterval(() => enqueue(async () => {
    for (const [id, state] of sessions) {
      if (state.busy && state.waiting.size === 0) await send(id, true);
    }
  }), 30000);
  timer.unref();

  return {
    event: ({ event }) => enqueue(async () => {
      const p = event.properties ?? {};
      if (event.type === "server.instance.disposed") {
        clearInterval(timer);
        for (const id of sessions.keys()) await send(id, false);
        sessions.clear();
        return;
      }
      const id = p.sessionID ?? (event.type === "session.deleted" ? p.info?.id : undefined);
      if (!id) return;
      if (["session.idle", "session.error", "session.deleted"].includes(event.type)
          || (event.type === "session.status" && p.status?.type === "idle")) {
        sessions.delete(id);
        await send(id, false);
        return;
      }
      const state = sessions.get(id) ?? { busy: false, waiting: new Set() };
      if (event.type === "session.status") {
        state.busy = ["busy", "retry"].includes(p.status?.type);
      } else if (["permission.asked", "question.asked"].includes(event.type)) {
        state.waiting.add(p.id);
      } else if (["permission.replied", "question.replied", "question.rejected"].includes(event.type)) {
        state.waiting.delete(p.requestID);
      } else {
        return;
      }
      sessions.set(id, state);
      await send(id, state.busy && state.waiting.size === 0);
    }),
  };
}
