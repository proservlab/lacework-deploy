resource "lacework_query" "query1" {
  query_id = "SNIFF_Host_Activity_PotentialReverseShell"
  query    = <<EOT
  SNIFF_Host_Activity_PotentialReverseShell {
        source {
            LW_HE_PROCESSES
        }
        filter {
            ((RIGHT(EXE_PATH, 3) = '/sh'
                or RIGHT(EXE_PATH, 4) = '/ash'
                or RIGHT(EXE_PATH, 5) = '/bash'
                or RIGHT(EXE_PATH, 5) = '/dash')
                and not CONTAINS(CMDLINE, '.vscode-server')
                and not CONTAINS(CMDLINE, 'ssh -i')
                and (CMDLINE = 'sh -i'
                    or LEFT(CMDLINE, 6) = 'sh -i '
                    or CONTAINS(CMDLINE, '/sh -i ')
                    or RIGHT(CMDLINE, 6) = '/sh -i'
                    or CMDLINE = 'bash -i'
                    or LEFT(CMDLINE, 8) = 'bash -i '
                    or CONTAINS(CMDLINE, '/bash -i ')
                    or RIGHT(CMDLINE, 8) = '/bash -i')
            )
            or (RIGHT(EXE_PATH, 3) = '/nc' and CONTAINS(CMDLINE, ' -e'))
            or (RIGHT(EXE_PATH, 5) = '/ncat' and CONTAINS(CMDLINE, ' -e'))
            or (RIGHT(EXE_PATH, 11) = '/nc.openbsd' and CONTAINS(CMDLINE, ' -e'))
            or (RIGHT(EXE_PATH, 3) = '/nc' and CONTAINS(CMDLINE, ' -l'))
            or (RIGHT(EXE_PATH, 5) = '/ncat' and CONTAINS(CMDLINE, ' -l'))
            or (RIGHT(EXE_PATH, 11) = '/nc.openbsd' and CONTAINS(CMDLINE, ' -l'))
            or (CONTAINS(CMDLINE, 'xterm -display'))
            or (CONTAINS(CMDLINE, '.exec([\"/bin/bash\"'))
            or (CONTAINS(CMDLINE, '.spawn(\"/bin/sh\")'))
            or (CONTAINS(CMDLINE, 'subprocess.call([\"/bin/sh\"'))
        }
        return distinct {
            MID,
            CMDLINE,
            EXE_PATH,
            PID,
            PID_HASH,
            PROCESS_START_TIME,
            USERNAME
        }
    }
EOT
}

resource "lacework_policy" "example1" {
  title       = "Potential Reverse Shell"
  description = "Reverse shell is a shell session initiated by the target machine, rather than from the client. It is a common method used by attackers to control compromised systems that are not publicly routable. This policy flags shell invocations indicating potential reverse shells established in your environment."
  remediation = "Remediation is environment-dependent because this may be expected or the result of normal operations. Investigation is first required to determine the nature of the activity."
  query_id    = lacework_query.query1.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0002-execution",
    "technique:T1059-command-and-scripting-interpreter"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HE_PROCESSES_DEFAULT_PROFILE.HE_Process_Violation"
  }
}

resource "lacework_query" "query2" {
  query_id = "SNIFF_Host_Activity_OffensiveSecurityContainers"
  query    = <<EOT
    SNIFF_Host_Activity_OffensiveSecurityContainers {
        source {
            LW_HE_CONTAINERS
        }
        filter {
            CONTAINS(REPO, 'kalilinux')
            or CONTAINS(REPO, 'metasploit')
            or CONTAINS(REPO, 'parrotsec')
            or CONTAINS(REPO, 'itsafeaturemythic')
            or CONTAINS(REPO, 'rhinosecuritylabs')
            or CONTAINS(REPO, 'bcsecurity')
            or CONTAINS(REPO, 'ne0nd0g')
            or CONTAINS(REPO, 'evilosx')
        }
        return distinct {
            CONTAINER_START_TIME,
            MID,
            CONTAINER_ID,
            CONTAINER_NAME,
            REPO,
            TAG
        }
    }
EOT
}

