# Graphics upgrade

The active game script `new_script.gd` now uses higher-quality environment settings and automatically uses real Poly Haven PBR asphalt maps and a 2K sunset HDRI when the assets are present. It retains procedural fallbacks, so the game can still start before the downloads complete.

## Download the free CC0 assets

Run the command from the Godot project root:

**Windows PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File .\\tools\\download_polyhaven_assets.ps1
```

**macOS / Linux**
```bash
bash tools/download_polyhaven_assets.sh
```

Then reopen the project in Godot and let it import the new files. The downloaders fetch directly from the official Poly Haven CDN and create the expected folders under `assets/polyhaven/`.

Assets: [Asphalt Track](https://polyhaven.com/a/asphalt_track) and [Sunset JHB Central](https://polyhaven.com/a/sunset_jhbcentral). Both are CC0.

The existing `new_script.gd.uid` is intentionally unchanged, so `control.tscn` remains attached to the active script. The original `master` branch is untouched; this work is on `graphics-upgrade-integration`.

**Validation:** the files have been committed, but the project has not yet been run in the Godot editor, so runtime/rendering validation is still required.
