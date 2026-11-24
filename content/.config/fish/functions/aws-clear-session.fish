# Drop exported session credentials, which would override AWS_PROFILE
function aws-clear-session
    set -e AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_CREDENTIAL_EXPIRATION
end
