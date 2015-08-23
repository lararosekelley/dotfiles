# zshrc
# ----------

# zsh settings
ZSH_THEME="steeef"
DISABLE_AUTO_TITLE="true"

unsetopt autocd

plugins=(
    vagrant
    go
    git
    rails
    ruby
    python
    web-search
    brew
    bower
    encode64
    gem
    gradle
    jsontools
    last-working-dir
    node
    npm
    osx
    perl
    pep8
    pip
    sudo
)

# my files
files=(
    ~/.aliases
    ~/.env
    ~/.functions
)

for file in ${files[@]}; do
    if [ -f "$file" ]; then
        source $file
    fi
done

source $ZSH/oh-my-zsh.sh

# rbenv
if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

# autojump
[[ -s $(brew --prefix)/etc/autojump.sh ]] && . $(brew --prefix)/etc/autojump.sh

# postgres
alias start-pg='pg_ctl -l $PGDATA/server.log start'
alias stop-pg='pg_ctl stop -m fast'
alias show-pg-status='pg_ctl status'
alias restart-pg='pg_ctl reload'
