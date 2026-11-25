# Abbreviations from ~/.aliases, so both shells share one list. Abbreviations
# expand only when typed; a fish alias is a function, which fish's own scripts
# would run too. Names that are fish builtins, such as path, keep their fish
# meaning.

status is-interactive; or return

if test -f ~/.aliases
    for line in (string match -r '^alias \S+=.*' <~/.aliases)
        set -l alias (string match -rg "^alias ([^=]+)=(['\"])(.*)\2\$" -- $line)
        set -q alias[3]; or continue
        builtin -q -- $alias[1]; and continue
        abbr -a -- $alias[1] $alias[3]
    end
end
