#!/usr/bin/env bash
set -euo pipefail
REPO="official-stockfish/Stockfish"
OUT_DIR="app/src/main/assets"
mkdir -p "$OUT_DIR"
echo "Querying GitHub releases for $REPO ..."
LATEST_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")
ASSET_URL=$(echo "$LATEST_JSON" | jq -r '.assets[] | select(.name | test("arm64|aarch64|android|armv8|arm64-v8a"; "i")) | .browser_download_url' | head -n 1)
if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    ASSET_URL=$(echo "$LATEST_JSON" | jq -r '.assets[] | select(.name | test("linux|aarch64|arm64"; "i")) | .browser_download_url' | head -n 1)
fi
if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    echo "No suitable asset found in latest release. Exiting."
    exit 2
fi
echo "Found asset: $ASSET_URL"
tmpfile=$(mktemp)
curl -L "$ASSET_URL" -o "$tmpfile"
filetype=$(file -b "$tmpfile" || true)
if echo "$ASSET_URL" | grep -Ei "\.zip$" >/dev/null || echo "$filetype" | grep -Ei "Zip archive" >/dev/null; then
    unzip -o "$tmpfile" -d "$OUT_DIR"
    exe=$(find "$OUT_DIR" -type f -perm -111 | head -n 1 || true)
    if [ -n "$exe" ]; then mv "$exe" "$OUT_DIR/stockfish"; chmod +x "$OUT_DIR/stockfish"; fi
elif echo "$ASSET_URL" | grep -Ei "\.tar\.gz|\.tgz$" >/dev/null || echo "$filetype" | grep -Ei "gzip compressed data" >/dev/null; then
    tar xzf "$tmpfile" -C "$OUT_DIR"
    exe=$(find "$OUT_DIR" -type f -perm -111 | head -n 1 || true)
    if [ -n "$exe" ]; then mv "$exe" "$OUT_DIR/stockfish"; chmod +x "$OUT_DIR/stockfish"; fi
else
    mv "$tmpfile" "$OUT_DIR/stockfish"
    chmod +x "$OUT_DIR/stockfish"
fi
echo "Stockfish downloaded to $OUT_DIR/stockfish"
