CAR GAME - POLY HAVEN ASSETS READY-TO-INSTALL
============================================

This package includes the upgraded game script and automatic downloaders for
its real Poly Haven assets. The binary asset files are fetched directly from
Poly Haven when you run the downloader from your Godot project folder.

ASSETS
------
1) Asphalt Track PBR texture (2K): diffuse, OpenGL normal, roughness, AO.
2) Joburg Central Sunset HDRI (2K): sky and image-based ambient/reflected light.

INSTALL ON WINDOWS
------------------
1. Copy car_game_graphics_upgrade.gd into your Godot project and attach it to
   the game scene (or replace the previous game script).
2. Open PowerShell with the current directory set to your Godot project root.
3. Run:
     powershell -ExecutionPolicy Bypass -File .\tools\download_polyhaven_assets.ps1
4. Open the project in Godot and allow it to import the new assets.

INSTALL ON macOS / LINUX
-----------------------
1. Copy the script and tools folder into your Godot project.
2. Open a terminal in the project root and run:
     bash tools/download_polyhaven_assets.sh
3. Open the project in Godot and allow it to import the new assets.

The downloaders create these paths automatically:
  assets/polyhaven/asphalt_track/asphalt_track_diff_2k.jpg
  assets/polyhaven/asphalt_track/asphalt_track_nor_gl_2k.jpg
  assets/polyhaven/asphalt_track/asphalt_track_rough_2k.jpg
  assets/polyhaven/asphalt_track/asphalt_track_ao_2k.jpg
  assets/polyhaven/sunset_jhbcentral_2k.hdr

LICENCE
-------
Poly Haven assets are CC0. Asset pages:
  https://polyhaven.com/a/asphalt_track
  https://polyhaven.com/a/sunset_jhbcentral

The download scripts retrieve the assets directly from the official Poly Haven
CDN; no third-party mirror is used. The game has fallback procedural graphics
if the downloaded files are absent.

NOTE
----
This environment could not retrieve the binary files itself because outbound
file downloads are blocked. The package therefore includes the exact downloader
for the assets and installs them into the correct paths automatically.
