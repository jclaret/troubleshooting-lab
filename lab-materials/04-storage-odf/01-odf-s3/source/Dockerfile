# UBI9 Python
FROM registry.redhat.io/ubi9/python-312:latest

USER 0
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080

# Pillow native libs
RUN dnf -y --setopt=install_weak_deps=False install \
      libjpeg-turbo libjpeg-turbo-devel zlib zlib-devel libpng libpng-devel \
 && dnf -y clean all && rm -rf /var/cache/dnf

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app_s3.py .

# Arbitrary UID friendly
RUN chgrp -R 0 /app && chmod -R g=u /app
USER 1001
EXPOSE 8080
CMD ["gunicorn","-b","0.0.0.0:8080","--workers","2","app_s3:app"]
