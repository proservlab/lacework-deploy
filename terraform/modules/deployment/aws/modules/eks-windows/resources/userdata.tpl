MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${ cluster_name } \
  --b64-cluster-ca ${ cluster_ca } \
  --apiserver-endpoint ${ cluster_endpoint } \
  --container-runtime ${ container_runtime } \
  --kubelet-extra-args '--max-pods=${ max_pods }' \
  --use-max-pods ${ use_max_pods }

--==MYBOUNDARY==--