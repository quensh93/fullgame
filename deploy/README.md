# Production deploy

This setup assumes:

- host `nginx` is already installed on the Linux server
- Docker and Docker Compose are already available
- Cloudflare points your subdomain to the server

## Files

- `docker-compose.prod.yml`
- `.env.prod.example`
- `deploy/nginx-subdomain.conf.example`

## 1. Prepare env

Copy `.env.prod.example` to `.env.prod` and set at least:

- `APP_DOMAIN`
- `DB_PASSWORD`
- `JWT_SECRET`

Generate a strong JWT secret, for example:

```bash
openssl rand -base64 48
```

## 2. Start containers

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Useful checks:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml ps
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f backend
docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f frontend
curl http://127.0.0.1:18081/healthz
curl http://127.0.0.1:18080/api/home/platform-stats
```

## 3. Configure nginx on the host

Use `deploy/nginx-subdomain.conf.example` as the template for your subdomain.

Example steps:

```bash
sudo cp deploy/nginx-subdomain.conf.example /etc/nginx/sites-available/game.example.com
sudo ln -s /etc/nginx/sites-available/game.example.com /etc/nginx/sites-enabled/game.example.com
sudo nginx -t
sudo systemctl reload nginx
```

Adjust:

- `server_name`
- SSL certificate paths
- local ports if you changed `HOST_BACKEND_PORT` or `HOST_FRONTEND_PORT`

## 4. Cloudflare

- Point the subdomain to the server IP
- Use SSL mode `Full (strict)` if your origin certificate is ready
- Keep WebSocket support enabled

## 5. Update later

After new code:

```bash
git pull
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

## 6. Deploy from local machine

The easiest path for constrained servers is:

- build backend jar locally
- build frontend dist locally
- sync artifacts to the server
- rebuild only runtime images on the server

Files involved:

- `.deploy.env.example`
- `scripts/deploy_server.sh`
- `gameBackend/Dockerfile.runtime`
- `gameweb/Dockerfile.runtime`

Setup:

```bash
cp .deploy.env.example .deploy.env
```

Set in `.deploy.env`:

- `DEPLOY_SSH_HOST`
- `DEPLOY_SSH_USER`
- `DEPLOY_REMOTE_DIR`
- `DEPLOY_ENV_FILE`

Then deploy:

```bash
./scripts/deploy_server.sh
```
