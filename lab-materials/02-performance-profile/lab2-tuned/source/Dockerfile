FROM registry.redhat.io/ubi9/python-312:9.6-1754326132

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
