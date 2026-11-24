# Counterpart of ~/.aliases. Everything is an abbreviation, which expands only
# when typed: a fish alias is a function, so it would also change what fish's
# own scripts run.

status is-interactive; or return

# neovim instead of vim

abbr -a vim nvim
abbr -a vi nvim
abbr -a vimrc 'nvim ~/.config/nvim/init.lua'

# cd stuff

abbr -a up 'cd ..'
abbr -a back 'cd -'
abbr -a dotdot --regex '^\.\.+$' --function multicd

# clipboard

abbr -a copy 'xclip -selection clipboard'
abbr -a pbcopy 'xclip -selection clipboard'

# verbose output for file and folder actions

abbr -a mv 'mv -v'
abbr -a rm 'rm -v'
abbr -a cp 'cp -v'
abbr -a mkdir 'mkdir -v'

# colored output

abbr -a ls 'ls -GF --color'
abbr -a grep 'grep --color=auto'
abbr -a fgrep 'fgrep --color=auto'
abbr -a egrep 'egrep --color=auto'

# files

abbr -a sizeof 'du -sh'

# ripgrep

abbr -a rgs "rg --hidden --glob '!.git' --smart-case --fixed-strings --line-number --color=always"
abbr -a rgf "rg -l --hidden --glob '!.git' --smart-case --fixed-strings --line-number --color=always"

# usage info

abbr -a cpu 'top -o cpu'
abbr -a mem 'top -o mem'

# ip

abbr -a ip 'dig +short myip.opendns.com @resolver1.opendns.com'
abbr -a localip 'ipconfig getifaddr en0'

# git

abbr -a g git
abbr -a wip 'git add -A && git commit -m "work in progress" --no-verify'

# kubernetes

abbr -a k kubectl
abbr -a kx 'kubectl ctx'
abbr -a kn 'kubectl ns'
abbr -a tsw 'tailscale switch'

# misc. tools

abbr -a c clear
abbr -a dl 'yt-dlp -x'
abbr -a notify 'tput bel'
abbr -a space 'df -P -kHl'
abbr -a ports 'lsof -n -i -P | grep LISTEN'
abbr -a agent-awake 'python3 ~/.local/share/agent-awake/agent_awake.py'

# rails

abbr -a rake 'bundle exec rake'
abbr -a r 'bundle exec rails'
abbr -a rch 'bundle exec rspec (git ls-files --modified --others spec)'

# stupid stuff

abbr -a fuckoff exit
abbr -a big 'figlet -c -f roman'

# work

abbr -a h higharc

# my personal oss projects

abbr -a git-stk-debug ~/Code/personal/git-stk/target/debug/git-stk
abbr -a navi-debug ~/Code/personal/navi/target/debug/navi
