# app_hp.py
# Purpose: Tiny Flask app to display HugePages information in a pod.
# Notes:
# - Reads /proc/meminfo and /sys/kernel/mm/hugepages for 1Gi pages
# - Shows env/DownwardAPI values for hugepages-1Gi requests/limits
# - Checks the hugetlbfs mount (/dev/hugepages) and lists files

import os
from flask import Flask, jsonify, render_template_string

APP_PORT = int(os.environ.get("PORT", "8080"))
HP_SIZE_KB = 1048576  # 1Gi pages
HP_SYSFS = f"/sys/kernel/mm/hugepages/hugepages-{HP_SIZE_KB}kB"
HP_MOUNT = os.environ.get("HP_MOUNT", "/dev/hugepages")
PODINFO_DIR = os.environ.get("PODINFO_DIR", "/etc/podinfo")

TEMPLATE = """
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>HugePages inspector</title>
<style>
  body { font-family: system-ui, Arial, sans-serif; margin: 1.5rem; }
  table { border-collapse: collapse; margin: 1rem 0; }
  th, td { border: 1px solid #bbb; padding: .35rem .6rem; }
  th { background: #f2f2f2; text-align: left; }
  code { background: #f6f8fa; padding: 0 .3rem; }
</style>
</head>
<body>
  <h1>HugePages inspector (1Gi)</h1>

  <h2>Pod resources (via Downward API / env)</h2>
  <table>
    <tr><th>requests.hugepages-1Gi</th><td>{{ req_1g }}</td></tr>
    <tr><th>limits.hugepages-1Gi</th><td>{{ lim_1g }}</td></tr>
    <tr><th>Downward file</th><td><code>{{ podinfo_file }}</code> → {{ podinfo_val }}</td></tr>
  </table>

  <h2>/proc/meminfo (huge-related)</h2>
  <table>
    {% for k,v in meminfo.items() %}
      <tr><th>{{k}}</th><td>{{v}}</td></tr>
    {% endfor %}
  </table>

  <h2>sysfs for 1Gi pages ({{hp_sysfs}})</h2>
  <table>
    {% for k,v in sysfs.items() %}
      <tr><th>{{k}}</th><td>{{v}}</td></tr>
    {% endfor %}
  </table>

  <h2>hugetlbfs mount ({{hp_mount}})</h2>
  <table>
    <tr><th>exists</th><td>{{ mount_exists }}</td></tr>
    <tr><th>files</th><td>{{ files|length }}</td></tr>
  </table>
  {% if files %}
  <ul>
    {% for f in files %}
      <li>{{ f }}</li>
    {% endfor %}
  </ul>
  {% endif %}

  <p><em>Tip:</em> To use hugepages you usually create files in {{hp_mount}} and mmap() them (libhugetlbfs).</p>
</body>
</html>
"""

app = Flask(__name__)

def parse_meminfo():
    want = {"HugePages_Total", "HugePages_Free", "HugePages_Rsvd", "HugePages_Surp",
            "Hugepagesize", "Hugetlb"}
    out = {}
    try:
        with open("/proc/meminfo") as fh:
            for line in fh:
                if ":" not in line:
                    continue
                k, v = line.split(":", 1)
                if k.strip() in want:
                    out[k.strip()] = v.strip()
    except Exception as e:
        out["error"] = str(e)
    return out

def read_sysfs_1g():
    keys = ["nr_hugepages", "free_hugepages", "resv_hugepages", "surplus_hugepages"]
    out = {}
    for k in keys:
        p = os.path.join(HP_SYSFS, k)
        try:
            with open(p) as fh:
                out[k] = fh.read().strip()
        except FileNotFoundError:
            out[k] = "N/A"
        except Exception as e:
            out[k] = f"err: {e}"
    return out

def read_podinfo_value():
    p = os.path.join(PODINFO_DIR, "hugepages_1G_request")
    try:
        with open(p) as fh:
            return fh.read().strip()
    except Exception:
        return "(not found)"

@app.get("/healthz")
def healthz():
    return "ok", 200

@app.get("/")
def index():
    req_1g = os.environ.get("REQUESTS_HUGEPAGES_1GI", "(env not set)")
    lim_1g = os.environ.get("LIMITS_HUGEPAGES_1GI", "(env not set)")
    podinfo_val = read_podinfo_value()
    meminfo = parse_meminfo()
    sysfs = read_sysfs_1g()
    files = []
    mount_exists = os.path.isdir(HP_MOUNT)
    if mount_exists:
        try:
            for name in sorted(os.listdir(HP_MOUNT)):
                files.append(name)
        except Exception as e:
            files = [f"(error listing mount: {e})"]
    return render_template_string(
        TEMPLATE,
        req_1g=req_1g,
        lim_1g=lim_1g,
        podinfo_file=f"{PODINFO_DIR}/hugepages_1G_request",
        podinfo_val=podinfo_val,
        meminfo=meminfo,
        sysfs=sysfs,
        hp_sysfs=HP_SYSFS,
        hp_mount=HP_MOUNT,
        mount_exists=mount_exists,
        files=files,
    )

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=APP_PORT)

