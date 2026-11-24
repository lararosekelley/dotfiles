# up/down/top/bottom cd into the worktree holding the branch. A process cannot
# change its parent shell's directory, so git-stk prints the destination and
# this moves you. Every other command falls through to git stk.
function stk
    switch "$argv[1]"
        case up down top bottom
            set -l dest (git stk $argv --from-path); or return
            test -n "$dest"; and cd $dest
        case '*'
            git stk $argv
    end
end
