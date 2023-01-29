apiVersion: v1
clusters:
- cluster:
    server: ${ cluster_endpoint }
    certificate-authority-data: ${ cluster_certificate_authority }
    name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        args:
          - "--region"
          - "${ aws_region }"
          - "eks"
          - "get-token"
          - "--cluster-name"
          - "${ cluster_name }"
        command: aws
        env:
        - name: AWS_PROFILE
          value: ${ aws_profile_name }