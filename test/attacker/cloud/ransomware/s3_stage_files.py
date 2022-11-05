#!/usr/bin/env python3

import boto3

#################################
############ Config #############
#################################
aws_cli_profile = 'default'  # The AWS CLI profile to use for the attack
bucket_name = 'proservlab-s3-bucket-to-target'  # The S3 bucket to target with the attack
#################################

#Creating Session With Boto3.
session = boto3.Session(profile_name=aws_cli_profile)

#Creating S3 Resource From the Session.
s3 = session.resource('s3')

txt_data = b'Unencrypted Content'

object = s3.Object(bucket_name, 'sample_unencrypted_file.txt')

result = object.put(Body=txt_data)