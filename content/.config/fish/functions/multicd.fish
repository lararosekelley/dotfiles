# Expands .. to cd .., ... to cd ../.., and so on (see conf.d/abbreviations.fish)
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end
