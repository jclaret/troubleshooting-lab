# Minimal RHEL9 base image with Python 3.12
FROM registry.redhat.io/ubi9/python-312:9.6-1754326132 AS builder

USER 0
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    UPLOAD_DIR=/data

# Install Pillow build deps
RUN dnf -y --setopt=install_weak_deps=False install \
      libjpeg-turbo libjpeg-turbo-devel \
      zlib zlib-devel \
      libpng libpng-devel \
 && dnf -y clean all && rm -rf /var/cache/dnf

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY app.py .

RUN mkdir -p /data && chgrp -R 0 /data /app && chmod -R g=u /data /app

USER 1001
EXPOSE 8080
CMD ["gunicorn", "-b", "0.0.0.0:8080", "--workers", "2", "app:app"]
