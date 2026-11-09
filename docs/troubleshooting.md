# Troubleshooting

### `podman-compose not found`
```bash
sudo apt install podman-compose
```

### `port 8081 is already used` / the site won't start
Something else is listening on that port. To find it:
```bash
ss -ltnp 'sport = :8081'
```
Change `PORT=` in `<name>/.env`, then run `sites restart <name>`.

### `no tunnel URL after 30s`
Look at the tunnel logs:
```bash
sites logs <name> --tunnel
```
- If you see network or DNS errors, check that the machine can reach the internet (`curl -I https://www.cloudflare.com`).
- If Cloudflare is slow or rate-limiting quick tunnels, wait a bit and retry, or set `SITES_TUNNEL_WAIT=60`.

### The tunnel URL shows `502 Bad Gateway`
The tunnel is up, but it can't reach nginx. Check `sites status <name>`. If WEB shows stopped, run `sites restart <name>` and then `sites tunnel <name>`.

### My edits don't show up
- Edit files inside `<name>/public/`, which is the folder nginx serves.
- Hard-refresh (Ctrl+Shift+R). Browsers, WebViews and Cloudflare can cache static files for a short time.
- Some editors save by replacing the file. If you edited a file you mounted on its own (like `nginx.conf`), run `sites restart <name>`. Folder mounts like `public/` aren't affected.

### `403 Forbidden`
- There's no `index.html` in `public/` (nginx doesn't list directories by default).
- On SELinux systems, make sure the volume line still ends in `:Z`.

### Phone on Wi-Fi can't connect
Set `BIND=0.0.0.0` in `.env`, run `sites restart <name>`, and allow the port through your firewall if you use one (`sudo ufw allow 8081/tcp`). Or skip all of that and use `sites tunnel`.

### Clean up everything
```bash
sites stop --all
podman image rm docker.io/library/nginx:alpine docker.io/cloudflare/cloudflared:latest
```
