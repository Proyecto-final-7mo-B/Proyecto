# Imagen de la API de Kaizen (Linux). Sirve en local y para desplegar en nodo1.
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /app

# Dependencias primero (con hashes): esta capa se reutiliza si solo cambia el código
COPY requirements/base.txt requirements/base.txt
RUN pip install --require-hashes -r requirements/base.txt

COPY pyproject.toml ./
COPY src ./src
RUN pip install --no-deps . && useradd --system --no-create-home kaizen

USER kaizen
EXPOSE 8000
CMD ["uvicorn", "kaizen.api.main:crear_app", "--factory", "--host", "0.0.0.0", "--port", "8000"]
