# AI agents

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
/audit docs packages/sdk/ — focus on examples; skip generated API docs
/audit help
```

Both commands accept `help`, `--help`, or `-h` to print usage without starting a
review. Audit starts read-only; finalize applies requested edits chunk by chunk.

Claude Code discovers both skills under `~/.claude/skills/`. OpenCode reads the
same skills through thin commands in `~/.config/opencode/commands/`.
Sync the skill and command files with `just sync-to-home`, then restart OpenCode.
Claude Code reloads skill changes; restart it if a command is not listed.

To install without the dotfiles sync tool, copy only these directories and files
from `content/` into your home directory:

| Source under `content/` | Destination | Used by |
| --- | --- | --- |
| `.claude/skills/finalize/` | `~/.claude/skills/finalize/` | Both harnesses |
| `.claude/skills/audit/` | `~/.claude/skills/audit/` | Both harnesses |
| `.config/opencode/commands/finalize.md` | `~/.config/opencode/commands/finalize.md` | OpenCode |
| `.config/opencode/commands/audit.md` | `~/.config/opencode/commands/audit.md` | OpenCode |

The command files load the shared skill definitions; there is no second copy of
the workflow to maintain. OpenCode must have access to external Claude skills,
or the wrapper must be allowed to read the shared file at its fallback path.
After installation, try `/finalize help` and `/audit help` in each harness, then
`/finalize docs README.md` to check argument handling and the one-chunk pause;
reply `stop` to return to normal conversation.

The `pr` scope reviews a PR/MR description using an available forge CLI, MCP,
or tool such as git-stk, with pasted text or a draft as a fallback. Publishing
description edits and rewriting commit messages require explicit direction.

These skills guide the agent rather than enforce a review state machine; completing
a review covers the selected material and reported checks, not a guarantee of correctness.

## Keep the machine awake while agents work

[Agent Awake](../content/.local/share/agent-awake/README.md) integrates OpenCode lifecycle events and Claude Code hooks with Linux sleep inhibitors. It releases leases when turns finish or need input, with crash cleanup and independent leases for concurrent sessions.

Install the helper and integrations without replacing unrelated live Claude settings:

```bash
python3 content/.local/share/agent-awake/install.py
```

Restart both clients afterward. See the linked guide for Fedora dependencies, verification, uninstall steps, and Claude's permission-approval timing limitation.
