# How it works

## One compose project per site

Every project folder is its own compose project, named `site-<name>`, with two services:

| Service | Container | Image | Runs when |
|---------|-----------|-------|-----------|
| `web` | `site-<name>-web` | `nginx:alpine` | `sites start` / `sites tunnel` |
| `tunnel` | `site-<name>-tunnel` | `cloudflare/cloudflared` | only with the `tunnel` profile (`sites tunnel`) |

```
browser ──► 127.0.0.1:PORT ──► site-<name>-web (nginx :80) ──► <name>/public/  (bind mount, read-only)
                                      ▲
internet ──► https://….trycloudflare.com ──► Cloudflare ──► site-<name>-tunnel ──┘  (http://web:80)
```

The tunnel container makes an **outbound** connection to Cloudflare. You don't need to open router ports or a firewall, and you don't need a certificate. Cloudflare handles HTTPS.

`podman-compose` creates a network for each project (`site-<name>_default`), and the tunnel reaches nginx on it by the service name `web`.

## Finding projects: the registry

Projects can live in any folder, so `sites` keeps a list of them in `~/.config/sites/projects`, one `name<TAB>path` per line:

- `sites new` adds an entry.
- Running a command inside a project folder fixes the entry if the folder has moved.
- Entries whose folder no longer has `compose.yaml` and `.env` are ignored and pruned.

It's plain text, so you can edit or delete it safely. Re-add a project with `sites new -y` inside its folder.

## Config: `.env`

```ini
NAME=blog        # used for container names
PORT=8081        # host port
BIND=127.0.0.1   # which host address to listen on
```

- `BIND=127.0.0.1` (the default) means only this computer can connect. The Android emulator also works, through `10.0.2.2`.
- `BIND=0.0.0.0` also lets other devices on your LAN connect, such as a real phone at `http://<your-LAN-IP>:PORT`.

Run `sites restart <name>` after you change `.env`.

## Mounts: `.mounts` and `compose.mounts.yaml`

`sites mount` writes one line per mount to `.mounts` (`kind<TAB>source<TAB>container-target<TAB>mode`), then regenerates `compose.mounts.yaml`:

```yaml
services:
  web:
    volumes:
      - "/home/you/Pictures:/usr/share/nginx/html/photos:ro"
volumes:
  uploads:
    external: true
```

`sites` passes `-f compose.yaml -f compose.mounts.yaml` to podman-compose, so the generated file is layered on top of your `compose.yaml` and never changes it. Named volumes are created with `podman volume create` and marked `external`, so `sites stop` never deletes their data.

URL-path mounts land under nginx's web root (`/usr/share/nginx/html/<path>`). Because `public/` is mounted read-only, `sites mount` creates an empty placeholder (`public/<path>`) to act as the mountpoint.

On SELinux hosts, bind mounts get the shared `:z` label. Everywhere else, no label option is added.

## The template

`sites new` copies `_template/` exactly, then replaces:

- `{{NAME}}` with the project name
- `{{PORT}}` with the chosen port

To change what new projects look like (a starter CSS file, a different nginx image, extra services), edit `_template/`. Projects you've already created keep their own copy and aren't affected.

### Custom nginx config (optional)

To get SPA fallback, custom headers and so on, add `nginx.conf` to a project and mount it in that project's `compose.yaml`:

```yaml
    volumes:
      - ./public:/usr/share/nginx/html:ro,Z
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro,Z
```

Example `nginx.conf` for a single-page app:

```nginx
server {
  listen 80;
  root /usr/share/nginx/html;
  location / { try_files $uri $uri/ /index.html; }
}
```

## Why `:Z` on the volume?

On SELinux systems (Fedora, RHEL), `:Z` relabels the folder so the container can read it. On Ubuntu it does nothing, and it's there so the template works on both.

## Turning an existing folder into a project

```bash
cd ~/Documents/sites/hello-world
sites new -y                 # adds compose.yaml, .env, public/ (keeps your files)
mv index.html public/        # only public/ is served
sites start
```
