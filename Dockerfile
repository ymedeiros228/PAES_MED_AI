# Dockerfile — PAES MED AI (deploy unificado: API + front Flutter web pre-compilado)
# O build Flutter web e feito no Windows e commitado em deploy/web/
# O banco SQLite e commitado em deploy/data/paes_med_ai.db
# Isso evita compilar Flutter no Render (memoria/tempo do plano Free).

FROM python:3.13-slim

# Dependencias do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requirements e instala dependencias Python
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

# Copia o projeto
COPY . /app/

# Copia build web pre-compilado e banco pronto
COPY deploy/web /app/backend/build/web
COPY deploy/data/paes_med_ai.db /app/data/paes_med_ai.db
COPY deploy/data/materiais /app/data/materiais

# Define data dir e porta
ENV PAES_DATA_DIR=/app/data
ENV PORT=8000
EXPOSE $PORT

# Comando de start
WORKDIR /app/backend
CMD python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
