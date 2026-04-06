#!/usr/bin/env bash
# Copiar al VPS (p. ej. ~/entorno/anyjobs-deploy) y chmod +x.
# Los workflows por defecto: bash "$HOME/entorno/anyjobs-deploy" (secret VPS_DEPLOY_SCRIPT para otra ruta).
# Directorio del compose: variable ANYJOBS_DEPLOY_ROOT (ruta absoluta con docker-compose.yml y .env).
#   Si NO está definida: BASE=/opt/anyjobs/<staging|production>.
# En Actions suele exportarse ANYJOBS_DEPLOY_ROOT; para un solo stack en todo el VPS, define el secret
# ANYJOBS_DEPLOY_ROOT igual en staging y production (p. ej. /root/entorno).
# El usuario de despliegue debe poder ejecutar docker compose en BASE.
# Si GHCR es privado: en el VPS, como ese usuario, ejecutar una vez:
#   echo TOKEN | docker login ghcr.io -u USUARIO --password-stdin
# (TOKEN = PAT con scope read:packages, mínimo privilegio.)
set -euo pipefail

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose "$@"
  else
    echo "anyjobs-deploy: no hay 'docker compose' (plugin) ni 'docker-compose'. Instala Docker Engine + plugin compose." >&2
    exit 1
  fi
}

ENV_NAME=""
SERVICE=""
IMAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --env) ENV_NAME="$2"; shift 2 ;;
    --service) SERVICE="$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$ENV_NAME" || -z "$SERVICE" || -z "$IMAGE" ]]; then
  echo "Uso: anyjobs-deploy --env staging|production --service anyjobs-back|anyjobs-front --image ghcr.io/org/repo:tag" >&2
  exit 2
fi

if [[ ! "$ENV_NAME" =~ ^(staging|production)$ ]]; then
  echo "Entorno no permitido: $ENV_NAME" >&2
  exit 2
fi

if [[ ! "$SERVICE" =~ ^(anyjobs-back|anyjobs-front)$ ]]; then
  echo "Servicio no permitido: $SERVICE" >&2
  exit 2
fi

# Solo imágenes GHCR del proyecto; tag debe ser sha-* (trazabilidad) o ramas develop|main.
if [[ ! "$IMAGE" =~ ^ghcr.io/[a-z0-9._/-]+:(sha-[a-f0-9]{7,40}|develop|main)$ ]]; then
  echo "Imagen o tag no permitidos: $IMAGE" >&2
  exit 2
fi

BASE="${ANYJOBS_DEPLOY_ROOT:-/opt/anyjobs/${ENV_NAME}}"
if [[ ! -d "$BASE" ]]; then
  echo "Directorio de entorno inexistente: $BASE" >&2
  exit 2
fi

cd "$BASE"

if [[ ! -f .env ]]; then
  echo "anyjobs-deploy: no existe .env en $BASE" >&2
  exit 2
fi

case "$SERVICE" in
  anyjobs-back)
    if ! grep -qE '^[[:space:]]*ANYJOBS_BACK_IMAGE=' .env 2>/dev/null; then
      echo "anyjobs-deploy: falta línea ANYJOBS_BACK_IMAGE= en .env (en $BASE)" >&2
      exit 2
    fi
    sed -i.bak "s|^\([[:space:]]*ANYJOBS_BACK_IMAGE=\).*$|\1${IMAGE}|" .env
    ;;
  anyjobs-front)
    if ! grep -qE '^[[:space:]]*ANYJOBS_FRONT_IMAGE=' .env 2>/dev/null; then
      echo "anyjobs-deploy: falta línea ANYJOBS_FRONT_IMAGE= en .env (en $BASE)" >&2
      exit 2
    fi
    sed -i.bak "s|^\([[:space:]]*ANYJOBS_FRONT_IMAGE=\).*$|\1${IMAGE}|" .env
    ;;
esac

echo "anyjobs-deploy: pull $SERVICE ($IMAGE) en $BASE" >&2
if ! compose --env-file .env pull "$SERVICE"; then
  echo "anyjobs-deploy: pull falló. Si GHCR es privado: docker login ghcr.io (PAT read:packages)." >&2
  exit 1
fi
if ! compose --env-file .env up -d --no-deps --force-recreate "$SERVICE"; then
  echo "anyjobs-deploy: docker compose up falló." >&2
  exit 1
fi
echo "anyjobs-deploy: OK $SERVICE" >&2
