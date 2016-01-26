# bashrc
# --------

# load dotfiles
files=(
    ~/.aliases
    ~/.bash_prompt
    ~/.exports
    ~/.functions
    ~/.git-prompt.sh
    ~/.env
)

for file in ${files[@]}; do
    if [ -f "$file" ]; then
        source $file
    fi
done

# bash options
options=(
    histappend
    cdspell
    globstar
    dotglob
)

for option in ${options[@]}; do
    shopt -s "$option"
done

# tab completion
if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

# only have to hit tab once to show suggestions
bind "set show-all-if-ambiguous on"

# rbenv
if which rbenv > /dev/null; then
    eval "$(rbenv init -)";
fi

# nvm
source $(brew --prefix nvm)/nvm.sh
nvm alias default stable > /dev/null

# autojump
[[ -s $(brew --prefix)/etc/autojump.sh ]] && . $(brew --prefix)/etc/autojump.sh
