- name: gke_my-gcp-project_us-west1-b_production
  user:
    auth-provider:
      config:
        access-token: ${ access_token }
        cmd-args: config config-helper --format=json
        cmd-path: gcloud
        expiry: 2018-04-27T04:10:15Z
        expiry-key: '{.credential.token_expiry}'
        token-key: '{.credential.access_token}'
      name: gcp