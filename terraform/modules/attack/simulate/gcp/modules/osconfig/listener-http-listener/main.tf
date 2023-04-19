locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    server_py = <<-EOT
    #!/usr/bin/env python3

    from http.server import BaseHTTPRequestHandler, HTTPServer
    import logging

    class S(BaseHTTPRequestHandler):
        def _set_response(self):
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

        def do_GET(self):
            logging.info("GET request,\nPath: %s\nHeaders:\n%s\n", str(self.path), str(self.headers))
            self._set_response()
            self.wfile.write("GET request for {}".format(self.path).encode('utf-8'))

        def do_POST(self):
            content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
            post_data = self.rfile.read(content_length) # <--- Gets the data itself
            logging.info("POST request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                    str(self.path), str(self.headers), post_data.decode('utf-8'))
            print(post_data)
            self._set_response()
            self.wfile.write("POST request for {}".format(self.path).encode('utf-8'))

    def run(server_class=HTTPServer, handler_class=S, port=${local.listen_port}):
        logging.basicConfig(level=logging.INFO)
        server_address = ('', port)
        httpd = server_class(server_address, handler_class)
        logging.info('Starting httpd...\n')
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass
        httpd.server_close()
        logging.info('Stopping httpd...\n')

    if __name__ == '__main__':
        from sys import argv

        if len(argv) == 2:
            run(port=int(argv[1]))
        else:
            run()
    EOT
    payload = <<-EOT
    LOGFILE=/tmp/osconfig_attacker_exec_http_listener.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "listener: ${local.listen_ip}:${local.listen_port}"
    screen -ls | grep http | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/http.log
    mkdir -p /tmp/www/
    echo "index" > /tmp/www/index.html
    mkdir -p /tmp/www/upload/v2
    echo "upload" > /tmp/www/upload/v2/index.html
    screen -d -L -Logfile /tmp/http.log -S http -m python3 -c "import base64; exec(base64.b64decode('${base64encode(local.server_py)}'))"
    screen -S http -X colon "logfile flush 0^M"
    log "listener started..."
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# GCP OSCONFIG
#####################################################



resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${var.tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}" = "true",
                              "deployment" = "{var.deployment}",
                              "environment" = "{var.environment}"
                            }
                            EOT
                          )
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id   = "${var.tag}-${var.environment}-${var.deployment}-${random_string.this.id}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash - && exit 100"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 100
    }
    min_wait_duration = var.timeout
  }
}