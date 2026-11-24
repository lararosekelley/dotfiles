# Show the current AWS profile and identity
function aws-current
    echo "AWS_PROFILE="(set -q AWS_PROFILE; and echo $AWS_PROFILE; or echo '<unset>')
    echo "AWS_REGION="(set -q AWS_REGION; and echo $AWS_REGION; or echo '<unset>')
    aws sts get-caller-identity
end
