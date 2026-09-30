# AI agents

## Shared global rules

`content/.config/opencode/AGENTS.md` is the shared source for global agent rules.
OpenCode loads it directly; `content/.claude/CLAUDE.md` imports it using Claude
Code's native file-import syntax. The relative import works in both `content/`
and the home directory. Edit the shared file rather than duplicating rules.

Sync both files with `just sync-to-home` and restart both harnesses. In Claude
Code, use `/context` to check the loaded memory files. The rules require explicit
confirmation before commits, pushes, and PR/MR comments or replies, and favor
short messages with plain text and ASCII punctuation. These are agent instructions,
not tool-level permission enforcement.

The repository's root [AGENTS.md](../AGENTS.md) covers dotfiles layout, sync
behavior, and checks. Root `CLAUDE.md` imports those project instructions; the
files under `content/` supply personal rules across repositories.

## OpenCode appearance

`content/.config/opencode/tui.json` sets the Catppuccin theme. OpenCode merges
`tui.json` followed by `tui.jsonc` in the same directory. The herdr installer owns
the local `tui.jsonc` plugin registration and `herdr-tui-session.js`; keep those
generated integration files out of the synced payload. See the
[herdr setup guide](./herdr.md) to install the integration. Restart OpenCode after
changing its TUI configuration.

## Interactive reviews and audits

The shared [finalize skill](../content/.claude/skills/finalize/SKILL.md) walks through
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

The shared [audit skill](../content/.claude/skills/audit/SKILL.md) assesses older or
larger work, including merged changes, and presents a short findings list before
you choose what to inspect or fix. It accepts a lens, an optional folder or Git
reference, and plain-language scope guidance:

```text
/audit docs
/audit docs content/.config/herdr/
/audit comments src/
/audit 'recent changes to the feature flag system'
/audit docs packages/sdk/ - focus on examples; skip generated API docs
/audit 'my agent configuration'
/audit help
```

Audit starts read-only; finalize applies requested edits chunk by chunk. Audit can
also check agent configurations for conflicting rules, stale references, loading
behavior, and context overhead. It distinguishes estimates from harness measurements.

The `pr` scope reviews a PR/MR description using an available forge CLI, MCP,
or tool such as git-stk, with pasted text or a draft as a fallback. Publishing
description edits and rewriting commit messages require explicit direction.

## Understanding and improving workflows

| Command | Purpose |
| --- | --- |
| [`/how`](../content/.claude/skills/how/SKILL.md) | Trace current code behavior with source references |
| [`/why`](../content/.claude/skills/why/SKILL.md) | Investigate historical rationale, separating evidence from inference |
| [`/teach`](../content/.claude/skills/teach/SKILL.md) | Explain a concept through a mental model and worked example |
| [`/reflect`](../content/.claude/skills/reflect/SKILL.md) | Propose up to three durable instruction changes for approval |
| [`/handoff`](../content/.claude/skills/handoff/SKILL.md) | Save or inspect private, cross-harness task context |
| [`/discuss`](../content/.claude/skills/discuss/SKILL.md) | Settle a plan through short rounds of informed questions |
| [`/verify`](../content/.claude/skills/verify/SKILL.md) | Run existing project checks and report what they establish |

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
Sync the skill and command files with `just sync-to-home`, then restart OpenCode.
Claude Code reloads skill changes; restart it if a command is not listed.

To install without the dotfiles sync tool, copy only these directories and files
from `content/` into your home directory:

| Source under `content/` | Destination | Used by |
| --- | --- | --- |
| `.claude/skills/<name>/` | `~/.claude/skills/<name>/` | Both harnesses |
| `.config/opencode/commands/<name>.md` | `~/.config/opencode/commands/<name>.md` | OpenCode |

Use `finalize`, `audit`, `how`, `why`, `teach`, `reflect`, `handoff`, `discuss`, and
`verify` as names.
Each skill is self-contained; install only the ones you want.

On Claude Code versions with a bundled `/verify`, installing this personal skill
replaces that command. Use the project-local `/verify-git-stk` name for the git-stk
recipe when working in its checkout.

The command files load the shared skill definitions; there is no second copy of
the workflow to maintain. OpenCode must have access to external Claude skills,
or the wrapper must be allowed to read the shared file at its fallback path.
After installation, try `/finalize help` and `/audit help` in each harness, then
`/finalize docs README.md` to check argument handling and the one-chunk pause;
reply `stop` to return to normal conversation.

These skills guide the agent rather than enforce a review state machine; completing
a review covers the selected material and reported checks, not a guarantee of correctness.

## Keep the machine awake while agents work

[Agent Awake](./agent-awake.md) integrates OpenCode lifecycle events and Claude Code
hooks with Linux sleep inhibitors. See its guide for installation, verification,
uninstall steps, and lifecycle limitations.
