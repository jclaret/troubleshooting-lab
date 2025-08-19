from flask import Flask, jsonify
import sys

EXPECTED_CONNTRACK = 8388608
SYSCTL_FILE = "/proc/sys/net/netfilter/nf_conntrack_max"

def check_conntrack():
    try:
        with open(SYSCTL_FILE, "r") as f:
            value = int(f.read().strip())
        return value
    except Exception as e:
        print(f"❌ Error reading {SYSCTL_FILE}: {e}", flush=True)
        sys.exit(1)

current_value = check_conntrack()
if current_value != EXPECTED_CONNTRACK:
    print(f"❌ Invalid nf_conntrack_max={current_value}, expected={EXPECTED_CONNTRACK}", flush=True)
    sys.exit(1)

print(f"✅ nf_conntrack_max={current_value} OK - Starting app", flush=True)

app = Flask(__name__)

@app.route("/")
def index():
    return jsonify({"status": "ok", "message": f"nf_conntrack_max={current_value} OK"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