resource "lacework_policy" "example2" {
  title       = "Offensive Security Containers"
  description = "Offensive security tools are used during red team exercises and penetration testing to evaluate the effectiveness of security products and security controls. Attackers may also use offensive security tools for developing exploits, identifying weaknesses in the target system, and carrying out attacks."
  remediation = "Remediation is environment-dependent because this may be expected or the result of normal operations. Investigation is first required to determine the nature of the activity."
  query_id    = lacework_query.query2.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0042-resource-development",
    "technique:T1588-obtain-capabilities"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HE_CONTAINERS_DEFAULT_PROFILE.HE_Container_Violation"
  }
}

resource "lacework_query" "query3" {
  query_id = "SNIFF_Host_Activity_CodecovCurl"
  query    = <<EOT
    {
        source {
            LW_HE_PROCESSES
        }
        filter {
            RIGHT(EXE_PATH, 5) = '/curl'
            and contains(CMDLINE, '<<<')
            and contains(CMDLINE, ' -d ')
        }
        return distinct {
            MID,
            CMDLINE,
            EXE_PATH,
            PID,
            PID_HASH,
            PROCESS_START_TIME,
            USERNAME
        }
    }
EOT
}

resource "lacework_policy" "example3" {
  title       = "Potential Codecov Bash Uploader Command"
  description = "In the Codecov supply chain attack, the Bash Uploader script was maliciously modified to upload potentially sensitive environment variables to an attacker-controlled site. This policy flags a similar use of cURL for data exfiltration."
  remediation = "Remediation is environment-dependent because this may be expected or the result of normal operations. Investigation is first required to determine the nature of the activity."
  query_id    = lacework_query.query3.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0010-exfiltration",
    "technique:T1020-automated-exfiltration"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HE_PROCESSES_DEFAULT_PROFILE.HE_Process_Violation"
  }
}


resource "lacework_query" "query4" {
  query_id = "SNIFF_Host_Activity_CommonScanners"
  query    = <<EOT
    SNIFF_Host_Activity_CommonScanners {
        source {
            LW_HE_PROCESSES
        }
        filter {
            RIGHT(EXE_PATH, 5) = '/nmap'
            or RIGHT(EXE_PATH, 11) = '/netscanner'
            or RIGHT(EXE_PATH, 5) = '/xmap'
            or RIGHT(EXE_PATH, 5) = '/zmap'
            or RIGHT(EXE_PATH, 9) = '/masscan'
            or RIGHT(EXE_PATH, 6) = '/dscan'
            or RIGHT(EXE_PATH, 7) = '/pnscan'
        }
        return distinct {
            MID,
            CMDLINE,
            EXE_PATH,
            PID,
            PID_HASH,
            PROCESS_START_TIME,
            USERNAME
        }
    }
EOT
}

resource "lacework_policy" "example4" {
  title       = "Commonly Used Scanners"
  description = "Scanning tools are often used during red team exercises and penetration testing, to map the target environment and identify vulnerable systems and services. Attackers, likewise, use these tools to assist in post-exploitation activities."
  remediation = "Remediation is environment-dependent because this may be expected or the result of normal operations. Investigation is first required to determine the nature of the activity."
  query_id    = lacework_query.query4.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0043-reconnaissance",
    "technique:T1595-active-scanning"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HE_PROCESSES_DEFAULT_PROFILE.HE_Process_Violation"
  }
}

resource "lacework_query" "query5" {
  query_id = "SNIFF_Host_Activity_OAST"
  query    = <<EOT
   SNIFF_Host_Activity_OAST {
      source {
          LW_HA_DNS_REQUESTS
      }
      filter {
          RIGHT(HOSTNAME,12) = '.interact.sh'
          or RIGHT(HOSTNAME,21) = '.burpcollaborator.net'
          or RIGHT(HOSTNAME,9) = '.oast.pro'
          or RIGHT(HOSTNAME,10) = '.oast.live'
          or RIGHT(HOSTNAME,10) = '.oast.site'
          or RIGHT(HOSTNAME,12) = '.oast.online'
          or RIGHT(HOSTNAME,8) = '.oast.me'
          or RIGHT(HOSTNAME,7) = '.r87.me'
          or RIGHT(HOSTNAME,12) = '.oastify.com'
      }
      return distinct {
          BATCH_START_TIME,
          BATCH_END_TIME,
          RECORD_CREATED_TIME,
          MID,
          SRV_IP_ADDR,
          HOSTNAME,
          HOST_IP_ADDR,
          TTL,
          PKTLEN
      }
  }
EOT
}

