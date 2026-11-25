# Apply `aws-env` to this shell. The aws-* aliases in ~/.aliases call this.
#
# Usage: aws-use work|personal|personal-admin|clear
function aws-use
    set -l vars (aws-env $argv); or return

    for line in $vars
        set -l kv (string split -m1 = -- $line)
        if test -n "$kv[2]"
            set -gx $kv[1] $kv[2]
        else
            set -e $kv[1]
        end
    end

    test "$argv[1]" = clear; or aws sts get-caller-identity --query Account --output text
end
