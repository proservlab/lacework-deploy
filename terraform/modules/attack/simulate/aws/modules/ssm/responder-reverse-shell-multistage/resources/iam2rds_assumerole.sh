ROLE_NAME="${iam2rds_role_name}"
SESSION_NAME="${iam2rds_session_name}"
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=$PROFILE $opts | jq -r '.Account')
echo "Account Number: $AWS_ACCOUNT_NUMBER"
CREDS=$(aws sts assume-role --role-arn "arn:aws:iam::$AWS_ACCOUNT_NUMBER:role/$ROLE_NAME" --role-session-name="$SESSION_NAME")
echo "Assume Role Creds: $CREDS"