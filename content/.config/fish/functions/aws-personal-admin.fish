# Assume the MFA-gated personal-admin role and export its session
# credentials, since Terraform and other SDK tools can't prompt for MFA
function aws-personal-admin
    aws-clear-session
    set -l creds (aws configure export-credentials --profile personal-admin --format env-no-export); or return 1
    set -e AWS_PROFILE

    for line in $creds
        set -l kv (string split -m1 = -- $line)
        set -gx $kv[1] $kv[2]
    end

    set -gx AWS_REGION us-east-1
    echo "Switched to AWS role: personal-admin (expires $AWS_CREDENTIAL_EXPIRATION)"
    aws sts get-caller-identity --query Account --output text
end
