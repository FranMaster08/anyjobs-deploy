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

## Secrets en GitHub (VPS)

Los workflows de **anyjobs-backend** y **anyjobs-front** usan el job `deploy` con **Environment** `staging` (rama `develop`) y `production` (rama `main`).

Define en cada repositorio, en **Settings → Environments → staging / production → Environment secrets**, como mínimo:

- **`VPS_HOST`**, **`VPS_USER`**, **`VPS_SSH_PRIVATE_KEY`**
- Opcionales: **`VPS_SSH_PORT`**, **`VPS_DEPLOY_SCRIPT`**, **`ANYJOBS_DEPLOY_ROOT`**

Si un nombre no existe en el Environment, GitHub sigue pudiendo resolver el secret a nivel **repositorio** (mismo nombre). No crees secrets de entorno vacíos: anulan el valor del repo.

### Copiar valores al entorno desde tu máquina

GitHub **no** permite leer de vuelta el valor de un secret. Para subir los mismos valores a `staging` y `production` en ambos repos con la CLI:

```bash
cd /ruta/anyjobs-deploy
cp scripts/vps-secrets.env.example scripts/vps-secrets.env
# edita scripts/vps-secrets.env (host, usuario, opcionales)
chmod +x scripts/sync-vps-secrets-to-github-environments.sh
./scripts/sync-vps-secrets-to-github-environments.sh scripts/vps-secrets.env ~/.ssh/tu_clave_vps
```

(`vps-secrets.env` está en `.gitignore`.)

Este repositorio no contiene código de aplicación; solo infraestructura de despliegue.
