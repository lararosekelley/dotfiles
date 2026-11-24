# Start an LLM harness with seeded AWS credentials
#
# Usage: ai harness [profile] [args...]
function ai
    set -l harness $argv[1]
    set -e argv[1]

    if not contains -- "$harness" claude codex opencode
        echo "Usage: ai harness [profile] [args...]" >&2
        echo "  harness: claude, codex, opencode" >&2
        echo "  profile: work, personal (optional)" >&2
        return 1
    end

    switch "$argv[1]"
        case work personal
            aws-$argv[1]; or return 1
            set -e argv[1]
    end

    command $harness $argv
end
