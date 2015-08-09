# zshrc
# ----------

export ZSH=$HOME/.oh-my-zsh
export GOPATH="$HOME/.go"
export RBENV_ROOT='/usr/local/var/rbenv'
export PATH="/usr/local/bin:/bin:/usr/sbin:/sbin:/usr/bin:$GOPATH/bin"
export STUDIO_JDK=/Library/Java/JavaVirtualMachines/jdk1.8.0_25.jdk

ZSH_THEME="steeef"
DISABLE_AUTO_TITLE="true"
plugins=(vagrant go git rails ruby python web-search brew bower encode64 gem gradle jsontools last-working-dir node npm osx perl pep8 pip sudo)

source $ZSH/oh-my-zsh.sh

# my files
files=(~/.aliases ~/.env ~/.functions)
for file in ${files[@]}; do
    if [ -f "$file" ]; then
        source $file
    fi
done

# rbenv
if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

# don't cd when dir name typed alone
unsetopt autocd

# autojump
[[ -s $(brew --prefix)/etc/autojump.sh ]] && . $(brew --prefix)/etc/autojump.sh

# postgres
export PGDATA='/usr/local/var/postgres'
export PGHOST=localhost
alias start-pg='pg_ctl -l $PGDATA/server.log start'
alias stop-pg='pg_ctl stop -m fast'
alias show-pg-status='pg_ctl status'
alias restart-pg='pg_ctl reload'
