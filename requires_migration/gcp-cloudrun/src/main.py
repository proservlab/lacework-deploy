import os

from flask import Flask

import subprocess

app = Flask(__name__)

@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "World")
    # test = subprocess.check_output("cat /var/lib/lacework/datacollector/config.json", shell=True)
    return "Hello: {}!".format(name)


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
