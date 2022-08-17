proxy-scanner:
  config:
    default_registry: index.docker.io
    static_cache_location: /opt/lacework
    lacework:
      account_name: "proservlab"
      integration_access_token: "${proxy_token}"
    registries:
      - domain: index.docker.io
        name: myRegistry
        ssl: true
        auto_poll: false
        is_public: true
        poll_frequency_minutes: 20
        disable_non_os_package_scanning: false
        go_binary_scanning:
          enable: true