#!/bin/bash

# set aws profile
export AWS_PROFILE="dev-test"

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

# alternative key expiry
#--expiration-model KEY_MATERIAL_EXPIRES \
#    --valid-to 2021-09-21T19:00:00Z