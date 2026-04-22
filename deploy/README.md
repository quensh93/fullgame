# Production deploy

This setup assumes:

- host `nginx` is already installed on the Linux server
- Docker and Docker Compose are already available
- Cloudflare points your subdomain to the server

## Files

- `docker-compose.prod.yml`
- `.env.prod.example`
- `deploy/nginx-subdomain.conf.example`
- `deploy/nginx-subdomain.cloudflare-origin.conf.example`
- `deploy/nginx-subdomain.http-only.conf.example`

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

Choose one of these TLS paths:

- Cloudflare proxy + Cloudflare Origin CA on the server
- Let's Encrypt on the origin server

### Option A. Cloudflare proxy + Origin CA

Recommended when your DNS record stays proxied through Cloudflare.

Use `deploy/nginx-subdomain.cloudflare-origin.conf.example` as the template for your subdomain.

```bash
sudo mkdir -p /etc/ssl/cloudflare
sudo cp deploy/nginx-subdomain.cloudflare-origin.conf.example /etc/nginx/sites-available/game.example.com
sudo ln -s /etc/nginx/sites-available/game.example.com /etc/nginx/sites-enabled/game.example.com
sudo nginx -t
sudo systemctl reload nginx
```

Adjust:

- `server_name`
- SSL certificate paths for the Cloudflare Origin CA certificate and key
- local ports if you changed `HOST_BACKEND_PORT` or `HOST_FRONTEND_PORT`

### Option B. Let's Encrypt on the origin

Recommended when clients may connect directly to the origin or you do not want to depend on Cloudflare proxying.

Bootstrap with HTTP first:

```bash
sudo mkdir -p /var/www/certbot
sudo cp deploy/nginx-subdomain.http-only.conf.example /etc/nginx/sites-available/game.example.com
sudo ln -s /etc/nginx/sites-available/game.example.com /etc/nginx/sites-enabled/game.example.com
sudo nginx -t
sudo systemctl reload nginx
```

Issue the certificate:

```bash
sudo certbot certonly --webroot -w /var/www/certbot -d game.example.com
```

Then switch to the HTTPS template:

```bash
sudo cp deploy/nginx-subdomain.conf.example /etc/nginx/sites-available/game.example.com
sudo nginx -t
sudo systemctl reload nginx
```

Adjust:

- `server_name`
- Let's Encrypt certificate paths
- local ports if you changed `HOST_BACKEND_PORT` or `HOST_FRONTEND_PORT`

## 4. Cloudflare

- Point the subdomain to the server IP
- Keep WebSocket support enabled
- If you use Cloudflare Origin CA, keep the DNS record proxied and use SSL mode `Full (strict)`
- If you use Let's Encrypt on the origin, `Full (strict)` is still the correct SSL mode

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
- `DEPLOY_SSH_KEY_PATH` (optional, defaults to `~/.ssh/id_ed25519`)
- `DEPLOY_BOOTSTRAP_SSH_KEY` (optional, repairs `authorized_keys` on the server if key login stopped working)
- `DEPLOY_SSH_PASSWORD_FALLBACK` (optional, uses one password prompt for the whole deploy when the SSH key cannot be unlocked)
- `DEPLOY_FORCE_PASSWORD_AUTH` (optional, skips the local SSH key entirely and uses one password prompt from the start)
- `DEPLOY_REMOTE_PULL_RETRIES` (optional, retries pulling runtime base images on the server)

What the deploy script now does automatically:

- loads your SSH key into `ssh-agent` once, so the passphrase is not requested for every `ssh` or `rsync`
- reuses one SSH control connection across all deploy steps
- fixes the remote `~/.ssh/authorized_keys` entry when password login still works but key login broke
- keeps the runtime images on your configured registry mirror, with optional override via:
  - `BACKEND_RUNTIME_BASE_IMAGE`
  - `FRONTEND_RUNTIME_BASE_IMAGE`
- pre-pulls runtime base images on the server with retries before rebuilding containers

Then deploy:

```bash
./scripts/deploy_server.sh
```

## 7. Replace a certificate later

If you renew a certificate on another machine and only need to copy it to the server and reload nginx:

```bash
./scripts/install_remote_tls_cert.sh \
  game.example.com \
  /tmp/game-fullchain.pem \
  /tmp/game-privkey.pem
```

The script reads SSH settings from `.deploy.env`, installs the files under `/etc/ssl/<domain>/`, verifies the nginx site points to those paths, then runs `nginx -t` and reloads the service.