resource "lacework_policy" "example5" {
  title       = "Out-of-Band Application Security Testing (OAST) Tools"
  description = "Out-of-Band Application Security Testing (OAST) tools, such as Burp Suite and Project Discovery, are commonly used by pen-testers, researchers, and attackers to test for various vulnerabilities and perform reconnaissance. Any DNS request for these domains may represent a vulnerability."
  remediation = "Remediation is environment-dependent because this may be expected or the result of normal operations. Investigation is first required to determine the nature of the activity."
  query_id    = lacework_query.query5.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0043-reconnaissance",
    "technique:T1595-active-scanning"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HA_DNS_REQUESTS_DEFAULT_PROFILE.HA_DNS_Request_Violation"
  }
}


resource "lacework_query" "query6" {
  query_id = "SNIFF_Host_Activity_WriteableRootVolumeMap"
  query    = <<EOT
    SNIFF_Host_Activity_WriteableRootVolumeMap {
        source {
            LW_HE_CONTAINERS
        }
        filter {
            contains(VOLUME_MAP::String, ':"/"')
            and not contains(VOLUME_MAP::String, ':ro":"/"')
            and not contains(REPO, 'lacework')
            and right(REPO, 13) <> 'node-exporter'
            and REPO not in (
                'docker.io/amazon/cloudwatch-agent',
                'docker.io/dynatrace/oneagent',
                'docker.io/google/cadvisor',
                'docker.io/kopeio/etcd-manager',
                'docker.io/library/protokube',
                'docker.io/netapp/trident',
                'docker.io/newrelic/infrastructure-k8s',
                'docker.io/openshift/prometheus-node-exporter',
                'docker.io/prom/node-exporter',
                'docker.io/rancher/prom-node-exporter',
                'gcr.io/cadvisor/cadvisor',
                'gcr.io/customer-facing/signalfx/signalfx-agent',
                'gcr.io/datadoghq/agent',
                'gcr.io/pixie-oss/pixie-prod/vizier/pem_image',
                'gke.gcr.io/watcher-daemonset',
                'k8s.gcr.io/etcdadm/etcd-manager',
                'mcr.microsoft.com/azuredefender/stable/security-publisher',
                'mcr.microsoft.com/azuremonitor/containerinsights/ciprod',
                'quay.io/openshift/okd-content',
                'quay.io/prometheus/node-exporter',
                'quay.io/signalfx/signalfx-agent',
                'quay.io/sysdig/vuln-runtime-scanner',
                'quay.io/sysdig/host-analyzer',
                'quay.io/sysdig/compliance-benchmark-runner',
                'quay.io/sysdig/node-image-analyzer',
                'quay.io/sysdig/agent-slim',
                'quay.io/sysdig/eveclient-api',
                'registry.redhat.io/openshift4/file-integrity-rhel8-operator'
            )
        }
        return distinct {
            CONTAINER_START_TIME,
            MID,
            CONTAINER_ID,
            CONTAINER_NAME,
            REPO,
            VOLUME_MAP,
            TAG
        }
    }
EOT
}

resource "lacework_policy" "example6" {
  title       = "Container with Writeable Root Volume Map Detected"
  description = "A container was detected running with the root of the host system mounted. This could potentially allow a container escape to access the host system."
  remediation = "Verify that a writeable root volume map is necessary for the container to execute."
  query_id    = lacework_query.query6.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "lwredteam",
    "security:attack",
    "tactic:TA0004-privilege-escalation",
    "technique:T1611-escape-to-host"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_HE_CONTAINERS_DEFAULT_PROFILE.HE_Container_Violation"
  }
}
   


    

  