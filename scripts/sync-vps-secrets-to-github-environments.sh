#!/usr/bin/env bash
# Sube VPS_* a los GitHub Environments staging y production en anyjobs-backend y anyjobs-front.
# Requiere: gh autenticado (repo). GitHub no expone valores de secrets ya guardados: hace falta
# un .env local puntual. Tras usar: chmod 600 vps-secrets.env; borra el archivo (rm) o guárdalo
# solo en un gestor de secretos, no en el repo.
#
# Uso:
#   ./scripts/sync-vps-secrets-to-github-environments.sh /ruta/vps-secrets.env [/ruta/clave_ssh]
#
# Si pasas clave_ssh, no pongas VPS_SSH_PRIVATE_KEY en el .env (evita multilínea en dotenv).
set -euo pipefail

ENV_FILE=${1:?"Uso: $0 /ruta/vps-secrets.env [/ruta/clave_ssh_privada]"}
KEY_FILE=${2:-}

test -f "$ENV_FILE" || { echo "No existe $ENV_FILE" >&2; exit 1; }
if [[ -n "$KEY_FILE" ]]; then
  test -f "$KEY_FILE" || { echo "No existe clave $KEY_FILE" >&2; exit 1; }
fi

REPOS=(FranMaster08/anyjobs-backend FranMaster08/anyjobs-front)
ENVS=(staging production)

for repo in "${REPOS[@]}"; do
  for env in "${ENVS[@]}"; do
    echo ">>> gh secret set -f … --env $env -R $repo"
    gh secret set -f "$ENV_FILE" --env "$env" -R "$repo"
    if [[ -n "$KEY_FILE" ]]; then
      gh secret set VPS_SSH_PRIVATE_KEY --env "$env" -R "$repo" <"$KEY_FILE"
    fi
  done
done

echo "Listo. Comprueba con: gh secret list -R FranMaster08/anyjobs-backend --env staging"
