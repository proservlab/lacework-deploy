apiVersion: v1
clusters:
- cluster:
    server: ${ cluster_endpoint }
    certificate-authority-data: ${ cluster_certificate_authority }
    name: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
contexts:
- context:
    cluster: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
    user: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
  name: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
current-context: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
kind: Config
preferences: {}
users:
- name: gke_${ gcp_project_id }_${ gcp_location }_${ cluster_name }
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: gke-gcloud-auth-plugin
      installHint: Install gke-gcloud-auth-plugin for use with kubectl by following
        https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
      provideClusterInfo: true