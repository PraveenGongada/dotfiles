#!/bin/sh
set -eu

version=5.40.0
dest="$(cd "$(dirname "$0")/.." && pwd)/herdr-app/mods/material-files/material"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://registry.npmjs.org/material-icon-theme/-/material-icon-theme-$version.tgz" | tar xz -C "$tmp"
rm -rf "$dest"
mkdir -p "$dest"
cp "$tmp"/package/icons/*.svg "$dest"/
cp "$tmp"/package/LICENSE "$dest"/LICENSE.txt
echo "material-icon-theme $version: $(ls "$dest" | grep -c '\.svg$') icons in $dest"
