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
- Directorio del compose: si no defines el secret **`ANYJOBS_DEPLOY_ROOT`**:
  - staging → `$HOME/entorno-staging`
  - production → `$HOME/entorno-production`

**Un solo stack** (misma carpeta para ambas ramas): en GitHub, en los environments `staging` y `production`, define **`ANYJOBS_DEPLOY_ROOT`** con la misma ruta absoluta (p. ej. `/root/entorno`).

**Atajo** (mismo contenido en dos rutas): en el VPS, `ln -s ~/entorno ~/entorno-staging` y `ln -s ~/entorno ~/entorno-production` (solo tiene sentido si aceptas un único `.env`; no separa datos entre entornos).

Si **no** usas `ANYJOBS_DEPLOY_ROOT`, el script cae en `/opt/anyjobs/<staging|production>` (layout clásico).

## En el servidor

1. Carpetas con `docker-compose.yml` + `.env` (líneas `ANYJOBS_BACK_IMAGE=` y `ANYJOBS_FRONT_IMAGE=`).
2. `docker login ghcr.io` si las imágenes GHCR son privadas.
3. Servicios en compose con nombres **`anyjobs-back`** y **`anyjobs-front`**.

Este repositorio no contiene código de aplicación; solo infraestructura de despliegue.
