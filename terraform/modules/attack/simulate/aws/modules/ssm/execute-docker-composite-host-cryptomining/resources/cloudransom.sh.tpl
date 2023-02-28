#!/bin/bash

# install preqs
if which yum; then
yum install -y jq openssl
elif which apt; then
apt-get install -y jq openssl
else
echo "Unsupported release - missing apt or yum"
exit 1
fi

# aws account where kms key will be created
AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' --raw-output)
# aws current user arn
AWS_CURRENT_USER=$(aws sts get-caller-identity | jq '.Arn' --raw-output)

mkdir ./key_material

KEY_ID=$(aws kms create-key --origin EXTERNAL | jq '.KeyMetadata.KeyId' --raw-output)
openssl rand -out ./key_material/PlaintextKeyMaterial.bin 32
openssl base64 -in ./key_material/PlaintextKeyMaterial.bin -out ./key_material/PlaintextKeyMaterial.b64
KEY=$(aws kms --region us-east-1 get-parameters-for-import --key-id "$KEY_ID" --wrapping-algorithm RSAES_OAEP_SHA_256 --wrapping-key-spec RSA_2048 --query '{Key:PublicKey,Token:ImportToken}' --output text)
echo "$KEY" | awk '{print $1}' > ./key_material/PublicKey.b64
echo "$KEY" | awk '{print $2}' > ./key_material/ImportToken.b64
openssl enc -d -base64 -A -in ./key_material/PublicKey.b64 -out ./key_material/PublicKey.bin
openssl enc -d -base64 -A -in ./key_material/ImportToken.b64 -out ./key_material/ImportToken.bin
openssl pkeyutl \
    -in ./key_material/PlaintextKeyMaterial.bin \
    -out ./key_material/EncryptedKeyMaterial.bin \
    -inkey ./key_material/PublicKey.bin \
    -keyform DER \
    -pubin \
    -encrypt \
    -pkeyopt \
    rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha256

aws kms \
    --region us-east-1 \
    import-key-material \
    --key-id "$KEY_ID" \
    --encrypted-key-material \
    fileb://./key_material/EncryptedKeyMaterial.bin \
    --import-token fileb://./key_material/ImportToken.bin \
    --expiration-model KEY_MATERIAL_DOES_NOT_EXPIRE
cat <<EOF > ./key_material/new_key_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableIAMUserPermissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::$AWS_ACCOUNT_ID:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "EnableCurrentUserKeySetup",
            "Effect": "Allow",
            "Principal": {
                "AWS": "$AWS_CURRENT_USER"
            },
            "Action": [
                    "kms:CreateKey",
                    "kms:ImportKey",
                    "kms:ImportKeyMaterial",
                    "kms:DeleteKey",
                    "kms:DeleteKeyMaterial",
                    "kms:EnableKey",
                    "kms:DisableKey",
                    "kms:ScheduleKeyDeletion",
                    "kms:PutKeyPolicy",
                    "kms:SetPolicy",
                    "kms:DeletePolicy",
                    "kms:CreateGrant",
                    "kms:DeleteIdentity",
                    "kms:DescribeIdentity",
                    "kms:KeyStatus",
                    "kms:Status",                        
                    "kms:List*",
                    "kms:Get*",
                    "kms:Describe*",
                    "tag:GetResources"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EnableGlobalKMSEncrypt",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:GenerateDataKey",
                "kms:Encrypt"
            ],
            "Resource": "*"
        }
    ]
}
EOF

# add key policy
aws kms put-key-policy \
    --policy-name default \
    --key-id "$KEY_ID" \
    --policy file://./key_material/new_key_policy.json