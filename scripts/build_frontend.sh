#!/bin/bash
set -e

# Run from the repo root regardless of where the script is invoked from.
cd "$(dirname "$0")/.."

# ============================================================================
# PLACEHOLDER — fill this in with your frontend build steps.
#
# Requirements:
#   - The final static build output MUST end up in cmd/frontend/out/
#     (that folder is embedded into the Go binary via go:embed, see
#     cmd/main.go). It must contain an index.html at its root.
#   - Run this script BEFORE `make build` so the binary embeds fresh assets.
#
# Example (Next.js static export):
#   cd my-frontend
#   npm ci
#   npm run build          # with `output: 'export'` in next.config.js
#   rm -rf ../cmd/frontend/out
#   cp -R out ../cmd/frontend/out
#
# Example (Vite):
#   cd my-frontend
#   npm ci
#   npm run build
#   rm -rf ../cmd/frontend/out
#   cp -R dist ../cmd/frontend/out
# ============================================================================

echo "scripts/build_frontend.sh is a placeholder — add your frontend build steps here."
echo "Output must land in cmd/frontend/out/ (with an index.html at its root)."
exit 1
