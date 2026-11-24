# HERD_AGENTS and HERD_REPOS are bash arrays in ~/.functions
function __herd_list -a name
    bash -c "$__bash_dotfiles; "'declare -n list=$1; printf "%s\n" "${list[@]}"' bash $name
end

complete -c herd -f
complete -c herd -l agent -x -a '(__herd_list HERD_AGENTS)' -d 'Agent for the agents tab'
complete -c herd -l repos -d 'Repos to open, instead of $HERD_REPOS'
complete -c herd -l reset -d 'Move the saved session aside, then rebuild'
complete -c herd -s y -l yes -d 'Skip the reset confirmation'
complete -c herd -s h -l help -d 'Show help'
complete -c herd -n '__fish_seen_argument -l repos' -a '(__herd_list HERD_REPOS) (__fish_complete_directories)'
