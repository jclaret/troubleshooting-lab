FROM registry.access.redhat.com/ubi9/python-39

WORKDIR /app

USER root
RUN dnf install -y kmod procps-ng && dnf clean all
USER 1001

COPY app.py /app/app.py
COPY hello.ko /app/hello.ko

CMD ["python3", "/app/app.py"]
