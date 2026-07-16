#!/bin/bash
set -e

# Run from the repo root regardless of where the script is invoked from.
cd "$(dirname "$0")/.."

# Pass --installers to also package installers (.dmg, .zip, .deb) after building.
BUILD_INSTALLERS=0
if [[ "$1" == "--installers" ]]; then
  BUILD_INSTALLERS=1
fi

# Frontend is pre-built and embedded from cmd/frontend (go:embed) — no npm build step.

# Cross-compile for all platforms/architectures
# Note: darwin builds must match native arch due to systray C bindings
NATIVE_ARCH=$(uname -m)
if [[ "$NATIVE_ARCH" == "arm64" ]] || [[ "$NATIVE_ARCH" == "aarch64" ]]; then
  DARWIN_ARCH="arm64"
else
  DARWIN_ARCH="amd64"
fi

TARGETS=(
  "darwin/${DARWIN_ARCH}"
  "linux/amd64"
  "linux/arm64"
  "linux/arm"
  "windows/amd64"
  "windows/arm64"
)

rm -rf build
mkdir -p build

for TARGET in "${TARGETS[@]}"; do
  OS="${TARGET%/*}"
  ARCH="${TARGET#*/}"
  OUT_DIR="build/${OS}_${ARCH}"
  mkdir -p "$OUT_DIR"

  BIN="systray-app"
  if [ "$OS" = "windows" ]; then
    BIN="systray-app.exe"
  fi

  echo "Building ${OS}/${ARCH}..."
  # darwin native build needs CGO (systray bindings); other targets cross-compile without CGO
  if [ "$OS" = "darwin" ]; then
    CGO=1
  else
    CGO=0
  fi
  CGO_ENABLED=$CGO GOOS="$OS" GOARCH="$ARCH" go build -o "${OUT_DIR}/${BIN}" ./cmd
done

echo ""
echo "Builds complete:"
for TARGET in "${TARGETS[@]}"; do
  OS="${TARGET%/*}"
  ARCH="${TARGET#*/}"
  BIN="systray-app"
  [ "$OS" = "windows" ] && BIN="systray-app.exe"
  echo "  build/${OS}_${ARCH}/${BIN}"
done

# macOS: create .app bundle and .dmg (only works on macOS)
create_mac_installer() {
  local OS=$1
  local ARCH=$2
  local OUT_DIR="build/${OS}_${ARCH}"
  local APP_DIR="${OUT_DIR}/SystrayApp.app"

  mkdir -p "${APP_DIR}/Contents/MacOS"
  mkdir -p "${APP_DIR}/Contents/Resources"

  cp "${OUT_DIR}/systray-app" "${APP_DIR}/Contents/MacOS/systray-app"
  chmod +x "${APP_DIR}/Contents/MacOS/systray-app"

  cat > "${APP_DIR}/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>systray-app</string>
  <key>CFBundleIdentifier</key>
  <string>com.bhavekbudhia.systray-app</string>
  <key>CFBundleName</key>
  <string>SystrayApp</string>
  <key>CFBundleDisplayName</key>
  <string>SystrayApp</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.15</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST

  local DMG_NAME="systray-app_${OS}_${ARCH}.dmg"
  echo "Creating ${DMG_NAME}..."
  hdiutil create \
    -volname "SystrayApp" \
    -srcfolder "${APP_DIR}" \
    -ov \
    -format UDZO \
    "build/${DMG_NAME}" \
    > /dev/null
  echo "  build/${DMG_NAME}"
}

# Windows: create .zip with binary + PowerShell install script
create_windows_installer() {
  local OS=$1
  local ARCH=$2
  local OUT_DIR="${OS}_${ARCH}"
  local ZIP_NAME="systray-app_${OS}_${ARCH}.zip"

  echo "Creating ${ZIP_NAME}..."
  cp installers/windows/install.ps1 "build/${OUT_DIR}/install.ps1"
  (cd build && zip -q -j "${ZIP_NAME}" "${OUT_DIR}/systray-app.exe" "${OUT_DIR}/install.ps1")
  echo "  build/${ZIP_NAME}"
}

# Linux: create .deb package (requires dpkg-deb, only works on Linux)
create_linux_deb() {
  local ARCH=$1
  local DEB_ARCH
  case "$ARCH" in
    amd64) DEB_ARCH="amd64" ;;
    arm64) DEB_ARCH="arm64" ;;
    arm)   DEB_ARCH="armhf" ;;
    *)     DEB_ARCH="$ARCH" ;;
  esac

  local PKG_DIR="build/deb_pkg_linux_${ARCH}"
  rm -rf "$PKG_DIR"
  mkdir -p "${PKG_DIR}/DEBIAN"
  mkdir -p "${PKG_DIR}/usr/local/bin"
  mkdir -p "${PKG_DIR}/usr/share/applications"

  cp "build/linux_${ARCH}/systray-app" "${PKG_DIR}/usr/local/bin/"
  chmod +x "${PKG_DIR}/usr/local/bin/systray-app"
  cp installers/linux/systray-app.desktop "${PKG_DIR}/usr/share/applications/"

  cat > "${PKG_DIR}/DEBIAN/control" << EOF
Package: systray-app
Version: 1.0.0
Architecture: ${DEB_ARCH}
Maintainer: Bhavek Budhia <bhavek.budhia@gmail.com>
Description: Go + Next.js tray app
 A system tray application serving an embedded Next.js frontend
 over a local Go HTTP server.
EOF

  local DEB_NAME="systray-app_linux_${DEB_ARCH}.deb"
  dpkg-deb --build "$PKG_DIR" "build/${DEB_NAME}"
  rm -rf "$PKG_DIR"
  echo "  build/${DEB_NAME}"
}

if [[ "$BUILD_INSTALLERS" != "1" ]]; then
  exit 0
fi

echo ""
echo "Creating installers:"

if [[ "$(uname)" == "Darwin" ]]; then
  create_mac_installer darwin "${DARWIN_ARCH}"
else
  echo "  Skipping macOS DMG (requires macOS build host)"
fi

create_windows_installer windows amd64
create_windows_installer windows arm64

if command -v dpkg-deb &> /dev/null; then
  create_linux_deb amd64
  create_linux_deb arm64
  create_linux_deb arm
else
  echo "  Skipping Linux .deb (dpkg-deb not found — run on a Linux host)"
fi
