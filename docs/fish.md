# fish

`~/.config/fish` sets up fish next to bash. It works as an interactive
shell started from bash, a terminal, tmux, tuios, or herdr, and as the login
shell (`chsh -s /usr/bin/fish`).

## What is shared with bash

Both shells read one copy of each of these:

- Environment variables: `.exports` and the private `~/.environment`. Each
  interactive or login fish session sources them in bash and copies the
  resulting environment, `PATH` included (`conf.d/bash.fish`).
- Aliases: `.aliases`. fish turns each one into an abbreviation
  (`conf.d/abbreviations.fish`), so values must work in both shells. Names fish
  already defines, such as `path`, `ls`, and `grep`, are skipped. Bash-only
  aliases live in `.bashrc`.
- Commands: scripts in `~/.bin`, such as `update`, `mux`, `serve`, `sub`,
  `loop`, `ai`, and `aws-env`.

Each shell keeps its own version of the little that has to change the shell
itself: `stk` (which changes directory) and `aws-use` (which applies `aws-env`'s
variables), plus the prompt. `functions/fish_prompt.fish` mirrors
`.bash_prompt`, so edit both when changing one.

## Plugins

`fish_plugins` lists the plugins, pinned to release tags, for
[fisher](https://github.com/jorgebucaran/fisher) to install:

- [fzf.fish](https://github.com/PatrickF1/fzf.fish): fzf searches on
  `Ctrl+Alt+F` (files), `Ctrl+Alt+L` (git log), `Ctrl+Alt+S` (git status),
  `Ctrl+Alt+P` (processes), `Ctrl+V` (variables, replacing fish's paste), and
  `Ctrl+R` (history).
- [fifc](https://github.com/gazorby/fifc): completion in fzf on `Shift+Tab`,
  with fish's own candidates, previews, and colored paths from `fd`. Tab stays
  fish's own completion. `conf.d/plugins.fish` sets the key and `fifc_editor`;
  fifc reads its key from the universal `fifc_keybinding` as it loads.

`conf.d/plugins.fish` keeps the installed plugins in step with the list. The
first interactive shell without fisher downloads it, at the tag in
`fish_plugins`, and installs everything listed; after that, a changed
`fish_plugins` is applied by the next shell. Normal startups make no network
requests. To change plugins, edit `fish_plugins` and open a new shell, or run
`fisher install`/`fisher remove`, which rewrite the file, and sync it back to
the repo. Plugin files land in `~/.config/fish` but are not tracked here.

## Differences from bash

- History is fish's own, and is merged from other sessions before each prompt.
- A directory path typed on its own, such as `~`, changes to it.
- Globs do not match hidden files unless the pattern starts with `.`, and are
  case-sensitive. `**` recurses, as with bash's `globstar`.
- File completion leaves out hidden files unless the word starts with `.`, and
  does not color candidates by file type.
- There is no spelling correction for `cd`.
- The Ruby completions are bash-only. higharc's come from
  `~/.higharc/completion.fish`, which `higharc setup --shell fish` writes.

## As the login shell

Programs that run commands through `$SHELL` then use fish. Editors whose
plugins assume bash syntax should be pointed at bash, for example
`vim.o.shell = "bash"` in Neovim or `(setq shell-file-name "bash")` in Emacs.
