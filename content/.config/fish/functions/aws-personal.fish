# Switch AWS_PROFILE to personal
function aws-personal
    aws-clear-session
    set -gx AWS_PROFILE personal
    set -gx AWS_REGION us-east-1
    echo "Switched to AWS profile: $AWS_PROFILE"
    aws sts get-caller-identity --query Account --output text
end
