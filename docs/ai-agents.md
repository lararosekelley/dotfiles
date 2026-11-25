# AI agents

## Shared global rules

`~/.config/opencode/AGENTS.md` is the shared source for global agent rules.
OpenCode loads it directly; `~/.claude/CLAUDE.md` imports it using Claude Code's
native file-import syntax. In the repo they are
`home/dot_config/opencode/AGENTS.md` and `home/dot_claude/CLAUDE.md`, and the
relative import works in both places. Edit the shared file rather than duplicating rules.

Codex reads `~/.codex/AGENTS.md`. Link it to the shared file once: `ln -s ../.config/opencode/AGENTS.md ~/.codex/AGENTS.md`.

Install both files with `chezmoi apply` and restart both harnesses. In Claude
Code, use `/context` to check the loaded memory files. The rules require explicit
confirmation before commits, pushes, and PR/MR comments or replies, and favor
short messages with plain text and ASCII punctuation. These are agent instructions,
not tool-level permission enforcement.

The repository's root [AGENTS.md](../AGENTS.md) covers dotfiles layout, sync
behavior, and checks. Root `CLAUDE.md` imports those project instructions; the
files under `home/` supply personal rules across repositories.

## OpenCode appearance

`~/.config/opencode/tui.json` sets the Callie theme, from
`~/.config/opencode/themes/callie.json`, a copy of
[greylocklabs/themes](https://github.com/greylocklabs/themes)' `ports/opencode/callie.json`. OpenCode merges
`tui.json` followed by `tui.jsonc` in the same directory. The herdr installer owns
the local `tui.jsonc` plugin registration and `herdr-tui-session.js`; keep those
generated integration files out of the synced payload. See the
[herdr config's README](https://github.com/lararosekelley/herdr) to install the integration. Restart OpenCode after
changing its TUI configuration.

## Codex

`~/.codex/config.toml` gives Codex the same MCP servers as Claude Code's
`~/.claude/.mcp.json` and OpenCode's `opencode.jsonc`; add a server to all
three. Sign in to the remote ones once with `codex mcp login <name>`. GitHub's
server uses the same pre-registered OAuth app as Claude Code. Codex also writes
project trust and notices into this file, so copy it back with `chezmoi re-add`.

Codex colors code blocks and diffs with the Callie theme in `~/.codex/themes`,
copies of [greylocklabs/themes](https://github.com/greylocklabs/themes)'
`ports/tmtheme`. `/theme` switches to Callie Light.

## Interactive reviews and audits

The shared [finalize skill](../home/dot_claude/skills/finalize/SKILL.md) walks through
current work one chunk at a time, applying keep/edit/remove decisions as you go.
It prioritizes relevant uncommitted changes and active branch commits.

```text
/finalize
/finalize code
/finalize comments
/finalize docs
/finalize commits
/finalize pr
/finalize help
```

The shared [audit skill](../home/dot_claude/skills/audit/SKILL.md) assesses older or
larger work, including merged changes, and presents a short findings list before
you choose what to inspect or fix. It accepts a lens, an optional folder or Git
reference, and plain-language scope guidance:

```text
/audit docs
/audit docs home/dot_config/private_fish/
/audit comments src/
/audit 'recent changes to the feature flag system'
/audit docs packages/sdk/ - focus on examples; skip generated API docs
/audit 'my agent configuration'
/audit help
```

Audit starts read-only; finalize applies requested edits chunk by chunk. Audit can
also check agent configurations for conflicting rules, stale references, loading
behavior, and context overhead. It distinguishes estimates from harness measurements.

The shared [reword skill](../home/dot_claude/skills/reword/SKILL.md) walks through
a repository's user-facing text, such as UI strings, CLI help, website pages, store
listings, release notes, and docs, so you can replace the wording with your own.
It lists text surfaces first, shows text as written, and updates tests that pin
the old wording. Use finalize for current diffs and audit for documentation accuracy.

```text
/reword
/reword app
/reword www/index.html
/reword help
```

The `pr` scope of finalize and audit reviews a PR/MR description using an
available forge CLI, MCP, or tool such as git-stk, with pasted text or a draft as
a fallback. Publishing
description edits and rewriting commit messages require explicit direction.

## Understanding and improving workflows

| Command | Purpose |
| --- | --- |
| [`/how`](../home/dot_claude/skills/how/SKILL.md) | Trace current code behavior with source references |
| [`/why`](../home/dot_claude/skills/why/SKILL.md) | Investigate historical rationale, separating evidence from inference |
| [`/teach`](../home/dot_claude/skills/teach/SKILL.md) | Explain a concept through a mental model and worked example |
| [`/reflect`](../home/dot_claude/skills/reflect/SKILL.md) | Propose up to three durable instruction changes for approval |
| [`/handoff`](../home/dot_claude/skills/handoff/SKILL.md) | Save or inspect private, cross-harness task context |
| [`/discuss`](../home/dot_claude/skills/discuss/SKILL.md) | Settle a plan through short rounds of informed questions |
| [`/verify`](../home/dot_claude/skills/verify/SKILL.md) | Run existing project checks and report what they establish |

```text
/how does sync select files?
/why does sync discover paths from the repo in both directions?
/teach worktrees step by step, assume I know branches
/reflect the repeated corrections during review
/handoff save finish the sync tests
/handoff resume /path/to/handoff.md
/discuss whether this CLI needs a daemon
/verify the worktree cleanup change
```

How, why, and teach stay read-only. Teach gives a compact explanation by default;
"step by step" pauses after each concept. Reflect starts from the current
conversation and waits for approval before editing instructions. It does not
automatically mine other chats, file issues, or launch reviewer panels.

Handoff writes a short Markdown note under `$XDG_STATE_HOME/agent-handoffs/`
(default `~/.local/state/agent-handoffs/`), using private directory/file permissions.
Keep this state out of dotfiles sync and version control. Resume requires the
explicit file path, checks the checkout state, and proposes the next action without
automatically executing it. A note does not transfer uncommitted code or approval
to publish; use the same checkout or supply changes separately.

Discuss inspects before asking and recommends an answer to each question. It
stays read-only until implementation is explicitly requested. Verify reuses local
test recipes and project-specific verification guides; it does not automatically
fix failures or run live-provider tests. Keep exact project commands in that
project rather than duplicating them in this shared skill.

## Installing the shared commands

All nine commands accept `help`, `--help`, or `-h` before doing any work. `stop`
returns to normal conversation with completed edits preserved. They follow the
user's existing permission and delegation rules.

Claude Code discovers the skills under `~/.claude/skills/`. OpenCode reads the
same skills through thin commands in `~/.config/opencode/commands/`.
Install the skill and command files with `chezmoi apply`, then restart OpenCode.
Claude Code reloads skill changes; restart it if a command is not listed.

To install without chezmoi, copy only these directories and files from `home/`
into your home directory:

| Source under `home/` | Destination | Used by |
| --- | --- | --- |
| `dot_claude/skills/<name>/` | `~/.claude/skills/<name>/` | Both harnesses |
| `dot_config/opencode/commands/<name>.md` | `~/.config/opencode/commands/<name>.md` | OpenCode |

Use `finalize`, `audit`, `how`, `why`, `teach`, `reflect`, `handoff`, `discuss`,
`verify`, and `reword` as names.
Each skill is self-contained; install only the ones you want.

On Claude Code versions with a bundled `/verify`, installing this personal skill
replaces that command. Use the project-local `/verify-git-stk` name for the git-stk
recipe when working in its checkout.

The command files load the shared skill definitions; there is no second copy of
the workflow to maintain. OpenCode must have access to external Claude skills,
or the wrapper must be allowed to read the shared file at its fallback path.
After installation, try `/finalize help`, `/audit help`, and `/reword help` in each
harness, then `/finalize docs README.md` to check argument handling and the one-chunk pause;
reply `stop` to return to normal conversation.

These skills guide the agent rather than enforce a review state machine; completing
a review covers the selected material and reported checks, not a guarantee of correctness.

## Keep the machine awake while agents work

[Agent Awake](./agent-awake.md) integrates OpenCode lifecycle events and Claude Code
hooks with Linux sleep inhibitors. See its guide for installation, verification,
uninstall steps, and lifecycle limitations.
