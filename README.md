# anyjobs-deploy

Plantillas y script para desplegar **Anyjobs** en un VPS con Docker Compose y GitHub Actions (GHCR).

## Contenido (`vps/`)

| Archivo | Uso |
|---------|-----|
| `anyjobs-deploy.sh` | Copiar al servidor como `/usr/local/sbin/anyjobs-deploy` (ejecutable). Lo invocan los workflows de front/back. |
| `docker-compose.registry.example.yml` | Base del `docker-compose.yml` en `/opt/anyjobs/{staging,production}/`. |
| `env.staging.example` / `env.production.example` | Plantillas de `.env` por entorno. |
| `env.backend.example` | Plantilla de `.env.backend` (secretos del API en el VPS). |

## En el servidor

1. Directorios: `/opt/anyjobs/staging` y `/opt/anyjobs/production` con compose + `.env` reales (no commitear secretos).
2. `docker login ghcr.io` si las imágenes son privadas.
3. Instalar el script: ver comentarios al inicio de `vps/anyjobs-deploy.sh`.

Este repositorio no contiene código de aplicación; solo infraestructura de despliegue.
