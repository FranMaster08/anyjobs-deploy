# anyjobs-deploy

Plantillas y script para desplegar **Anyjobs** en un VPS con Docker Compose y GitHub Actions (GHCR).

## Contenido (`vps/`)

| Archivo | Uso |
|---------|-----|
| `anyjobs-deploy.sh` | Copiar al servidor (p. ej. `~/entorno/anyjobs-deploy`), `chmod +x`. Lo invocan los workflows. |
| `docker-compose.registry.example.yml` | Base del `docker-compose.yml` en el directorio de cada entorno. |
| `env.staging.example` / `env.production.example` | Plantillas de `.env` por entorno. |
| `env.backend.example` | Plantilla de `.env.backend` (secretos del API en el VPS). |

## Rutas por defecto (workflows front/back)

- Script: `bash "$HOME/entorno/anyjobs-deploy"` (secret **`VPS_DEPLOY_SCRIPT`** para otra ruta).
- Directorio del compose sin secret **`ANYJOBS_DEPLOY_ROOT`**:
  1. Si existe `$HOME/entorno-staging` o `$HOME/entorno-production` (según el job), se usa esa carpeta.
  2. Si no, se usa **`$HOME/entorno`** (un solo stack para staging y production).

Para forzar siempre una ruta concreta, define el secret **`ANYJOBS_DEPLOY_ROOT`** en cada environment de GitHub.

Si **no** usas `ANYJOBS_DEPLOY_ROOT`, el script cae en `/opt/anyjobs/<staging|production>` (layout clásico).

## En el servidor

1. Carpetas con `docker-compose.yml` + `.env` (líneas `ANYJOBS_BACK_IMAGE=` y `ANYJOBS_FRONT_IMAGE=`).
2. `docker login ghcr.io` si las imágenes GHCR son privadas.
3. Servicios en compose con nombres **`anyjobs-back`** y **`anyjobs-front`**.

## Error `missing server host` o “Faltan VPS_HOST…”

Los workflows leen **`VPS_HOST`**, **`VPS_USER`** y **`VPS_SSH_PRIVATE_KEY`** desde **Repository secrets** (Settings → Secrets and variables → Actions → **Secrets** del repositorio, no solo del Environment).

El job de deploy **no** usa `environment:` para no mezclar con secrets de Environment vacíos que tapen los del repo.

Este repositorio no contiene código de aplicación; solo infraestructura de despliegue.
