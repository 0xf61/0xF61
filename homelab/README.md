# 0xF61 Homelab

Self-hosted stack on a Raspberry Pi 5 (8GB). Boots from NVMe, data lives on a 1TB HDD.

## Layout

Each service has its own directory:

```
/mnt/hdd/<service>/
  compose.yml   # versioned
  ahu.env       # versioned — secrets are pass:// references only
  data/         # runtime data — never versioned
```

Shared variables (`BASEPATH`, `DOMAIN`) live in `/mnt/hdd/.env.global` (a clean template is committed; see the note below about Arcane). `manage.fish` feeds it to every service alongside `ahu.env`; `DOMAIN` also feeds museum's apps URLs via compose env interpolation.

Secrets (including public API keys) live in Proton Pass; `pass run` resolves them only at compose up (recreate) time. Since env is baked into containers, reboots do not need Pass at all (`restart: unless-stopped` everywhere).

## Management

```fish
./manage.fish up    # fast start (no image pull)
./manage.fish upp   # full run (--pull always)
./manage.fish down  # take everything down
```

## Services

| Service | Purpose |
|---|---|
| caddy | reverse proxy, TLS (DNS-01) |
| cloudflareTunnel | public access (Cloudflare Tunnel) |
| hermes | AI assistant gateway (Telegram) |
| my-ente | ente (museum/postgres/silo/web) |
| n8n | automation |
| arcane | compose management panel |
| silverbullet | markdown knowledge-base (notes) |
| ollama | local LLM (gemma4:e2b, preloaded at boot) |
| zerobyte | /mnt/hdd backups |

## Forking notes

- `.env.global` is partially managed by Arcane (notification bots): it may re-add bot secrets into the working copy after stack restarts. The repo copy is kept secret-free — never commit the regenerated lines.
- Hermes needs `TELEGRAM_CHAT_ID` at first boot (fresh `data/`): put it in `.env.global` or a Proton Pass item referenced from `hermes/ahu.env`.
- `caddy/Caddyfile` uses `{$DOMAIN}` placeholders — the domain comes from `.env.global`.
- `my-ente/museum.yaml` apps URLs (`public-albums`, `public-locker`) are configured via `ENTE_APPS_PUBLIC_ALBUMS` / `ENTE_APPS_PUBLIC_LOCKER` env vars in compose (using `${DOMAIN}`). The S3 endpoint (`minio.kurt.link`) in museum.yaml remains hardcoded — edit manually if needed.
- `arcane/compose.yml` sets `APP_URL` to the host's VPN (NetBird) IP — change it to whatever IP/DNS you use to reach the pi.
- `zerobyte` expects an rclone config at `/home/pi/.config/rclone`.
- `ollama/compose.yml` pins the preload model (`gemma4:e2b`) in its `post_start` hook — update it if you switch models.
- Secrets exist only as `pass://` references — create the matching Proton Pass items before running `./manage.fish up`.
