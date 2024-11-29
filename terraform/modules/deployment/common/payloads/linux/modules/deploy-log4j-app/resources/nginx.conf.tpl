# Define trusted IPs using the geo module
geo $trusted_ip {
    default 0; # Default to not trusted
    %{for address in trusted_addresses ~}
    ${address} 1;
    %{ endfor ~}
    
}

server {
    listen ${listen_port};

    location / {
        # Check if the IP is trusted
        if ($trusted_ip = 1) {
            proxy_pass http://127.0.0.1:${loopback_port}; # Backend vulnerable app
            break;
        }

        # Add headers that mimic Apache Struts
        add_header X-Powered-By "Servlet/3.1 JSP/2.3 (Apache Tomcat/9.0.37 Java/Oracle Corporation/1.8.0_292-b10)";
        add_header X-Application "Apache Struts 2.5.10";
        add_header Server "Apache-Coyote/1.1";
        add_header X-Log4j-Version "2.14.1"; # Log4j vulnerable version
        add_header Content-Type "text/html;charset=ISO-8859-1";

        # Clear default Nginx headers
        more_clear_headers Server;
        more_clear_headers X-Content-Type-Options;

        # Use Lua to process the Content-Type header
        content_by_lua_block {
            -- Get the Content-Type header from the request
            local content_type = ngx.req.get_headers()["Content-Type"]

            if content_type then
                -- Extract the value inside addHeader('X-Check-Struts', 'VALUE')
                local value = content_type:match("addHeader%('X%-Check%-Struts',%s*'([^']+)'%)")

                if value then
                    -- Add the X-Check-Struts header with the extracted value
                    ngx.header["X-Check-Struts"] = value
                end
            end

            -- Return a simple HTML response
            local page = [[
                <!DOCTYPE html>
                <html>
                    <head>
                        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
                        <title>Basic Struts 2 Application - Welcome</title>
                    </head>
                    <body>
                        <h1>Welcome To Struts 2!</h1>
                        <p><a href="#">Hello World</a></p>
                    </body>
                </html>
            ]]
            ngx.say(page)
        }
    }
}
