from flask import Flask, render_template, jsonify
import socket
import datetime
import os
import platform

app = Flask(__name__)

@app.route("/")
def index():
    container_id = socket.gethostname()
    current_time = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    sys_info = {
        "hostname": container_id,
        "os": platform.system(),
        "release": platform.release(),
        "python_version": platform.python_version(),
        "port": 8081,
        "status": "Healthy & Operational",
        "current_time": current_time,
        "environment": os.environ.get("APP_ENV", "Production (Docker on AWS)")
    }
    return render_template("index.html", info=sys_info)

@app.route("/health")
def health():
    return jsonify({
        "status": "UP",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "hostname": socket.gethostname()
    }), 200

if __name__ == "__main__":
    # Must listen on 0.0.0.0 to accept traffic from outside the container
    port = int(os.environ.get("PORT", 8081))
    app.run(host="0.0.0.0", port=port)
