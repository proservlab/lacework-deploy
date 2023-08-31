locals {
    cloudtrail_bucket_name = "cloudtrail-log-${random_string.this.id}"
}

data "aws_caller_identity" "current" {}

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket = local.cloudtrail_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = "${aws_s3_bucket.cloudtrail_bucket.id}"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${local.cloudtrail_bucket_name}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
            "Action": "s3:PutObject",
            "Resource": ["arn:aws:s3:::${local.cloudtrail_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"],
            "Condition": { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
        }]

}
POLICY
}

resource "aws_s3_bucket_lifecycle_configuration" "trails" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  rule {
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    status = "Enabled"
    id     = "delete after 30 days"

    expiration {
      days                         = 30
      expired_object_delete_marker = false
    }

    noncurrent_version_expiration {
      noncurrent_days = 31
    }

  }
}

resource "aws_cloudtrail" "example" {
  name                          = "example"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.bucket
  depends_on                    = [ aws_s3_bucket_policy.cloudtrail_bucket_policy ]
  enable_logging                = true
  enable_log_file_validation    = true
  is_multi_region_trail         = true
  include_global_service_events = true
}

resource "aws_athena_database" "cloudtrail_db" {
  name   = "cloudtrail_db"
  bucket = aws_s3_bucket.cloudtrail_bucket.bucket
}

resource "aws_athena_named_query" "create_cloudtrail_table" {
  name     = "create_table_cloudtrail"
  database = aws_athena_database.cloudtrail_db.name

  query = <<-EOT
    CREATE EXTERNAL TABLE IF NOT EXISTS cloudtrail_logs (
      eventversion STRING,
      useridentity STRUCT<
        type: STRING,
        principalid: STRING,
        arn: STRING,
        accountid: STRING,
        invokedby: STRING,
        accesskeyid: STRING,
        userName: STRING,
        sessioncontext: STRUCT<
          attributes: STRUCT<
            mfaauthenticated: STRING,
            creationdate: STRING
          >,
          sessionIssuer: STRUCT<
            type: STRING,
            principalId: STRING,
            arn: STRING,
            accountId: STRING,
            userName: STRING
          >
        >
      >,
      eventtime STRING,
      eventsource STRING,
      eventname STRING,
      awsregion STRING,
      sourceipaddress STRING,
      useragent STRING,
      errorcode STRING,
      errormessage STRING,
      requestparameters STRING,
      responseelements STRING,
      additionaleventdata STRING,
      requestid STRING,
      eventid STRING,
      resources ARRAY<STRUCT<
        ARN: STRING,
        accountId: STRING,
        type: STRING
      >>,
      eventtype STRING,
      apiversion STRING,
      readonly STRING,
      recipientaccountid STRING,
      serviceeventdetails STRING,
      sharedeventid STRING,
      vpcendpointid STRING
    )
    ROW FORMAT SERDE 'com.amazon.emr.hive.serde.CloudTrailSerde'
    STORED AS INPUTFORMAT 'com.amazon.emr.cloudtrail.CloudTrailInputFormat'
    OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
    LOCATION 's3://${aws_s3_bucket.cloudtrail_bucket.bucket}/AWSLogs/'
  EOT
}
