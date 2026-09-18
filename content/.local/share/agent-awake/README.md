# Activity-based sleep inhibition

Keeps Linux awake while OpenCode or Claude Code is working, rather than for the entire lifetime of an open terminal. Uses Python's standard library and `systemd-inhibit`; no always-running service, npm package, or sudo access is needed at runtime.

## Install on Fedora

```bash
sudo dnf install python3 systemd
```

From the dotfiles repository root:

```bash
python3 content/.local/share/agent-awake/install.py
```

The installer:

- Copies the helper to `~/.local/share/agent-awake/agent_awake.py`.
- Copies the auto-loaded plugin to `~/.config/opencode/plugins/agent-awake.js`.
- Merges only the Agent Awake hooks into `~/.claude/settings.json`, retaining other hooks, permissions, model choices, and plugin settings.
- Makes timestamped backups of files it replaces. Re-running it does not duplicate hooks.

Quit and restart **both OpenCode and Claude Code**. No `opencode.jsonc` entry is needed. Alternatively, the normal dotfiles sync installs these files too, but syncing the whole Claude settings file replaces local preferences; the dedicated installer is preferable for an existing setup.

Designed against OpenCode 1.18.31 and Claude Code 2.1.272. Older clients may lack some of the events. Non-Linux systems and `AGENT_AWAKE_DISABLE=1` skip inhibition.

## Behavior

| State | Behavior |
| --- | --- |
| OpenCode busy or retrying | Acquire a lease; refresh every 30 seconds |
| OpenCode permission/question pending | Release that session's lease until all pending requests are answered |
| OpenCode idle, error, deleted, or instance disposed | Release the corresponding leases |
| Claude prompt, tool activity, or compaction | Acquire/refresh the actor's lease |
| Claude permission request, question tool, plan approval, or MCP elicitation | Release the actor's lease |
| Claude turn finished, failed, or session ended | Release the corresponding leases |
| Claude subagent starts/stops | Separate lease per subagent; a waiting parent delegates inhibition to its subagents |
| Owning agent process exits or crashes | Release within roughly half a second |

Sessions have independent leases, so one session finishing cannot release another session's inhibitor. PID plus process-start time prevents accidentally following a reused PID. Prompt text, tool arguments, and transcripts are not stored.

Each lease runs a short watchdog **inside** `systemd-inhibit --what=idle:sleep --mode=block`. Stopping a lease ends that watchdog and releases the lock. Missing dependencies or authorization failures do not block agent tool calls.

The inhibitor covers idle and sleep requests, not screen brightness or a screen saver. Desktop integration varies: verify automatic suspend on your Fedora/KDE setup. Explicit forced suspend can bypass inhibitors. When the agent runs over SSH, inhibition applies to the Linux host running it, not the laptop displaying the terminal.

## Boundaries and fallback cleanup

- **Claude permission approval gap:** the documented hooks do not provide an immediate approval-completed event. After `PermissionRequest`, inhibition resumes on `PostToolUse`/`PostToolUseFailure` or the next activity hook. A long newly approved tool can therefore run without an inhibitor. This integration never auto-approves permissions to work around that gap.
- Claude interrupt/cancel paths do not all emit `Stop`. Notification hooks provide additional cleanup, but a missed event can leave a lease until expiry. An actor's lease expires after **two hours without an activity hook**. A single Claude tool or model call longer than that can lose protection. Set `AGENT_AWAKE_TTL` to a larger number of seconds before launching the client if needed.
- OpenCode renews leases while its status is busy, including long tools. Multiple pending questions/permissions are tracked separately. Background shell jobs are not independently tracked after the agent turn finishes; use `systemd-inhibit` around a deliberately detached long-running job if needed.
- Claude lifecycle hooks are best-effort around parallel tools and third-party hooks that block completion. A later tool event can reactivate a lease while a different tool waits for input; a blocked `Stop` may briefly release it until the next activity event.
- Claude process discovery supports the native `claude` executable and the standard `@anthropic-ai/claude-code` Node installation. An unrecognized wrapper fails open with a diagnostic rather than attaching to an unrelated shell.

## Verify and troubleshoot

While an agent is working:

```bash
systemd-inhibit --list
python3 ~/.local/share/agent-awake/agent_awake.py status
```

Look for **Agent Awake (opencode)** or **Agent Awake (claude)** with `idle:sleep` in the systemd list. The helper status lists requested leases and watchdog process liveness; **the systemd list is the authoritative check that the lock was acquired**. After a normal finished turn, the corresponding entry should disappear within about half a second. Check again while a permission/question dialog is waiting.

If a lease has `worker_alive: false`, inspect `$XDG_RUNTIME_DIR/agent-awake/inhibit.log` (usually `/run/user/$UID/agent-awake/inhibit.log`). This contains systemd acquisition errors, for example a missing binary or a logind/polkit denial. Do not run the agents as root to work around a denial.

For a short real inhibitor smoke test without an AI request:

```bash
AGENT_AWAKE_TTL=10 python3 ~/.local/share/agent-awake/agent_awake.py opencode on smoke-test "$$"
systemd-inhibit --list
python3 ~/.local/share/agent-awake/agent_awake.py opencode off smoke-test "$$"
```

The helper starts asynchronously; give it a moment before checking. Test that KDE's automatic suspend respects the inhibitor separately; unit tests cannot verify desktop power policy.

To release all Agent Awake leases immediately:

```bash
python3 ~/.local/share/agent-awake/agent_awake.py clear
```

Active clients can reacquire them on their next event or heartbeat. To disable for a session, set the environment variable before launching it:

```bash
AGENT_AWAKE_DISABLE=1 opencode
AGENT_AWAKE_DISABLE=1 claude
```

To uninstall, remove `~/.config/opencode/plugins/agent-awake.js` and only the Claude hook handlers whose command references `agent_awake.py`. Restart both clients, run `clear`, then remove the helper. Existing hooks unrelated to Agent Awake should remain.

## Development checks

From the repository root:

```bash
python3 -m unittest discover -s tests/agent_awake -p 'test_*.py'
node --test tests/agent_awake/plugin.test.mjs
```

References: [OpenCode plugins](https://opencode.ai/docs/plugins/) and [Claude Code hooks](https://code.claude.com/docs/en/hooks).
