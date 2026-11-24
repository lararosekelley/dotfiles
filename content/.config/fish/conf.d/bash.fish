# Shares the bash dotfiles with fish: environment variables from ~/.exports and
# ~/.environment, and the bash functions that do not change the calling shell.

status is-interactive; or status is-login; or return

set -g __bash_dotfiles 'for f in ~/.functions ~/.exports ~/.environment; do [ -f "$f" ] && source "$f"; done'

# Copy what sourcing the bash files sets or unsets in the environment.
function __bash_import_env
    set -l skip _ SHLVL PWD OLDPWD
    set -l seen

    for entry in (bash -c "$__bash_dotfiles; env -0" | string split0)
        set -l kv (string split -m1 = -- $entry)
        set -l name $kv[1]

        if contains -- $name $skip; or string match -q 'BASH_*' -- $name
            continue
        end

        set -a seen $name

        if test "$name" = PATH
            set -gx PATH (string split : -- $kv[2])
        else if test "$$name" != "$kv[2]"
            set -gx $name $kv[2]
        end
    end

    for name in (set --names --export)
        if not contains -- $name $seen $skip
            set -e $name
        end
    end
end

__bash_import_env

for fn in update mux flac2mp3 vid2mp4 vidslice mov2gif serve peerdeps sub
    function $fn --inherit-variable fn
        bash -c "$__bash_dotfiles; \"\$@\"" bash $fn $argv
    end
end
