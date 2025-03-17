#!/usr/bin/env bash

# bashrc
#
# bash settings
# --------

# load dotfiles

files=(
  ~/.aliases
  ~/.exports
  ~/.functions
  ~/.git_prompt
  ~/.environment # placed last for precedence
)

for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    # shellcheck disable=SC1090
    source "$file"
  fi
done

# bash options

options=(
  histappend
  cdspell
  globstar
  dotglob
  cmdhist
  dirspell
  nocaseglob
)

for option in "${options[@]}"; do
  shopt -s "$option"
done

bind "set show-all-if-ambiguous on"

# command not found handler (relies on PackageKit-command-not-found)
# copied from /etc/profile.d/PackageKit.sh
command_not_found_handle() {
  local runcnf=1
  local retval=127

  # only search for the command if we're interactive
  [[ $- == *"i"* ]] || runcnf=0

  # don't run if DBus isn't running
  [[ ! -S /run/dbus/system_bus_socket ]] && runcnf=0

  # don't run if packagekitd doesn't exist in the _system_ root
  [[ ! -x '/usr/libexec/packagekitd' ]] && runcnf=0

  # don't run if bash command completion is being run
  [[ -n ${COMP_CWORD-} ]] && runcnf=0

  # don't run if we've been uninstalled since the shell was launched
  [[ ! -x '/usr/libexec/pk-command-not-found' ]] && runcnf=0

  # run the command, or just print a warning
  if [ $runcnf -eq 1 ]; then
    '/usr/libexec/pk-command-not-found' "$@"
    retval=$?
  elif [[ -n "${BASH_VERSION-}" ]]; then
    printf >&2 'bash: %s%s\n' "${1:+$1: }" "$(gettext PackageKit 'command not found')"
  fi

  # return success or failure
  return $retval
}

# bash completion

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    source "/usr/share/bash-completion/bash_completion"
  fi
fi

# git completion

if [ -f /usr/share/bash-completion/completions/git ]; then
  source "/usr/share/bash-completion/completions/git"
  __git_complete g __git_main
fi

# autojump

if [ -f /usr/share/autojump/autojump.bash ]; then
  # shellcheck disable=SC1091
  source "/usr/share/autojump/autojump.bash"
fi

if [ -f "$HOME/.autojump/etc/profile.d/autojump.sh" ]; then
  source "$HOME/.autojump/etc/profile.d/autojump.sh"
fi

# keychain

if keychain &> /dev/null && [ -f "$HOME/.ssh/id_ed25519" ]; then
  eval "$(keychain --eval id_ed25519 --quiet)"
fi

# pyenv

eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# nodenv

eval "$(nodenv init -)"

# rbenv

eval "$(rbenv init - --no-rehash bash)"

# ruby completion

if [ -f ~/Code/oss/completion-ruby/completion-ruby-all ]; then
  source "$HOME/Code/oss/completion-ruby/completion-ruby-all"
fi

# rust

if [ -f ~/.cargo/env ]; then
  # shellcheck disable=SC1091
  source "$HOME/.cargo/env"
fi

# load bash prompt

if [ -f ~/.bash_prompt ]; then
  source "$HOME/.bash_prompt"

  PROMPT_COMMAND="set_prompt; autojump_add_to_database; history -a; history -c; history -r"
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.config/emacs/bin:$PATH"
