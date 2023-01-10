#!/bin/bash

bucketname="attacksurface-target-s3-bucket-46qsim8h"
aws s3 ls ${bucketname} --recursive | awk '{ print $NF }' > /tmp/filelist

for file in `cat /tmp/filelist`
do
        class=`aws s3api head-object --bucket ${bucketname} --key $file  | jq -r '.StorageClass'`
        if [ "$class" = "null" ]
        then
                class="STANDARD"

        fi
        echo "aws s3 cp s3://${bucketname}/${file} s3://${bucketname}/${file} --sse  --storage-class ${class}"
done