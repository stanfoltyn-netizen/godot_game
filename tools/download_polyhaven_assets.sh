#!/usr/bin/env bash
set -euo pipefail

# Run this script from the root of your Godot project.
# Downloads CC0 assets directly from Poly Haven into the paths expected by the game.
command -v curl >/dev/null 2>&1 || { echo 'ERROR: curl is required.' >&2; exit 1; }

ROAD_DIR='assets/polyhaven/asphalt_track'
mkdir -p "$ROAD_DIR" 'assets/polyhaven'

download() {
  local url="$1" dest="$2"
  echo "Downloading $(basename "$dest")..."
  curl --fail --location --retry 3 --retry-delay 2 --output "$dest" "$url"
  test -s "$dest" || { echo "ERROR: empty download: $dest" >&2; exit 1; }
}

BASE='https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/asphalt_track'
download "$BASE/asphalt_track_diff_2k.jpg" "$ROAD_DIR/asphalt_track_diff_2k.jpg"
download "$BASE/asphalt_track_nor_gl_2k.jpg" "$ROAD_DIR/asphalt_track_nor_gl_2k.jpg"
download "$BASE/asphalt_track_rough_2k.jpg" "$ROAD_DIR/asphalt_track_rough_2k.jpg"
download "$BASE/asphalt_track_ao_2k.jpg" "$ROAD_DIR/asphalt_track_ao_2k.jpg"
download 'https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/sunset_jhbcentral_2k.hdr' 'assets/polyhaven/sunset_jhbcentral_2k.hdr'

echo
echo 'Poly Haven assets downloaded.'
echo 'Open the project in Godot and let the assets import.'
