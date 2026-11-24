# Switch AWS_PROFILE to work
function aws-work
    aws-clear-session
    set -gx AWS_PROFILE work
    set -gx AWS_REGION us-east-1
    echo "Switched to AWS profile: $AWS_PROFILE"
    aws sts get-caller-identity --query Account --output text
end
