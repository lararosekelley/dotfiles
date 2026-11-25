# user at host in dir on branch *+^↑1↓1 (venv) (NODE_ENV: env)
# (time) ➜
#
# Mirrors ~/.bash_prompt. A part that would wrap mid-word starts its own line
# instead.

# git state, after the branch: * unstaged, + untracked, ^ staged, ✔ clean, and
# ↑/↓ commits ahead of and behind upstream
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_status_order dirtystate untrackedfiles stagedstate
set -g __fish_git_prompt_char_dirtystate '*'
set -g __fish_git_prompt_char_untrackedfiles +
set -g __fish_git_prompt_char_stagedstate '^'
set -g __fish_git_prompt_char_cleanstate ' ✔'
set -g __fish_git_prompt_char_upstream_ahead ↑
set -g __fish_git_prompt_char_upstream_behind ↓
set -g __fish_git_prompt_char_upstream_equal ''
set -g __fish_git_prompt_color_branch -o brgreen
set -g __fish_git_prompt_color_flags -o brmagenta
set -g __fish_git_prompt_color_cleanstate -o brmagenta
set -g __fish_git_prompt_color_upstream -o brmagenta

function fish_prompt
    set -l last_status $status
    set -l normal (set_color normal)
    set -l white (set_color brwhite)
    set -l bold_purple (set_color -o brmagenta)

    set -l identity (set_color -o brred)$USER$normal$white" at "(set_color -o ff8700)(prompt_hostname)$normal
    if set -q SSH_CLIENT; or set -q SSH_TTY
        set identity $identity$white" over "$bold_purple"ssh"$normal
    end

    set -l dir_part $white" in "(set_color -o bryellow)(prompt_pwd -d 0)$normal

    set -l git_part (fish_git_prompt $white" on %s")$normal

    set -l env_part ""
    if set -q VIRTUAL_ENV
        set env_part " ("(path basename $VIRTUAL_ENV)")"
    end
    if test -n "$NODE_ENV"
        set env_part "$env_part (NODE_ENV: $NODE_ENV)"
    end
    test -n "$env_part"; and set env_part $bold_purple$env_part$normal

    set -l line $identity
    set -l width (string length --visible -- $identity)
    for part in $dir_part $git_part $env_part
        set -l part_width (string length --visible -- $part)
        test $part_width -eq 0; and continue

        if test (math $width + $part_width) -gt $COLUMNS
            set line $line\n(string replace ' ' '' -- $part)
            set width (math $part_width - 1)
        else
            set line $line$part
            set width (math $width + $part_width)
        end
    end

    set -l icon (set_color brwhite)➜
    if test $last_status -ne 0
        set icon (set_color brred)✗
    end

    echo $line
    printf '%s(%s) %s%s  ' (set_color brmagenta) (date '+%I:%M %p') $icon $normal
end
