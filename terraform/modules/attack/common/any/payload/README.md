## PAYLOADS ##

This directory houses scripts used by ssm, osconfig and azure runbooks. Scripts which are not cloud specific (e.g. docker install) are in the `any` subdirectory, where as cloud specific scripts like `aws_generate_activity.sh` are under the specific cloud service provider folder.