# fish

`content/.config/fish` sets up fish next to bash. It works as an interactive
shell started from bash, a terminal, tmux, tuios, or herdr, and as the login
shell (`chsh -s /usr/bin/fish`).

## What is shared with bash

`conf.d/bash.fish` keeps one copy of these in the bash dotfiles:

- Environment variables: each interactive or login fish session sources
  `~/.functions`, `~/.exports`, and the private `~/.environment` in bash and
  copies the resulting environment, `PATH` included.
- Functions that do not change the calling shell (`update`, `mux`, and the
  media and file helpers) run in bash through thin fish wrappers.

Anything that changes the shell itself has a fish version in `functions/`:
`notes`, `stk`, `loop`, `ai`, and the `aws-*` helpers. Aliases are in
`conf.d/abbreviations.fish`, and the prompt in `functions/fish_prompt.fish`
mirrors `.bash_prompt`. Edit both versions when changing one of these.

## Differences from bash

- History is fish's own, and is merged from other sessions before each prompt.
- `..`, `...`, and so on expand to `cd ../..` style commands. A directory path
  typed on its own, such as `~`, changes to it.
- Globs do not match hidden files unless the pattern starts with `.`, and are
  case-sensitive. `**` recurses, as with bash's `globstar`.
- There is no spelling correction for `cd`.
- The higharc and Ruby completions are bash-only.

## As the login shell

Programs that run commands through `$SHELL` then use fish. Editors whose
plugins assume bash syntax should be pointed at bash, for example
`vim.o.shell = "bash"` in Neovim or `(setq shell-file-name "bash")` in Emacs.
