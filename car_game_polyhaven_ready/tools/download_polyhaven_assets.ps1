$ErrorActionPreference = 'Stop'
# Run from the root of your Godot project.
$roadDir = Join-Path (Get-Location) 'assets/polyhaven/asphalt_track'
$assetDir = Join-Path (Get-Location) 'assets/polyhaven'
New-Item -ItemType Directory -Force -Path $roadDir | Out-Null
New-Item -ItemType Directory -Force -Path $assetDir | Out-Null
function Download-Asset([string]$Url, [string]$Path) {
    Write-Host "Downloading $(Split-Path $Path -Leaf)..."
    Invoke-WebRequest -Uri $Url -OutFile $Path
    if (!(Test-Path $Path) -or (Get-Item $Path).Length -eq 0) { throw "Download failed: $Path" }
}
$base = 'https://dl.polyhaven.org/file/ph-assets/Textures/jpg/2k/asphalt_track'
Download-Asset "$base/asphalt_track_diff_2k.jpg" (Join-Path $roadDir 'asphalt_track_diff_2k.jpg')
Download-Asset "$base/asphalt_track_nor_gl_2k.jpg" (Join-Path $roadDir 'asphalt_track_nor_gl_2k.jpg')
Download-Asset "$base/asphalt_track_rough_2k.jpg" (Join-Path $roadDir 'asphalt_track_rough_2k.jpg')
Download-Asset "$base/asphalt_track_ao_2k.jpg" (Join-Path $roadDir 'asphalt_track_ao_2k.jpg')
Download-Asset 'https://dl.polyhaven.org/file/ph-assets/HDRIs/hdr/2k/sunset_jhbcentral_2k.hdr' (Join-Path $assetDir 'sunset_jhbcentral_2k.hdr')
Write-Host 'Poly Haven assets downloaded. Open the project in Godot and let the assets import.'
