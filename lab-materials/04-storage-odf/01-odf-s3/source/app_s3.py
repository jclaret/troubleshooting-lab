import os
import uuid
import logging
from flask import Flask, request, redirect, url_for, render_template_string, jsonify
from werkzeug.utils import secure_filename
from PIL import Image
import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

# ----- Logging setup -----
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL, format='[%(asctime)s] %(levelname)s %(message)s')
logger = logging.getLogger("s3-uploader")
if os.getenv("S3_DEBUG", "false").lower() == "true":
    # Very verbose: signs, headers, retries, etc.
    boto3.set_stream_logger("botocore", logging.DEBUG)

# ----- Config from env/OBC -----
ALLOWED_EXT = {"png", "jpg", "jpeg", "gif", "webp"}
MAX_MB = int(os.environ.get("MAX_CONTENT_LENGTH_MB", "10"))

AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
S3_BUCKET = os.environ["S3_BUCKET"]

# Region: use S3_REGION if provided, otherwise default to us-east-1 (SigV4 friendly)
S3_REGION = os.environ.get("S3_REGION") or os.environ.get("BUCKET_REGION") or "us-east-1"

S3_HOST = os.environ.get("S3_HOST")            # from OBC ConfigMap BUCKET_HOST
S3_PORT = os.environ.get("S3_PORT")            # from OBC ConfigMap BUCKET_PORT
S3_SCHEME = os.environ.get("S3_SCHEME", "http")
FORCE_PATH = os.environ.get("S3_FORCE_PATH_STYLE", "true").lower() == "true"

# Build endpoint including port if present (avoids 80/443 ambiguity)
endpoint = None
if S3_HOST:
    endpoint = f"{S3_SCHEME}://{S3_HOST}{':' + S3_PORT if S3_PORT else ''}"

logger.info(f"S3 config: endpoint={endpoint} region={S3_REGION} bucket={S3_BUCKET} path_style={FORCE_PATH}")

# Boto3 client
s3 = boto3.client(
    "s3",
    endpoint_url=endpoint,
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=S3_REGION,
    config=Config(s3={"addressing_style": "path" if FORCE_PATH else "virtual"})
)

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = MAX_MB * 1024 * 1024

INDEX_HTML = """
<!doctype html>
<html>
<head><meta charset="utf-8"><title>S3 Image Uploader</title>
<style>
 body {font-family: system-ui, Arial, sans-serif; margin:2rem;}
 form {display:flex; gap:1rem; align-items:center;}
 .note {color:#555; margin-top:.5rem;}
 .ok {color:#070;}
 .err {color:#a00;}
</style></head>
<body>
  <h1>Upload images to S3 bucket: {{bucket}}</h1>
  <form method="post" enctype="multipart/form-data" action="/upload">
    <input type="file" name="file" accept="image/*" required>
    <button type="submit">Upload</button>
  </form>
  <p class="note">Max size: {{max_mb}} MB. Types: png, jpg, jpeg, gif, webp.</p>
  {% if msg %}<p class="{{cls}}">{{msg}}</p>{% endif %}
  <h2>Objects in bucket</h2>
  <ul>
    {% for o in objects %}
      <li>{{o}}</li>
    {% else %}
      <li>(Empty)</li>
    {% endfor %}
  </ul>
</body>
</html>
"""

def allowed(filename: str) -> bool:
    return "." in filename and filename.rsplit(".", 1)[-1].lower() in ALLOWED_EXT

def log_client_error(where: str, err: ClientError, extra: dict | None = None):
    """Pretty-print S3 ClientError into pod logs with request id and http code."""
    try:
        code = err.response["Error"].get("Code")
        msg = err.response["Error"].get("Message")
        meta = err.response.get("ResponseMetadata", {})
        rid = meta.get("RequestId")
        http = meta.get("HTTPStatusCode")
    except Exception:
        code = msg = rid = http = "unknown"
    logger.error(f"S3 {where} failed: code={code} http={http} request_id={rid} msg={msg} extra={extra}", exc_info=True)

@app.get("/")
def index():
    try:
        resp = s3.list_objects_v2(Bucket=S3_BUCKET, MaxKeys=50)
        objs = [x["Key"] for x in resp.get("Contents", [])]
        return render_template_string(INDEX_HTML, bucket=S3_BUCKET, objects=objs,
                                      msg=request.args.get("msg"), cls=request.args.get("cls",""), max_mb=MAX_MB)
    except ClientError as e:
        log_client_error("list_objects_v2", e, {"bucket": S3_BUCKET, "endpoint": endpoint})
        code = e.response["Error"].get("Code")
        # Show reason on page but keep app responsive
        return render_template_string(INDEX_HTML, bucket=S3_BUCKET, objects=[],
                                      msg=f"S3 list failed: {code}", cls="err", max_mb=MAX_MB), 200

@app.get("/healthz")
def healthz():
    return "ok", 200

@app.post("/upload")
def upload():
    if "file" not in request.files:
        return redirect(url_for("index", msg="No file", cls="err"))
    f = request.files["file"]
    if f.filename == "":
        return redirect(url_for("index", msg="Empty filename", cls="err"))
    if not allowed(f.filename):
        return redirect(url_for("index", msg="Type not allowed", cls="err"))

    # Basic image validation
    try:
        img = Image.open(f.stream); img.verify()
    except Exception:
        return redirect(url_for("index", msg="Invalid image", cls="err"))
    f.stream.seek(0)

    ext = secure_filename(f.filename).rsplit(".", 1)[-1].lower()
    key = f"{uuid.uuid4().hex}.{ext}"

    try:
        s3.upload_fileobj(f.stream, S3_BUCKET, key)
        return redirect(url_for("index", msg=f"Uploaded: {key}", cls="ok"))
    except ClientError as e:
        log_client_error("upload_fileobj", e, {"bucket": S3_BUCKET, "key": key, "endpoint": endpoint})
        code = e.response["Error"].get("Code")
        status = 403 if code in ("AccessDenied", "SignatureDoesNotMatch") else 500
        return redirect(url_for("index", msg=f"S3 error: {code}", cls="err")), status

# Optional: simple API
@app.post("/api/upload")
def api_upload():
    f = request.files.get("file")
    if not f or not allowed(f.filename):
        return jsonify({"error": "missing or not allowed"}), 400
    try:
        img = Image.open(f.stream); img.verify()
    except Exception:
        return jsonify({"error": "invalid image"}), 400
    f.stream.seek(0)
    key = secure_filename(f.filename)
    try:
        s3.upload_fileobj(f.stream, S3_BUCKET, key)
        return jsonify({"ok": True, "bucket": S3_BUCKET, "key": key}), 201
    except ClientError as e:
        log_client_error("upload_fileobj", e, {"bucket": S3_BUCKET, "key": key, "endpoint": endpoint})
        code = e.response["Error"].get("Code")
        return jsonify({"error": code}), 403 if code in ("AccessDenied", "SignatureDoesNotMatch") else 500

if __name__ == "__main__":
    app.run("0.0.0.0", int(os.environ.get("PORT","8080")))
