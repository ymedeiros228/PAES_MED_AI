# Dockerfile — PAES MED AI (deploy unificado: API + front web)
# Usa Python 3.13 + instala Flutter SDK no build.

FROM python:3.13-slim

# Dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copia requirements e instala dependências Python
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

# Expõe a porta
ENV PORT=8000
EXPOSE $PORT

# Comando de start
WORKDIR /app/backend
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
