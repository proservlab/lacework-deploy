proxy-scanner:
  config:
    scan_public_registries: true
    default_registry: index.docker.io
    static_cache_location: /opt/lacework
    lacework:
      account_name: "${lacework_account_name}"
      integration_access_token: "${lacework_proxy_token}"
    registries:
      - domain: index.docker.io
        name: docker_public
        ssl: true
        auto_poll: true
        is_public: true
        disable_non_os_package_scanning: false
        poll_frequency_minutes: 20
        go_binary_scanning:
          enable: true
      - auto_poll: true
        disable_non_os_package_scanning: false
        domain: ghcr.io
        is_public: true
        name: github_public
        notification_type: ghcr
        ssl: true
        poll_frequency_minutes: 20
        go_binary_scanning:
          enable: true 