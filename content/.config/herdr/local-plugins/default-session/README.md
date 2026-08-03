# default-session

> A local herdr plugin that recreates my tmux startup habits

---

herdr has no config option for a startup layout, so this plugin builds one over
the socket API instead. It also picks up a few tmux keybindings that have no
built-in herdr equivalent.

## Install

```bash
herdr plugin link ~/.config/herdr/local-plugins/default-session
```

`herdr plugin list` should then show `default-session ... [local:...]`. Startup
hooks run when a **server** starts, so the layout appears on the next
`herdr` launch (not on client attach or config reload).

## What it does

On startup it builds every space that has nothing running in it, from
[`layout.json`](./layout.json) (a fresh session, or a restored one whose panes
all came back as bare shells (see [After a reboot](#after-a-reboot))):

| tab      | panes                                         | where           |
| -------- | --------------------------------------------- | --------------- |
| `shell`  | main shell, plus scratch/watch shells stacked | everywhere      |
| `agents` | `claude`, beside a spare pane for codex       | repo spaces     |
| `editor` | full screen `nvim`                            | everywhere      |
| `git`    | `lazygit` beside a git shell                  | repo spaces     |
| `review` | full screen `tuicr`                           | repo spaces     |
| `prs`    | full screen `ghzinga`, via `prs.sh`           | repo spaces     |
| `system` | `glances` stacked over `journalctl -f`        | `~` space only  |

The `~` space's main shell opens on a `fastfetch` banner; see
[the pane flags](#editing-the-layout) for why the repo spaces skip it.

That covers what the `mux` function in `~/.functions` set up under tmux.
`primary`, `editor`, and the logs window, with the repo-oriented TUIs added.

Every space created afterwards gets the same treatment through a
`workspace.created` event hook. Which tabs a space gets depends on whether it is
the primary (`~`) space:

- `primary_only` tabs are skipped everywhere else, so global monitors exist once
  rather than once per project. `system` is one.
- `secondary_only` tabs are skipped in the primary space. `agents`, `git`,
  `review`, and `prs` are all repo-oriented, and `~` is not a checkout, so the
  `~` space gets `shell`, `editor`, and `system` and nothing else.

Both flags also work on a single **pane**, where they scope its `run` rather
than the pane itself: the pane is still built in every space, just as a plain
shell. The `shell` tab's main pane uses that to greet the `~` space with
`fastfetch` without paying for it once per project space.

An explicit `apply` ignores both flags and builds the whole set.

Details worth knowing:

- Panes inherit the space's cwd, so launching herdr from a checkout gives every
  tab the right repo.
- Panes marked `requires_repo` (`lazygit`, `tuicr`, `ghzinga`, and the git
  shell) need a checkout. When the space is rooted somewhere that isn't one (such as `~`),
  they fall back to `default_repo` in `layout.json`. If that is also
  missing they print a hint instead of an error.
- Every `run` command falls back to an interactive shell when the program
  exits, so quitting nvim leaves a usable pane instead of a dead tab. A pane
  marked `oneshot` leans on that: `fastfetch` prints and hands the pane back
  right away, so the banner is scrollback above an ordinary prompt.
- The `prs` tab goes through [`prs.sh`](./prs.sh), which pins ghzinga to a
  session named after the repo. Left to itself ghzinga scores saved herdr pane
  ids as "strong" anchors and cwd or git remote as "weak", so a bare launch
  reopens whatever you last looked at in some other repo. The script opens the
  PR for the current branch, else the newest open PR, else the repo's own
  session.
- All splits are even. `prefix+=` puts them back that way after resizing.
- Tabs holding a running program or an agent are never rebuilt on startup, and
  neither are the spaces they live in.
- The startup hook waits for the root pane to finish sourcing rc files before
  deciding whether anything is running in it. Judging that on one sample reads a
  shell still loading `.bashrc` as busy.
- Startup and `workspace.created` take a short-lived claim on a space before
  building it, so they cannot both build the space a fresh session opens with.

## Actions

Bound in [`../../config.toml`](../../config.toml):

| action           | key                | tmux equivalent          |
| ---------------- | ------------------ | ------------------------ |
| `apply`          | `prefix+d`         | (none) build this layout |
| `rehydrate`      | `prefix+ctrl+d`    | `@resurrect-processes`   |
| `tab-move-left`  | `ctrl+shift+left`  | `swap-window -t -1`      |
| `tab-move-right` | `ctrl+shift+right` | `swap-window -t +1`      |
| `balance`        | `prefix+=`         | vim's `C-w =`            |
| `toggle-mouse`   | `prefix+m`         | `bind m` / `bind M`      |

`apply` replaces the current tab and appends the rest, so running it in a space
that already has tabs leaves those tabs in place ahead of the new ones. It
ignores `primary_only` and `secondary_only`, since asking for it explicitly
means you want the whole set.

`toggle-mouse` rewrites `ui.mouse_capture` in `~/.config/herdr/config.toml` and
reloads the server, so run `just sync-to-repo` if you want the flip kept.

## After a reboot

A restore brings back spaces, tabs, splits, and cwds, but every pane comes back
as a bare shell. herdr does not relaunch programs the way tmux-resurrect's
`@resurrect-processes` did. The startup hook fills that gap: every tab whose
panes are _all_ idle shells is rebuilt from its entry in `layout.json`, so nvim,
lazygit, glances, journalctl, tuicr, ghzinga, and claude come back where they
belong. That makes launching herdr the equivalent of
`@continuum-restore 'on'`.

The pass works a tab at a time, matching tabs to the layout by label. That
matters now that `agents` holds a claude: a resumed agent vetoes its own tab, but
the rest of the space still gets rebuilt. Vetoing space-wide would leave every
other tab a bare shell for the rest of the session. Tabs that aren't in
`layout.json` are left where they are, and a space with nothing in it at all
gets the whole layout instead.

Set `rehydrate_on_startup` false in `layout.json` to go back to only building
fresh sessions. `prefix+ctrl+d` runs the same pass by hand at any time.

Tabs are skipped by evidence, not by guess:

```text
~/shell: replayed 1 command(s) in place
product/shell: only shells, nothing to relaunch
~/editor: relaunching
product/agents: agent in w2:p5, leaving it alone
product/editor: something is running in w2:p7, leaving it alone
navi/notes: not in layout.json, leaving it alone
rehydrated 1 tab(s), built 0 space(s)
```

A tab whose layout starts no programs is skipped outright. `shell` is the only
one: a restore brings its panes back exactly as the layout would build them, so
there is nothing to relaunch, and every other tab is vetoed by the program
running in it. That left `shell` as the one tab rebuilt on every single startup.

`oneshot` panes are the exception that doesn't reopen that hole. `fastfetch`
prints and exits, so a restored `shell` tab is still "only shells" as far as
rebuilding goes — rebuilding it to get the banner back would throw away the cwds
the restore just recovered. Instead the command is typed into the shell already
sitting in the pane, over `pane.send_text`, and only when that pane settles to
an idle prompt. A pane you left something running in keeps it.

Replaying has to know the banner hasn't already printed, because the startup
hook and `workspace.created` both reach the `~` space on a fresh `herd`: one
builds it, and the other then finds a space that is no longer new. The tell is
in the pane itself. A pane built from the layout keeps the command it was
launched with, visible through `layout.export`; a pane brought back by a restore
has none, because `session.json` persists cwds and labels but never commands.
So a pane herdr started is left alone and a pane the restore left bare gets the
banner typed into it, which is the difference between greeting the space once
and greeting it twice.

Rebuilding is not free. `layout.apply` against an existing tab hands back a
_new_ tab id, so the `~` space came out of a `herd --reset` with `shell` sitting
on `w1:t9` while `agents` through `system` kept `t3`–`t8`, putting it last in
tab order rather than first. Repo spaces escaped it only by accident of timing:
`herd` creates them after the startup hook has taken its snapshot, so they are
not in the pass at all. Tabs that genuinely do get relaunched are now moved back
to the index they held.

Agent panes veto a rebuild on metadata alone, not on whether a process is up.
herdr persists `agent_session` refs so it can resume claude conversations, and a
pane waiting to be resumed looks exactly like an idle shell. Rebuilding it would
throw the conversation away. A pane with no saved session is just an idle shell,
so rehydrate starts `claude` there fresh.

## Resetting

`herd --reset` is the equivalent of deleting the tmux-resurrect directory: it
stops the server, moves `session.json` and `session-history.json` aside as
`.bak`, then builds everything from scratch. It refuses to run from inside a
herdr pane, since stopping the server would take that shell with it.

A fresh session has no spaces until a client attaches, which is after `herd`
creates its repo spaces, so `herd` makes the `~` space itself first, keeping it
the primary space and the one you land in.

Anything can also be driven by hand:

```bash
herdr plugin action invoke apply --plugin default-session
python3 session.py balance
```

## Editing the layout

`layout.json` is a BSP tree per tab:

- `{"type": "pane", "label": ..., "run": ..., "requires_repo": ..., "oneshot": ...}`
- `{"type": "split", "direction": ..., "ratio": ..., "first": ..., "second": ...}`
  where direction is `right` or `down` and ratio is between 0 and 1

Each tab also takes an optional `primary_only` or `secondary_only` flag, which
decide whether it lands in the `~` space, the repo spaces, or both. On a pane
the same flags scope its `run`, leaving the pane itself in every space.

`oneshot` marks a `run` that prints and exits rather than owning the pane. It
keeps the tab out of rehydrate's rebuild path and gets replayed into the
restored shell instead, which is what makes the `fastfetch` banner cheap.

`default_repo` at the top of the file is where `requires_repo` panes land when
the space itself isn't a checkout. `{plugin_root}` inside a `run` string expands
to this directory, which is how the `prs` tab finds `prs.sh`.

No restart needed. The file is read on each run, so `prefix+d` in a fresh
space is enough to see a change.

## Opening a space per repo

The `herd` function in `~/.functions` is the herdr version of `mux`: it starts
the server detached, opens a space per repo, then attaches. Spaces already open
are skipped, so it is safe to re-run.

```bash
herd                                          # $HERD_REPOS
herd --repos ~/Code/work/product ~/Code/oss/x # or an explicit list
herd --reset                                  # throw the saved session away first
herd --help                                   # flags and the default list
```

`HERD_REPOS` in `~/.functions` holds the default list; `~/.exports` or
`~/.environment` can override it, since both load after. Tab completion offers
the flags, then those repos plus directory completion after `--repos`.

Each new space triggers the `workspace.created` hook, so it arrives with tabs
already built, and `herd` puts focus back on the space you started in before
attaching. Note the cost: every project space starts its own `nvim`, `lazygit`,
`tuicr`, `ghzinga`, and `claude`. Marking more tabs `primary_only` trims that.

## Editing the plugin manifest

`plugins.json` caches the manifest, so re-link after changing
`herdr-plugin.toml`. New actions and event hooks stay invisible until then:

```bash
herdr plugin link ~/.config/herdr/local-plugins/default-session
```
