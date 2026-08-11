# Dockerfile — PAES MED AI (deploy unificado: API + front Flutter web)
# Plano Free do Render: banco SQLite pronto em deploy/data/paes_med_ai.db
# e PDFs em data/provas/ e data/gabaritos/ (já no repo).

FROM python:3.13-slim

# Dependencias do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requirements e instala dependencias Python
COPY backend/requirements.txt /app/backend/requirements.txt
RUN pip install --no-cache-dir -r /app/backend/requirements.txt

# Instala Flutter SDK (stable channel)
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:$PATH"
RUN flutter precache --web

# Copia o projeto
COPY . /app/

# Compila o front web (base-href=/ para servir da raiz)
RUN cd /app && flutter build web --release --base-href=/

# Move o build web pra onde o backend espera
RUN mkdir -p /app/backend/build/web && cp -r /app/build/web/* /app/backend/build/web/

# Banco pronto para deploy (evita re-ingerir PDFs a cada start no Free tier)
RUN mkdir -p /app/data && \
    cp /app/deploy/data/paes_med_ai.db /app/data/paes_med_ai.db && \
    cp -r /app/data/provas /app/data/gabaritos /app/data/edital /app/data/ 2>/dev/null || true

# Define data dir e porta
ENV PAES_DATA_DIR=/app/data
ENV PORT=8000
EXPOSE $PORT

# Comando de start (shell form para expandir $PORT)
WORKDIR /app/backend
CMD python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
