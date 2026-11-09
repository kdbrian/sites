# sites

A small bash CLI for running local static websites with **Podman**. Each site:

- is served by nginx from a folder you edit directly (refresh to see changes)
- starts and stops on demand
- can get a temporary public **HTTPS** URL with one command (Cloudflare quick tunnel, no account needed)

```
$ cd ~/projects && sites new blog      # creates ./blog/
✓ created blog  (port 8081)
$ sites tunnel blog
✓ local:  http://127.0.0.1:8081
✓ public: https://quiet-river-1234.trycloudflare.com
```

## Requirements

| Tool | Install (Ubuntu) |
|------|------------------|
| podman | `sudo apt install podman` |
| podman-compose | `sudo apt install podman-compose` |

## Install

Put `sites` on your `PATH`:

```bash
mkdir -p ~/.local/bin
ln -s ~/Documents/sites/sites ~/.local/bin/sites
sites help
```

The symlink works from any directory: the script finds `_template/` through its own real location.

## Quick start

```bash
sites new myapp            # creates ./myapp/ in the current directory
cd myapp
$EDITOR public/index.html
sites start                # http://127.0.0.1:8081  (or: sites start . / ./myapp / myapp)
sites tunnel               # adds a public https://….trycloudflare.com URL
sites untunnel             # closes the public URL, keeps the local site
sites stop                 # stops everything for this project
sites status               # all projects, anywhere, and what's running
```

Three ways to create a project:

| Command | Creates the project in |
|---------|------------------------|
| `sites new blog` | `./blog/` |
| `sites new -y` | the current directory (named after the folder) |
| `sites new` | asks for a directory name; press Enter for the current directory |

## Commands

`[name]` can be a project name (`blog`), a path (`.`, `./blog`, `~/x/blog`), or left out to use the project folder you're in.

| Command | What it does |
|---------|--------------|
| `sites new [dir] [-y] [--name N] [--port N]` | Create a project from `_template/` |
| `sites start [name]` | Serve the project's `public/` folder locally |
| `sites stop [name]` / `--all` | Stop the site and its tunnel |
| `sites restart [name]` | Stop, then start |
| `sites tunnel [name]` | Start the site if needed, open an HTTPS tunnel, print the URL |
| `sites untunnel [name]` | Close the tunnel only |
| `sites url [name]` | Print local and public URLs |
| `sites open [name] [--public]` | Open in your browser |
| `sites status [name]` | List projects (alias `ls`) |
| `sites logs [name] [-t] [-f]` | Web logs (`-t` tunnel, `-f` follow) |
| `sites mount [name] <src>[:/url][:rw]` | Link a host folder/file or a Podman volume into the site |
| `sites unmount [name] <url\|src>` | Remove a mount |
| `sites mounts [name]` | List mounts |
| `sites help [command]` | Overview, or details for one command (also `sites <command> --help`) |

See [docs/commands.md](docs/commands.md) for details.

## Mounting host folders and volumes

```bash
sites mount ~/Pictures:/photos             # http://…/photos/ serves ~/Pictures (read-only)
sites mount ../shared-assets               # served at /shared-assets/
sites mount uploads:/uploads:rw            # named Podman volume (bare word = volume)
sites mount ./nginx.conf:/etc/nginx/conf.d/default.conf --raw   # any container path
sites mounts                               # list
sites unmount /photos                      # remove (host files are never touched)
```

Edits in a mounted folder show up live. If the site is running, the change is applied right away, and an open tunnel keeps its URL.

## Layout

The tool and template live here:

```
~/Documents/sites/
├── sites               # the CLI
├── README.md
├── docs/
└── _template/          # copied by `sites new`; edit it to change new projects
    ├── compose.yaml
    ├── .env
    └── public/index.html
```

A project can live anywhere you like:

```
wherever/myapp/
├── compose.yaml
├── .env            # NAME, PORT, BIND
├── .mounts         # extra mounts (managed by `sites mount`)
├── compose.mounts.yaml  # generated from .mounts
└── public/         # ← your site files
```

`sites` remembers where your projects are in `~/.config/sites/projects`, so `sites status` and `sites start <name>` work from any directory.

## Docs

- [docs/commands.md](docs/commands.md): full command reference
- [docs/how-it-works.md](docs/how-it-works.md): containers, networking, config, the template
- [docs/android-webview.md](docs/android-webview.md): loading these sites in an Android WebView
- [docs/troubleshooting.md](docs/troubleshooting.md): common problems

## Development

```bash
tests/smoke.sh          # no containers needed
tests/integration.sh    # needs podman + podman-compose
```

CI (`.github/workflows/verify.yml`) runs shellcheck, the smoke tests and the integration tests on every push and pull request.

## Security note

While a tunnel is open, **anyone with the URL can view everything in `public/`**. Don't put secrets there, and run `sites untunnel <name>` when you're done.
