proxy-scanner:
  config:
    scan_public_registries: true
    default_registry: index.docker.io
    static_cache_location: /opt/lacework
    lacework:
      account_name: "${lacework_account_name}"
      integration_access_token: "${proxy_token}"
    registries:
      - domain: index.docker.io
        name: publicdocker
        ssl: true
        auto_poll: false
        is_public: true
        disable_non_os_package_scanning: false
        go_binary_scanning:
          enable: true