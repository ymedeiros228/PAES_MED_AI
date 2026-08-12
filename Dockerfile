# Dockerfile — PAES MED AI (deploy unificado: API + front Flutter web)
# Multi-stage: Stage 1 compila Flutter web, Stage 2 roda o backend Python.
# Resolve problema do git clone do Flutter no Render.

# ------------------------------------------------------------------------
# STAGE 1: Build do Flutter web
# ------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.24.5 AS flutter-build

WORKDIR /app
COPY . /app/

# Build do front web (HTML renderer = 5.5MB vs 25MB com CanvasKit)
RUN flutter build web --release --base-href=/ --web-renderer html

# Remove CanvasKit nao usado (renderer HTML) para reduzir tamanho da imagem
RUN rm -rf /app/build/web/canvaskit

# ------------------------------------------------------------------------
# STAGE 2: Runtime Python
# ------------------------------------------------------------------------
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

# Copia o build web do stage 1
COPY --from=flutter-build /app/build/web /app/backend/build/web

# Banco pronto para deploy
COPY deploy/data/paes_med_ai.db /app/data/paes_med_ai.db

# Define data dir e porta
ENV PAES_DATA_DIR=/app/data
ENV PORT=8000
EXPOSE $PORT

# Comando de start
WORKDIR /app/backend
CMD python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
