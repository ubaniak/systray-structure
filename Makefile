.PHONY: run build installers installer help

help:
	@echo "Available targets:"
	@echo "  make run             - Start the app (Go tray + embedded frontend on :8080)"
	@echo "  make build           - Cross-compile binaries for all platforms"
	@echo "  make installers      - Build all installers (macOS .dmg, Windows .zip, Linux .deb)"

run:
	go run ./cmd

build:
	./scripts/build.sh

installers:
	./scripts/build.sh --installers

installer: installers
