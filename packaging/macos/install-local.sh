#!/usr/bin/env bash
# Assemble FilmCraft.app from an existing local release build and install it to ~/Applications
# so Spotlight / Launchpad / the Dock can find it. Ad-hoc signed; for personal use only.
#
#   cargo build --release -p filmcraft -p filmcraft-cli && packaging/macos/install-local.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HERE="$ROOT/packaging/macos"
BIN="${CARGO_TARGET_DIR:-$ROOT/target}/release/filmcraft"
DEST="${1:-$HOME/Applications}"
APP="$DEST/FilmCraft.app"
[ -x "$BIN" ] || { echo "error: $BIN not found (cargo build --release -p filmcraft)" >&2; exit 1; }
VERSION="$(awk '/^\[/{p=($0=="[workspace.package]");next} p&&$1=="version"{gsub(/[" ]/,"",$3);print $3;exit}' "$ROOT/Cargo.toml")"
SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo local)"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/FilmCraft"
cp "$ROOT/assets/app-icon/filmcraft.icns" "$APP/Contents/Resources/FilmCraft.icns"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@SHORT_VERSION@/${VERSION%%-*}/g" -e "s/@BUILD_SHA@/$SHA/g" \
  "$HERE/Info.plist.in" >"$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist"
printf 'APPL????' >"$APP/Contents/PkgInfo"
codesign --force --sign - --timestamp=none --entitlements "$HERE/entitlements.plist" "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
mdimport "$APP" 2>/dev/null || true
echo "installed $APP"
