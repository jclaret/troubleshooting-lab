# --- builder ---
FROM registry.redhat.io/ubi9/python-312:9.6-1754326132 AS builder
WORKDIR /app
ENV VIRTUAL_ENV=/opt/app-root/venv \
    PATH=/opt/app-root/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
COPY requirements.txt .
# Fuerza venv limpio y basado en 3.12
RUN rm -rf "$VIRTUAL_ENV" \
 && /usr/bin/python3 -m venv --copies "$VIRTUAL_ENV" \
 && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir -U pip wheel \
 && "$VIRTUAL_ENV/bin/pip" install --no-cache-dir -r requirements.txt
COPY app_hp.py .

# --- runtime (MISMA base que builder) ---
FROM registry.redhat.io/ubi9/python-312:9.6-1754326132
ENV PORT=8080 \
    HP_MOUNT=/dev/hugepages \
    PODINFO_DIR=/etc/podinfo \
    VIRTUAL_ENV=/opt/app-root/venv \
    PATH=/opt/app-root/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
USER 0
RUN mkdir -p /app /opt/app-root \
 && chgrp -R 0 /app /opt/app-root \
 && chmod -R g=u /app /opt/app-root
COPY --from=builder /opt/app-root/venv /opt/app-root/venv
COPY --from=builder /app/app_hp.py /app/
USER 1001
WORKDIR /app
EXPOSE 8080
# Evita depender del shebang del script
CMD ["/opt/app-root/venv/bin/python","-m","gunicorn","-b","0.0.0.0:8080","--workers","2","app_hp:app"]
