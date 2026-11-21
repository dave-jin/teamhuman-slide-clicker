#!/usr/bin/env bash
# Build Auto Clicker.app for macOS.
# Linux/CI cannot produce a .app — run this on a Mac.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

die() {
  echo "error: $*" >&2
  exit 1
}

# --- Platform guard -----------------------------------------------------------
OS="$(uname -s 2>/dev/null || true)"
if [[ "$OS" != "Darwin" ]]; then
  cat >&2 <<EOF
error: This script builds a macOS .app and must run on a Mac (Darwin).
       Current OS: ${OS:-unknown}

On your Mac (≈2–3 min):
  git pull
  chmod +x scripts/build-app.sh
  ./scripts/build-app.sh
  open "dist/Auto Clicker.app"
  # or: cp -R "dist/Auto Clicker.app" /Applications/
  # or Dropbox: ~/Dropbox/PARA/0.\\ Inbox/
EOF
  exit 1
fi

# --- Toolchain ----------------------------------------------------------------
# Works with full Xcode OR Command Line Tools only (no SwiftUIMacros plugins).
# Sources intentionally avoid @State / @StateObject so CLT `swift build` succeeds.
if ! command -v swift >/dev/null 2>&1; then
  die "swift not found. Install Xcode or Command Line Tools:
  xcode-select --install"
fi

if ! xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1; then
  die "macOS SDK missing. Open Xcode once or run: xcode-select --install"
fi

SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
echo "Toolchain: $(swift --version 2>/dev/null | head -1 || echo swift)"
echo "SDK: ${SDK_PATH:-unknown}"
if [[ "$SDK_PATH" == *CommandLineTools* ]]; then
  echo "Note: building with Command Line Tools (no full Xcode) — OK for this project."
fi

CONFIG="${1:-release}"
case "$CONFIG" in
  release|debug) ;;
  *) die "unknown config '$CONFIG' (use release or debug)" ;;
esac

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist" 2>/dev/null || echo '?')"
BUILD="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$ROOT/Resources/Info.plist" 2>/dev/null || echo '?')"
echo "Building Auto Clicker ${VERSION} (build ${BUILD}), config=${CONFIG}…"

# --- Compile ------------------------------------------------------------------
swift build -c "$CONFIG" || die "swift build failed"

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN="$BIN_DIR/AutoClicker"
[[ -x "$BIN" ]] || die "binary missing after build: $BIN"

DIST="$ROOT/dist"
APP="$DIST/Auto Clicker.app"

rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/AutoClicker"
chmod +x "$APP/Contents/MacOS/AutoClicker"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"
if [[ -f "$ROOT/Resources/AppIcon.icns" ]]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign so Accessibility can target a stable bundle identity locally.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" >/dev/null 2>&1 \
    || echo "warning: ad-hoc codesign failed (app may still run)" >&2
fi

# Sanity check bundle layout
[[ -x "$APP/Contents/MacOS/AutoClicker" ]] || die "app binary not executable"
[[ -f "$APP/Contents/Info.plist" ]] || die "Info.plist missing from app bundle"

echo ""
echo "Built: $APP"
echo "Version ${VERSION} (build ${BUILD})"
echo ""
echo "Open:   open \"$APP\""
echo "Install: cp -R \"$APP\" /Applications/"
echo "Inbox:   cp -R \"$APP\" \"\$HOME/Dropbox/PARA/0. Inbox/\""
echo ""
echo "First launch: right-click → Open if Gatekeeper warns."
echo "Then enable Accessibility for Auto Clicker."
