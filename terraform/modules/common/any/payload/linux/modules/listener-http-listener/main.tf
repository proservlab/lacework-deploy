locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
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
    log "listener: ${local.listen_ip}:${local.listen_port}"
    screen -S http -X quit
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
    
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}