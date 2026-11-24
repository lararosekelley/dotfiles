# Run a command n times
#
# Usage: loop n command [args...]
function loop
    for i in (seq $argv[1])
        $argv[2..]
    end
end
