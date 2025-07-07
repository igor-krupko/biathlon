#!/bin/bash
# Download country flags for biathlon_app/assets/flags/
# Usage: bash download_flags.sh

set -e

FLAGS_DIR="biathlon_app/assets/flags"
mkdir -p "$FLAGS_DIR"

# Country codes and names
FLAGS=(
  "ca:Canada"
  "bg:Bulgaria"
  "ro:Romania"
  "be:Belgium"
  "gl:Greenland"
  "rs:Serbia"
  "ar:Argentina"
  "cl:Chile"
  "cn:China"
  "gb:Great_Britain"
  "hu:Hungary"
  "gr:Greece"
  "es:Spain"
)

for entry in "${FLAGS[@]}"; do
  IFS=":" read -r code name <<< "$entry"
  url="https://flagcdn.com/w40/$code.png"
  out="$FLAGS_DIR/$(echo $code | tr '[:lower:]' '[:upper:]').png"
  echo "Downloading $name ($code) -> $out"
  curl -sSL "$url" -o "$out"
done

echo "All flags downloaded to $FLAGS_DIR" 