import os
import uuid
from flask import Flask, request, redirect, url_for, send_from_directory, render_template_string, abort, jsonify
from werkzeug.utils import secure_filename
from PIL import Image

UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/data")
MAX_CONTENT_LENGTH = int(os.environ.get("MAX_CONTENT_LENGTH_MB", "10")) * 1024 * 1024  # 10 MB by default
ALLOWED_EXT = {"png", "jpg", "jpeg", "gif", "webp"}

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_CONTENT_LENGTH
os.makedirs(UPLOAD_DIR, exist_ok=True)

INDEX_HTML = """
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>Upload images</title>
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 2rem; }
    form { display:flex; gap: 1rem; align-items: center; }
    .note { color: #555; margin-top: .5rem; }
    .ok { color: #0a0; }
    .err { color: #a00; }
  </style>
</head>
<body>
  <h1>Upload images to /data</h1>
  <form method="post" enctype="multipart/form-data" action="/upload">
    <input type="file" name="file" accept="image/*" required>
    <button type="submit">Upload</button>
  </form>
  <p class="note">Max size: {{max_mb}} MB. Types: png, jpg, jpeg, gif, webp.</p>
  {% if msg %}<p class="{{cls}}">{{msg}}</p>{% endif %}
  <h2>Existing images</h2>
  <ul>
    {% for f in files %}
      <li><a href="{{url_for('serve_file', filename=f)}}">{{f}}</a></li>
    {% else %}
      <li>(Empty)</li>
    {% endfor %}
  </ul>
</body>
</html>
"""

def allowed(filename):
    ext = filename.rsplit(".", 1)[-1].lower() if "." in filename else ""
    return ext in ALLOWED_EXT

@app.get("/")
def index():
    files = sorted([f for f in os.listdir(UPLOAD_DIR) if os.path.isfile(os.path.join(UPLOAD_DIR, f))])
    return render_template_string(INDEX_HTML, files=files, msg=request.args.get("msg"), cls=request.args.get("cls", ""), max_mb=app.config["MAX_CONTENT_LENGTH"] // (1024*1024))

@app.get("/healthz")
def healthz():
    return "ok", 200

@app.post("/upload")
def upload():
    if "file" not in request.files:
        return redirect(url_for("index", msg="No file attached", cls="err"))
    file = request.files["file"]
    if file.filename == "":
        return redirect(url_for("index", msg="Empty filename", cls="err"))
    if not allowed(file.filename):
        return redirect(url_for("index", msg="File type not allowed", cls="err"))

    # Secure name + UUID to avoid collisions
    base = secure_filename(file.filename)
    ext = base.rsplit(".", 1)[-1].lower()
    newname = f"{uuid.uuid4().hex}.{ext}"
    dest = os.path.join(UPLOAD_DIR, newname)

    # Quick validation with Pillow
    try:
        img = Image.open(file.stream)
        img.verify()  # raises an exception if it's not a valid image
    except Exception:
        return redirect(url_for("index", msg="Invalid or corrupt file", cls="err"))

    # Reset the stream and save
    file.stream.seek(0)
    file.save(dest)

    return redirect(url_for("index", msg=f"Upload OK: {newname}", cls="ok"))

@app.get("/files/<path:filename>")
def serve_file(filename):
    # Optional: make listing/download public
    path = os.path.join(UPLOAD_DIR, filename)
    if not os.path.isfile(path):
        abort(404)
    return send_from_directory(UPLOAD_DIR, filename)

# Simple API for automation
@app.post("/api/upload")
def api_upload():
    f = request.files.get("file")
    if not f or not allowed(f.filename):
        return jsonify({"error": "missing file or file type not allowed"}), 400
    ext = f.filename.rsplit(".", 1)[-1].lower()
    name = f"{uuid.uuid4().hex}.{ext}"
    dest = os.path.join(UPLOAD_DIR, name)
    try:
        img = Image.open(f.stream); img.verify()
    except Exception:
        return jsonify({"error": "invalid file"}), 400
    f.stream.seek(0)
    f.save(dest)
    return jsonify({"ok": True, "filename": name, "url": f"/files/{name}"}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8088")))
