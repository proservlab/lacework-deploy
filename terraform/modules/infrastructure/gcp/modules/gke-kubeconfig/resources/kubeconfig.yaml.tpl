apiVersion: v1
clusters:
- cluster:
    server: ${ cluster_endpoint }
    certificate-authority-data: ${ cluster_certificate_authority }
    name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: gcp
  name: gcp
current-context: gcp
kind: Config
preferences: {}
users:
- name: gcp
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - "--use_application_default_credentials"
      - "--cluster"
      - "${ cluster_name }"
      - "--location"
      - "${ gcp_location }"
      command: gke-gcloud-auth-plugin
      provideClusterInfo: true