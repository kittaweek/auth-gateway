# auth-gateway

A generic authentication gateway using [Dex](https://dexidp.io/) as an identity broker and [OAuth2 Proxy](https://oauth2-proxy.github.io/oauth2-proxy/) to protect upstream services. Supports login via Google and Microsoft out of the box.

## Architecture

```text
Browser → Reverse Proxy (Caddy/Nginx)
               ├── app-a domain → OAuth2 Proxy (4180) → App A
               └── app-b domain → OAuth2 Proxy (4181) → App B
                                           ↓
                                          Dex
                                        ↙    ↘
                                   Google    Microsoft
```

Each app has its own OAuth2 Proxy instance. All services share a Docker network (`shared-proxy`) so they can communicate with each other and with the reverse proxy host.

## Prerequisites

- Docker and Docker Compose
- A reverse proxy (Caddy or Nginx) running on the VM with SSL termination
- OAuth2 app credentials from Google and/or Microsoft
- DNS records pointing your domains to the VM

## Setup

### 1. Copy and fill in the environment file

```bash
cp .env.example .env
```

Edit `.env` with your actual domains, upstream URLs, and secrets. Generate cookie secrets with:

```bash
openssl rand -hex 16
```

### 2. Copy and configure Dex

```bash
cp dex-config.yaml.example dex-config.yaml
```

Fill in your Google and Microsoft OAuth2 credentials, and set the correct domains for `staticClients` redirect URIs. The values in `dex-config.yaml` must match `APP_A_CLIENT_SECRET` and `APP_B_CLIENT_SECRET` in your `.env`.

### 3. Set up the allowed emails list

```bash
cp emails.txt.example emails.txt
```

Add one email address per line. Only users whose email appears in this file will be granted access.

### 4. Create the shared Docker network

```bash
docker network create shared-proxy
```

Skip this step if the network already exists.

### 5. Start the services

```bash
docker compose up -d
```

## Reverse Proxy Configuration

### Caddyfile example

```caddy
app-a.example.com {
    reverse_proxy 127.0.0.1:4180
}

app-b.example.com {
    reverse_proxy 127.0.0.1:4181
}
```

OAuth2 Proxy handles authentication and forwards authenticated requests to the upstream app. You do not need to expose Dex or the upstream apps directly.

## Adding a New App

1. Add a new `oauth2-proxy-<app-name>` service in `docker-compose.yml`, binding a new host port (e.g. `127.0.0.1:4182:4180`).
2. Add the corresponding env variables to `.env.example` and `.env`.
3. Add a new `staticClient` entry in `dex-config.yaml` with a matching `id`, `secret`, and `redirectURI`.
4. Add a new virtual host block in your reverse proxy config.
5. Restart: `docker compose up -d`.

## Troubleshooting

View logs for all services:

```bash
docker compose logs -f
```

View logs for a specific service:

```bash
docker compose logs -f dex
docker compose logs -f oauth2-proxy-app-a
docker compose logs -f oauth2-proxy-app-b
```

Common issues:

- **"Email not in list"** — Add the user's email to `emails.txt` and restart the affected proxy: `docker compose restart oauth2-proxy-app-a`
- **OIDC discovery errors** — Ensure Dex is running and reachable from the OAuth2 Proxy containers on the `shared-proxy` network.
- **Redirect URI mismatch** — The `redirectURI` in `dex-config.yaml` static clients must exactly match the `OAUTH2_PROXY_REDIRECT_URL` in your `.env`.
