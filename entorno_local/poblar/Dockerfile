# Kaizen · imagen del poblador (Python 3.12, la misma versión que nodo1)
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY poblar.py .
USER nobody
ENTRYPOINT ["python", "poblar.py"]
