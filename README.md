# systray-app

A Go system-tray app that serves an embedded static frontend and a JSON API on `:8080`.

## Quick start

```bash
make run          # start the app (Go tray + embedded frontend on :8080)
make build        # cross-compile binaries for all platforms
make installers   # build installers (macOS .dmg, Windows .zip, Linux .deb)
```

## Adding a frontend

The app serves static files embedded into the binary from **`cmd/frontend/out/`** (via `go:embed` in `cmd/main.go`). Anything in that folder is baked into the binary at build time and served at `http://localhost:8080/`.

To add your own frontend:

1. **Create your frontend project** anywhere you like (e.g. a `frontend/` folder at the repo root). Any framework works as long as it can produce a fully static build — Next.js (static export), Vite, Create React App, plain HTML/CSS/JS, etc.

2. **Fill out `scripts/build_frontend.sh`.** It is a placeholder — add the commands that build your frontend and copy the result into `cmd/frontend/out/`. The script already `cd`s to the repo root, and the file contains commented examples for Next.js and Vite.

   > **Important:** the build output **must** land in `cmd/frontend/out/` and contain an `index.html` at its root. That exact path is what `go:embed` picks up.

3. **Build the frontend, then the binary:**

   ```bash
   ./scripts/build_frontend.sh
   make build
   ```

   Run `build_frontend.sh` before every `make build` where frontend code changed — the Go binary embeds whatever is in `cmd/frontend/out/` at compile time.

4. **Call the API from your frontend** at relative paths under `/api/...`. API routes are registered in `cmd/apps/` (see `apps/healthcheck` for an example) and take priority over static files.

### Notes

- Client-side routing: the server is a plain file server, so deep links only work for paths that exist as files. Prefer hash routing or frameworks that emit one HTML file per route (e.g. Next.js static export).
- The server binds to `0.0.0.0:8080`, so the frontend is also reachable from other machines on the network.
