#!/usr/bin/env bash
# Instalar en el VPS EXACTAMENTE como: /usr/local/sbin/anyjobs-deploy
# (los workflows de GitHub Actions invocan esa ruta; chmod +x, ej. chmod 750, root:deploy).
# El usuario de despliegue debe poder ejecutar docker compose en los directorios de cada entorno.
# Si GHCR es privado: en el VPS, como ese usuario, ejecutar una vez:
#   echo TOKEN | docker login ghcr.io -u USUARIO --password-stdin
# (TOKEN = PAT con scope read:packages, mínimo privilegio.)
set -euo pipefail

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

BASE="/opt/anyjobs/${ENV_NAME}"
if [[ ! -d "$BASE" ]]; then
  echo "Directorio de entorno inexistente: $BASE" >&2
  exit 2
fi

cd "$BASE"

case "$SERVICE" in
  anyjobs-back)
    if ! grep -q '^ANYJOBS_BACK_IMAGE=' .env 2>/dev/null; then
      echo "Falta ANYJOBS_BACK_IMAGE en .env" >&2
      exit 2
    fi
    sed -i.bak "s|^ANYJOBS_BACK_IMAGE=.*|ANYJOBS_BACK_IMAGE=${IMAGE}|" .env
    ;;
  anyjobs-front)
    if ! grep -q '^ANYJOBS_FRONT_IMAGE=' .env 2>/dev/null; then
      echo "Falta ANYJOBS_FRONT_IMAGE en .env" >&2
      exit 2
    fi
    sed -i.bak "s|^ANYJOBS_FRONT_IMAGE=.*|ANYJOBS_FRONT_IMAGE=${IMAGE}|" .env
    ;;
esac

docker compose --env-file .env pull "$SERVICE"
docker compose --env-file .env up -d --no-deps --force-recreate "$SERVICE"
