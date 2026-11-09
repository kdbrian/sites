# Command reference

To see help in the terminal: `sites help` gives the overview, and `sites help <command>` or `sites <command> --help` gives details for one command.

Project names must be lowercase letters, digits and dashes (for example `my-app`, `demo2`).

**Choosing a project: `[name|path]`.** Every command except `new` takes one of these:

| You type | Which project |
|----------|---------------|
| `sites start` | the project folder you're in, searching upward (also works from `public/css/`) |
| `sites start .` | same, explicitly |
| `sites start ./blog`, `../blog`, `~/x/blog`, `/abs/blog` | the project at that path (or the project folder above it) |
| `sites start blog` | the project registered as `blog`, from any directory |

Anything with a `/`, a leading `~`, `.` or `..` counts as a path. A bare word is looked up as a project name first, then as `./word` if no project has that name.

---

## `sites new [dir] [-y] [--name N] [--port N]`

Creates a project by copying `_template/` into a folder, then replaces `{{NAME}}` and `{{PORT}}` in the copied files.

| Command | Target folder |
|---------|---------------|
| `sites new blog` | `./blog/` (relative or absolute paths both work) |
| `sites new -y` | the current directory |
| `sites new` | asks: `Directory name (blank = current directory 'x'):` |

- **Name:** defaults to the folder name, lowercased, with other characters turned into `-` (`My Shop` becomes `my-shop`). Use `--name` to override it. Names must be unique, because they're used for container names.
- **Port:** if you leave out `--port`, it picks the first free port from **8081**. A port counts as taken if another project uses it or something is listening on it. It has to be between 1024 and 65535.
- **It never overwrites anything.** Template files that already exist in the folder, such as your own `public/index.html`, are left alone.
- **HTML at the folder root gets a warning.** Only `public/` is served, so move those files into it.
- **In a folder that's already a project,** it just re-registers it. Use this after moving or copying a project.
- **In a pipe or script,** `sites new` with no arguments gives an error instead of prompting, so pass a directory or `-y`.

```bash
sites new blog
sites new ~/work/api-docs --port 9000
cd ~/Documents/sites/hello-world && sites new -y
```

## `sites start [name|path]`

Runs `podman-compose up -d web` in the project folder. The site is served from `<name>/public/` at `http://<BIND>:<PORT>`.

The folder is bind-mounted read-only. **Your edits show up as soon as you refresh**, with no restart needed.

## `sites stop [name|path]` · `sites stop --all`

Runs `podman-compose --profile tunnel down`. This removes the web and tunnel containers and the project's network. Your files are never touched.

`--all` stops every project that has something running.

## `sites restart [name|path]`

Stops the project, then starts it again. Use it after you edit `.env` or `compose.yaml`.

## `sites tunnel [name|path]`

Starts the web container if it isn't running, then starts a `cloudflared` quick-tunnel container. It waits up to 30 seconds for the public URL and prints it:

```
✓ local:  http://127.0.0.1:8081
✓ public: https://some-random-words.trycloudflare.com
```

- **The URL is new every time the tunnel starts.**
- If a tunnel is already running, it just prints the current URL.
- Set `SITES_TUNNEL_WAIT=60` to wait longer.

## `sites untunnel [name|path]`

Removes only the tunnel container. The local site keeps running.

## `sites url [name|path]`

Prints the local URL and the public URL (if there is one).

## `sites open [name|path] [--public]`

Opens the local URL with `xdg-open`, and starts the site first if needed. `--public` opens the tunnel URL instead, if a tunnel is running.

## `sites status [name|path]` (alias `ls`, `list`)

```
PROJECT            PORT   WEB       TUNNEL                             PATH
blog               8081   running   https://….trycloudflare.com        ~/projects/blog
shop               8082   stopped   -                                  ~/work/shop
```

Projects whose folder has been deleted are dropped from the list automatically.

## `sites logs [name|path] [-t|--tunnel] [-f|--follow]`

Shows nginx access logs, or cloudflared logs with `-t`. `-f` keeps following them.

## `sites mount [name|path] <source>[:<url-path>][:ro|rw] [--rw] [--raw]`

Links a host folder or file, or a named Podman volume, into the site.

| Part | Meaning |
|------|---------|
| `source` | A host path (`./dir`, `../x`, `~/dir`, `/abs`, `./file.txt`) **or** a bare word, which is a named Podman volume (created if missing) |
| `url-path` | Where it appears on the site. Defaults to `/<basename of source>` |
| `ro` / `rw` | Read-only (the default) or read-write. `--rw` does the same |
| `--raw` | The target is a container path (e.g. `/etc/nginx/conf.d/default.conf`), not a URL path |

```bash
sites mount ~/Pictures:/photos
sites mount blog ~/Downloads/docs:/docs     # for project "blog", from anywhere
sites mount uploads:/uploads:rw
sites mount ./nginx.conf:/etc/nginx/conf.d/default.conf --raw
```

- **Mounting at a URL path that's already mounted** replaces the old mount.
- **An empty placeholder is added to `public/`** (e.g. `public/photos/`), because the mountpoint has to exist inside the read-only web root. `unmount` removes it if it's still empty. If `public/` already has files at that path, you get a warning that the mount will hide them.
- **It refuses to mount `/` or your whole home folder**, or anything over the site root `/`.
- **Changes apply right away if the site is running.** Only the web container is recreated, so a running tunnel keeps its URL.

## `sites unmount [name|path] <url-path|source>`

Removes a mount, matched by where it's mounted (`/photos`) or by its source (`~/Pictures`, or the volume name). Host files and volume data are never deleted. To delete a volume, use `podman volume rm <name>`.

## `sites mounts [name|path]`

Lists a project's extra mounts.

---

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `SITES_HOME` | folder containing the script | Where `_template/` and the docs are |
| `SITES_TEMPLATE` | `$SITES_HOME/_template` | Template folder copied by `sites new` |
| `SITES_REGISTRY` | `~/.config/sites/projects` | File listing known projects (`name<TAB>path`) |
| `SITES_BASE_PORT` | `8081` | First port tried by `sites new` |
| `SITES_TUNNEL_WAIT` | `30` | Seconds to wait for a tunnel URL |
